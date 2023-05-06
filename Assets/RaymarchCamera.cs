using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Camera))]
[ExecuteInEditMode]
public class RaymarchCamera : MonoBehaviour
{
    [SerializeField]
    Shader m_RaymarchShader;

    [Header("Render")]
    public int MaxIteration = 200;
    public float HitThreshold = 0.001f;
    public float MaxRenderDistance = 100;

    [Header("Shadow")]
    public Vector2 MinMaxShadowRenderDistance = new Vector2(0.8f, 100);
    public float ShadowIntensity = 1;
    public float ShadowPenumbra = 20;

    [Header("Ambient Occlusion")]
    public int AOIteration = 3;
    public float AODistance = 1.0f;
    public float AOIntensity = 0.8f;

    [Header("Reflection")]
    public int ReflectionCount;
    [Range(0, 1)]
    public float ReflectionIntensity = 1;
    [Range(0, 1)]
    public float EnvReflectionIntensity = 0.5f;
    [Range(0, 1)]
    public float EnvReflectionBlurIntensity = 0.05f;
    public Cubemap ReflectionCube;

    [Header("SDF")]
    // (x, y, z, radius)
    public Color MeshColor = Color.white;
    public Vector4 Sphere = new Vector4(0, 0, 0, 0.5f);
    [Range(1, 64)]
    public int SphereCount = 1;
    public float SphereDistance = 0;
    public float SphereSmooth = 1;
    public float SphereRotateScale = 1;
    public Gradient SphereGradient;
    public List<Color> SphereColors;
    public float PlaneSmooth = 1;
    public Color PlaneColor = Color.white;

    Material m_RaymarchMaterial;
    Camera m_Camera;

    public Material raymarchMaterial
    {
        get
        {
            if (!m_RaymarchShader)
                return null;
            if (!m_RaymarchMaterial)
                m_RaymarchMaterial = new Material(m_RaymarchShader);
            m_RaymarchMaterial.hideFlags = HideFlags.HideAndDontSave;
            return m_RaymarchMaterial;
        }
    }

    public new Camera camera
    {
        get
        {
            if (!m_Camera)
                m_Camera = GetComponent<Camera>();
            return m_Camera;
        }
    }

    [ImageEffectOpaque]
    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (!raymarchMaterial)
        {
            Graphics.Blit(source, destination);
            return;
        }

        raymarchMaterial.SetMatrix("_CamFrustum", CalcCamSpaceFrustum(camera));
        raymarchMaterial.SetMatrix("_CamToWorld", camera.cameraToWorldMatrix);

        raymarchMaterial.SetInt("_MaxIteration", MaxIteration);
        raymarchMaterial.SetFloat("_HitThreshold", HitThreshold);
        raymarchMaterial.SetFloat("_MaxRenderDistance", MaxRenderDistance);

        raymarchMaterial.SetVector("_MinMaxShadowRenderDistance", MinMaxShadowRenderDistance);
        raymarchMaterial.SetFloat("_ShadowIntensity", ShadowIntensity);
        raymarchMaterial.SetFloat("_ShadowPenumbra", ShadowPenumbra);

        raymarchMaterial.SetInt("_AOIteration", AOIteration);
        raymarchMaterial.SetFloat("_AODistance", AODistance);
        raymarchMaterial.SetFloat("_AOIntensity", AOIntensity);

        raymarchMaterial.SetInt("_ReflectionCount", ReflectionCount);
        raymarchMaterial.SetFloat("_ReflectionIntensity", ReflectionIntensity);
        raymarchMaterial.SetFloat("_EnvReflectionIntensity", EnvReflectionIntensity);
        raymarchMaterial.SetFloat("_EnvReflectionBlurIntensity", EnvReflectionBlurIntensity);
        raymarchMaterial.SetTexture("_ReflectionCube", ReflectionCube);

        raymarchMaterial.SetColor("_MeshColor", MeshColor);

        raymarchMaterial.SetTexture("_MainTex", source);
        raymarchMaterial.SetVector("_Sphere", Sphere);
        raymarchMaterial.SetVector("_Sphere", Sphere);
        raymarchMaterial.SetInt("_SphereCount", SphereCount);
        raymarchMaterial.SetFloat("_SphereDistance", SphereDistance);
        raymarchMaterial.SetFloat("_SphereSmooth", SphereSmooth);
        raymarchMaterial.SetFloat("_SphereRotateScale", SphereRotateScale);

        if (SphereColors.Count < SphereCount)
        {
            SphereColors.AddRange(new Color[SphereCount - SphereColors.Count]);
        }
        for(int i = 0; i < SphereCount; ++i)
        {
            SphereColors[i] = SphereGradient.Evaluate((float)i / (float)SphereCount);
        }
        raymarchMaterial.SetColorArray("_SphereColors", SphereColors);

        raymarchMaterial.SetFloat("_PlaneSmooth", PlaneSmooth);
        raymarchMaterial.SetColor("_PlaneColor", PlaneColor);

        RenderTexture.active = destination;
        GL.PushMatrix();
        GL.LoadOrtho();
        raymarchMaterial.SetPass(0);
        GL.Begin(GL.QUADS);
        {
            // should set z of vertex to zero
            // z of vertex is index of row of frustum matrix
            // row of frustum matrix is corner of frustum

            // bottom left
            GL.MultiTexCoord2(0, 0, 0);
            GL.Vertex3(0, 0, 3); 
            // bottom right
            GL.MultiTexCoord2(0, 1, 0);
            GL.Vertex3(1, 0, 2);
            // top right
            GL.MultiTexCoord2(0, 1, 1);
            GL.Vertex3(1, 1, 1);
            // top left
            GL.MultiTexCoord2(0, 0, 1);
            GL.Vertex3(0, 1, 0);
        }
        GL.End();
        GL.PopMatrix();
    }

    static Matrix4x4 CalcCamSpaceFrustum(Camera cam)
    {
        float fov = Mathf.Tan(cam.fieldOfView * 0.5f * Mathf.Deg2Rad);
        Vector3 cameraSpaceForward = Vector3.back;
        Vector3 up = Vector3.up * fov;
        Vector3 right = Vector3.right * fov * cam.aspect;
        // local positions of corners of frustum
        Vector3 tl = Vector3.forward - right + up;
        Vector3 tr = Vector3.forward + right + up;
        Vector3 br = Vector3.forward + right - up;
        Vector3 bl = Vector3.forward - right - up;
        // world positions of corners of frustum
        tl = cam.transform.localToWorldMatrix.MultiplyPoint(tl);
        tr = cam.transform.localToWorldMatrix.MultiplyPoint(tr);
        br = cam.transform.localToWorldMatrix.MultiplyPoint(br);
        bl = cam.transform.localToWorldMatrix.MultiplyPoint(bl);
        // camera positions of corners of frustum
        tl = cam.worldToCameraMatrix.MultiplyPoint(tl);
        tr = cam.worldToCameraMatrix.MultiplyPoint(tr);
        br = cam.worldToCameraMatrix.MultiplyPoint(br);
        bl = cam.worldToCameraMatrix.MultiplyPoint(bl);
        Matrix4x4 frustum = Matrix4x4.identity;
        frustum.SetRow(0, tl);
        frustum.SetRow(1, tr);
        frustum.SetRow(2, br);
        frustum.SetRow(3, bl);
        return frustum;
    }
}
