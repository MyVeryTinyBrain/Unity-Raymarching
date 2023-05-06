#pragma once

#define PI 3.14159265359
#define TAU 6.28318530718
#define Deg2Rad 0.0174532925199
#define Rad2Deg 57.2957795131

// Matrices for * Row vector *
//              --------------

float4x4 IdentityMatrix()
{
    return float4x4(
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1
        );
}

float4x4 TranslateMatrix(float3 translation)
{
    float4x4 m = float4x4(
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        translation.x, translation.y, translation.z, 1
        );
    return m;
}

float2x2 RotateMatrix2x2(float radian)
{
    float s = sin(radian);
    float c = cos(radian);
    return float2x2(
        c, -s,
        s, c
        );
}

float4x4 RotateXMatrix(float radian)
{
    float c = cos(radian);
    float s = sin(radian);
    return float4x4(
        1, 0, 0, 0,
        0, c, s, 0,
        0, -s, c, 0,
        0, 0, 0, 1
        );
}

float4x4 RotateYMatrix(float radian)
{
    float c = cos(radian);
    float s = sin(radian);
    return float4x4(
        c, 0, -s, 0,
        0, 1, 0, 0,
        s, 0, c, 0,
        0, 0, 0, 1
        );
}

float4x4 RotateZMatrix(float radian)
{
    float c = cos(radian);
    float s = sin(radian);
    return float4x4(
        c, s, 0, 0,
        -s, c, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1
        );
}

float4x4 RotateMatrix(float3 radians)
{
    float4x4 zy = mul(RotateZMatrix(radians.z), RotateYMatrix(radians.y));
    float4x4 zyx = mul(zy, RotateXMatrix(radians.x));
    return zyx;
}

float4x4 ScaleMatrix(float3 scale)
{
    return float4x4(
        scale.x, 0, 0, 0,
        0, scale.y, 0, 0,
        0, 0, scale.z, 0,
        0, 0, 0, 1
        );
}

float4x4 TransformMatrix(float3 translate, float3 radians, float3 scale)
{
    float4x4 sr = mul(ScaleMatrix(scale), RotateMatrix(radians));
    float4x4 srt = mul(sr, TranslateMatrix(translate));
    return srt;
}

float4x4 InverseMatrix(float4x4 m)
{
    float n11 = m[0][0], n12 = m[1][0], n13 = m[2][0], n14 = m[3][0];
    float n21 = m[0][1], n22 = m[1][1], n23 = m[2][1], n24 = m[3][1];
    float n31 = m[0][2], n32 = m[1][2], n33 = m[2][2], n34 = m[3][2];
    float n41 = m[0][3], n42 = m[1][3], n43 = m[2][3], n44 = m[3][3];

    float t11 = n23 * n34 * n42 - n24 * n33 * n42 + n24 * n32 * n43 - n22 * n34 * n43 - n23 * n32 * n44 + n22 * n33 * n44;
    float t12 = n14 * n33 * n42 - n13 * n34 * n42 - n14 * n32 * n43 + n12 * n34 * n43 + n13 * n32 * n44 - n12 * n33 * n44;
    float t13 = n13 * n24 * n42 - n14 * n23 * n42 + n14 * n22 * n43 - n12 * n24 * n43 - n13 * n22 * n44 + n12 * n23 * n44;
    float t14 = n14 * n23 * n32 - n13 * n24 * n32 - n14 * n22 * n33 + n12 * n24 * n33 + n13 * n22 * n34 - n12 * n23 * n34;

    float det = n11 * t11 + n21 * t12 + n31 * t13 + n41 * t14;
    float idet = 1.0f / det;

    float4x4 ret;

    ret[0][0] = t11 * idet;
    ret[0][1] = (n24 * n33 * n41 - n23 * n34 * n41 - n24 * n31 * n43 + n21 * n34 * n43 + n23 * n31 * n44 - n21 * n33 * n44) * idet;
    ret[0][2] = (n22 * n34 * n41 - n24 * n32 * n41 + n24 * n31 * n42 - n21 * n34 * n42 - n22 * n31 * n44 + n21 * n32 * n44) * idet;
    ret[0][3] = (n23 * n32 * n41 - n22 * n33 * n41 - n23 * n31 * n42 + n21 * n33 * n42 + n22 * n31 * n43 - n21 * n32 * n43) * idet;

    ret[1][0] = t12 * idet;
    ret[1][1] = (n13 * n34 * n41 - n14 * n33 * n41 + n14 * n31 * n43 - n11 * n34 * n43 - n13 * n31 * n44 + n11 * n33 * n44) * idet;
    ret[1][2] = (n14 * n32 * n41 - n12 * n34 * n41 - n14 * n31 * n42 + n11 * n34 * n42 + n12 * n31 * n44 - n11 * n32 * n44) * idet;
    ret[1][3] = (n12 * n33 * n41 - n13 * n32 * n41 + n13 * n31 * n42 - n11 * n33 * n42 - n12 * n31 * n43 + n11 * n32 * n43) * idet;

    ret[2][0] = t13 * idet;
    ret[2][1] = (n14 * n23 * n41 - n13 * n24 * n41 - n14 * n21 * n43 + n11 * n24 * n43 + n13 * n21 * n44 - n11 * n23 * n44) * idet;
    ret[2][2] = (n12 * n24 * n41 - n14 * n22 * n41 + n14 * n21 * n42 - n11 * n24 * n42 - n12 * n21 * n44 + n11 * n22 * n44) * idet;
    ret[2][3] = (n13 * n22 * n41 - n12 * n23 * n41 - n13 * n21 * n42 + n11 * n23 * n42 + n12 * n21 * n43 - n11 * n22 * n43) * idet;

    ret[3][0] = t14 * idet;
    ret[3][1] = (n13 * n24 * n31 - n14 * n23 * n31 + n14 * n21 * n33 - n11 * n24 * n33 - n13 * n21 * n34 + n11 * n23 * n34) * idet;
    ret[3][2] = (n14 * n22 * n31 - n12 * n24 * n31 - n14 * n21 * n32 + n11 * n24 * n32 + n12 * n21 * n34 - n11 * n22 * n34) * idet;
    ret[3][3] = (n12 * n23 * n31 - n13 * n22 * n31 + n13 * n21 * n32 - n11 * n23 * n32 - n12 * n21 * n33 + n11 * n22 * n33) * idet;

    return ret;
}

float3 RotatePoint(float3 p, float3 radians)
{
    float4x4 m = RotateMatrix(radians);
    return mul(float4(p.x, p.y, p.z, 1), m);
}

float3 RotateVector(float3 v, float3 radians)
{
    float4x4 m = RotateMatrix(radians);
    return mul(float4(v.x, v.y, v.z, 0), m);
}

float3 TransformPoint(float3 p, float3 translate, float3 radians, float3 scale)
{
    float4x4 m = TransformMatrix(translate, radians, scale);
    return mul(float4(p.x, p.y, p.z, 1), m);
}

float3 TransformPoint(float3 p, float4x4 m)
{
    return mul(float4(p.x, p.y, p.z, 1), m);
}

float3 TransformVector(float3 p, float3 translate, float3 radians, float3 scale)
{
    float4x4 m = TransformMatrix(translate, radians, scale);
    return mul(float4(p.x, p.y, p.z, 0), m);
}

float3 TransformVector(float3 p, float4x4 m)
{
    return mul(float4(p.x, p.y, p.z, 0), m);
}
