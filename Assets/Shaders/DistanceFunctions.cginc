#pragma once

// https://iquilezles.org/articles/distfunctions/
// More functions are here

// Input Position: Position.xyz - SDF.xyz
// You can transform SDF Shape to Inverse Transform Position.xyz

// Sphere
// s: radius
float sdSphere(float3 p, float s)
{
	return length(p) - s;
}

// Box
// b: size of box in x/y/z
float sdBox(float3 p, float3 b)
{
	float3 d = abs(p) - b;
	return min(max(d.x, max(d.y, d.z)), 0.0) +
		length(max(d, 0.0));
}

// Round Box
// b: size of box in x/y/z
// r: additional radius
float sdRoundBox(float3 p, float3 b, float r)
{
	float3 q = abs(p) - b;
	return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0) - r;
}

// Plane
// h: height of plane
float sdPlane(float3 p, float3 n, float h)
{
	// n must be normalized
	return dot(p, n) + h;
}

// BOOLEAN OPERATORS //

float opU(float d1, float d2)
{
	return min(d1, d2);
}

float4 opColorU(float4 d1, float4 d2)
{
	return d1.w < d2.w ? d1 : d2;
}

float opS(float d1, float d2)
{
	return max(-d1, d2);
}

float opI(float d1, float d2)
{
	return max(d1, d2);
}

float opI(float d1, float d2, fixed4 col1, fixed4 col2, inout fixed4 col)
{
	return max(d1, d2);
}

float opSmoothUnion(float d1, float d2, float k)
{
	float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
	return lerp(d2, d1, h) - k * h * (1.0 - h);
}

float opSmoothSubtraction(float d1, float d2, float k)
{
	float h = clamp(0.5 - 0.5 * (d2 + d1) / k, 0.0, 1.0);
	return lerp(d2, -d1, h) + k * h * (1.0 - h);
}

float opSmoothIntersection(float d1, float d2, float k)
{
	float h = clamp(0.5 - 0.5 * (d2 - d1) / k, 0.0, 1.0);
	return lerp(d2, d1, h) + k * h * (1.0 - h);
}

float4 opSmoothColorUnion(float4 d1, float4 d2, float k)
{
	float h = clamp(0.5 + 0.5 * (d2.w - d1.w) / k, 0.0, 1.0);
	float3 color = lerp(d2.rgb, d1.rgb, h);
	float dist = lerp(d2.w, d1.w, h) - k * h * (1.0 - h);
	return float4(color, dist);
}

// Mod Position Axis
float pMod1 (inout float p, float size)
{
	float halfsize = size * 0.5;
	float c = floor((p+halfsize)/size);
	p = fmod(p+halfsize,size)-halfsize;
	p = fmod(-p+halfsize,size)-halfsize;
	return c;
}