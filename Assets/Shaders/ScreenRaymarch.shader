Shader "Raymarch/ScreenRaymarch"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0

            #include "UnityCG.cginc"
            #include "GeometryUtility.cginc"
            #include "DistanceFunctions.cginc"
            #include "RaymarchFunctions.cginc"

            #define NoneHitColor fixed4(0, 0, 0, 0)
            #define NormalOffsetDistance 0.001
            #define NormalOffsetA float3(NormalOffsetDistance, 0, 0)
            #define NormalOffsetB float3(0, NormalOffsetDistance, 0)
            #define NormalOffsetC float3(0, 0, NormalOffsetDistance)

            sampler2D _MainTex;
            uniform sampler2D _CameraDepthTexture;
            uniform float4x4 _CamFrustum, _CamToWorld;
            uniform int _MaxIteration;
            uniform float _HitThreshold;
            uniform float _MaxRenderDistance;
            uniform float2 _MinMaxShadowRenderDistance;
            uniform float _ShadowIntensity, _ShadowPenumbra;
            uniform int _AOIteration;
            uniform float _AODistance, _AOIntensity;
            uniform int _ReflectionCount;
            uniform float _ReflectionIntensity;
            uniform float _EnvReflectionIntensity;
            uniform float _EnvReflectionBlurIntensity;
            uniform samplerCUBE _ReflectionCube;

            uniform float4 _MeshColor;
            // (x, y, z, radius)
            uniform float4 _Sphere;
            uniform int _SphereCount;
            uniform float _SphereDistance;
            uniform float _SphereSmooth;
            uniform float _SphereRotateScale;
            uniform float4 _SphereColors[512];
            uniform float _PlaneSmooth;
            uniform float4 _PlaneColor;

            fixed4 _LightColor0;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 ray : TEXCOORD1;
            };

            v2f vert(appdata v)
            {
                // cache index from z of vertex
                half index = v.vertex.z;
                // reset z of vertex
                // z must be zero in screen space
                v.vertex.z = 0;

                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;

                // get frustum
                // row of the cam frustum matrix is corner of frustum
                o.ray = _CamFrustum[(int)index].xyz;
                o.ray /= abs(o.ray.z);
                o.ray = mul(_CamToWorld, o.ray);
                return o;
            }

            float4 distanceField(float3 position)
            {
                float4 plane = float4(_PlaneColor.rgb, sdPlane(position, float3(0, 1, 0), 0));

                float4 spheres = float4(1, 1, 1, _MaxRenderDistance + 1);
                float3 spheresTransform = TransformSDFPoint(position, 0, float3(0, _Time.x * _SphereRotateScale, 0), 1);
                for (int i = 0; i < _SphereCount; ++i)
                {
                    float ratio = float(i) / float(_SphereCount);
                    float radian = TAU * ratio;
                    float3 translate = float3(cos(radian), 0, sin(radian)) * _SphereDistance;
                    float4 sphere = float4(_SphereColors[i].rgb, sdSphere(spheresTransform - _Sphere.xyz - translate, _Sphere.w * 0.5f));
                    spheres = opSmoothColorUnion(sphere, spheres, _SphereSmooth);
                }

                return opSmoothColorUnion(plane, spheres, _PlaneSmooth);
            }

            float3 getNormal(float3 position)
            {
                float3 normal = float3(
                    distanceField(position + NormalOffsetA).w - distanceField(position - NormalOffsetA).w,
                    distanceField(position + NormalOffsetB).w - distanceField(position - NormalOffsetB).w,
                    distanceField(position + NormalOffsetC).w - distanceField(position - NormalOffsetC).w);
                return normalize(normal);
            }

            float hardShadow(float3 rayOrigin, float3 rayDirection, float minDistance, float maxDistance)
            {
                for (float marchedDistance = minDistance; marchedDistance < maxDistance;)
                {
                    float stepMarchDistance = distanceField(rayOrigin + rayDirection * marchedDistance).w;
                    if (stepMarchDistance < _HitThreshold)
                    {
                        return 0.0;
                    }
                    marchedDistance += stepMarchDistance;
                }
                return 1.0;
            }

            float softShadow(float3 rayOrigin, float3 rayDirection, float minDistance, float maxDistance, float penumbra)
            {
                float bright = 1;
                for (float marchedDistance = minDistance; marchedDistance < maxDistance;)
                {
                    float stepMarchDistance = distanceField(rayOrigin + rayDirection * marchedDistance).w;
                    if (stepMarchDistance < _HitThreshold)
                    {
                        return 0.0;
                    }
                    bright = min(bright, penumbra * stepMarchDistance / marchedDistance);
                    marchedDistance += stepMarchDistance;
                }
                return bright;
            }

            float ambientOcclusion(float3 position, float3 normal, int iteration, float distance, float intensity)
            {
                float step = distance / iteration;
                float ao = 0;
                for (int i = 1; i <= iteration; i++)
                {
                    float dist = step * i;
                    ao += max(0, (dist - distanceField(position + normal * dist).w) / dist);
                }
                return (1 - ao / iteration * intensity);
            }

            float3 directionalShading(float3 position, float3 normal)
            {
                float intensity = dot(normal, _WorldSpaceLightPos0) * 0.5 + 0.5;
                float shadow = softShadow(position, _WorldSpaceLightPos0, _MinMaxShadowRenderDistance.x, _MinMaxShadowRenderDistance.y, _ShadowPenumbra) * 0.5 + 0.5;
                shadow = max(0.0, pow(shadow, _ShadowIntensity));
                float ao = ambientOcclusion(position, normal, _AOIteration, _AODistance, _AOIntensity);
                return intensity * shadow * ao * _LightColor0.rgb;
            }

            // return: hit result
            // inout: set hit position if hit
            bool raymarching(float3 rayOrigin, float3 rayDirection, float pixelDepth, int maxIteration, inout float3 hitPosition, inout fixed3 hitColor)
            {
                float marchedDistance = 0;

                for (int i = 0; i < maxIteration; ++i)
                {
                    // if nothing hit
                    if (marchedDistance > _MaxRenderDistance || marchedDistance > pixelDepth)
                    {
                        return false;
                    }

                    // important part of raymarch
                    float3 position = rayOrigin + rayDirection * marchedDistance;
                    // (Hit color RGB, March Step Distance)
                    float4 d = distanceField(position);
                    marchedDistance += d.w;

                    // if hit something
                    if (d.w < _HitThreshold)
                    {
                        hitPosition = position;
                        hitColor = d.rgb;
                        return true;
                    }
                }

                return false;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float depth = LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv).r);
                float3 rayOrigin = _WorldSpaceCameraPos;
                float3 rayDirection = normalize(i.ray.xyz);
                fixed4 raymarchedColor = 1;
                float3 raymarchHitPoint;
                fixed3 raymarchHitColor;
                bool raymarchHit = raymarching(rayOrigin, rayDirection, depth, _MaxIteration, raymarchHitPoint, raymarchHitColor);
                if (raymarchHit) 
                {
                    float3 normal = getNormal(raymarchHitPoint);
                    raymarchedColor.rgb = directionalShading(raymarchHitPoint, normal) * raymarchHitColor;

                    float3 envRefRayDirection = normalize(reflect(rayDirection, normal));
                    fixed3 envReflectionColor = (
                        texCUBE(_ReflectionCube, envRefRayDirection) +
                        texCUBE(_ReflectionCube, normalize(envRefRayDirection + float3(+_EnvReflectionBlurIntensity, 0, 0))) +
                        texCUBE(_ReflectionCube, normalize(envRefRayDirection + float3(-_EnvReflectionBlurIntensity, 0, 0))) +
                        texCUBE(_ReflectionCube, normalize(envRefRayDirection + float3(0, +_EnvReflectionBlurIntensity, 0))) +
                        texCUBE(_ReflectionCube, normalize(envRefRayDirection + float3(0, -_EnvReflectionBlurIntensity, 0))) +
                        texCUBE(_ReflectionCube, normalize(envRefRayDirection + float3(0, 0, +_EnvReflectionBlurIntensity))) +
                        texCUBE(_ReflectionCube, normalize(envRefRayDirection + float3(0, 0, -_EnvReflectionBlurIntensity)))
                        ).rgb / 7.0;
                    raymarchedColor.rgb += envReflectionColor * _EnvReflectionIntensity * _ReflectionIntensity;

                    float3 refRayDirection = normalize(reflect(rayDirection, normal));
                    float3 refRayOrigin = raymarchHitPoint + (refRayDirection * 0.01);
                    for (int i = 0; i < _ReflectionCount; ++i)
                    {
                        float3 refRaymarchHitPoint;
                        fixed3 refRaymarchHitColor;
                        bool refRaymarchHit = raymarching(refRayOrigin, refRayDirection, _MaxRenderDistance * 0.5, _MaxIteration / 2, refRaymarchHitPoint, refRaymarchHitColor);
                        if (refRaymarchHit)
                        {
                            float3 refNormal = getNormal(refRaymarchHitPoint);
                            fixed3 reflectionColor = directionalShading(refRaymarchHitPoint, refNormal) * refRaymarchHitColor * _ReflectionIntensity;
                            raymarchedColor.rgb += reflectionColor;

                            refRayDirection = normalize(reflect(refRayDirection, refNormal));
                            refRayOrigin = refRaymarchHitPoint + (refRayDirection * 0.01);
                        }
                        else
                        {
                            break;
                        }
                    }
                }
                fixed4 srcColor = tex2D(_MainTex, i.uv);
                return lerp(srcColor, raymarchedColor, raymarchHit);
            }
            ENDCG
        }
    }
}
