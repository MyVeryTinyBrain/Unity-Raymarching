#pragma once

#include "GeometryUtility.cginc"

float3 TransformSDFPoint(float3 p, float3 translate, float3 radians, float3 scale)
{
    float4x4 m = TransformMatrix(translate, radians, scale);
    m = InverseMatrix(m);
    return mul(float4(p.x, p.y, p.z, 1), m);
}