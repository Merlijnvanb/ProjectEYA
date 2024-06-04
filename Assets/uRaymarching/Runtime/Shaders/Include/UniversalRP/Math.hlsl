#ifndef URAYMARCHING_MATH_HLSL
#define URAYMARCHING_MATH_HLSL

float Rand(float2 seed)
{
    return frac(sin(dot(seed, float2(12.9898, 78.233))) * 43758.5453);
}

inline float hash(float p) {
    p = frac(p * 0.011); 
    p *= p + 7.5; 
    p *= p + p; 
    return frac(p); 
}


inline float hash(float2 p) {
    float3 p3 = frac(float3(p.x, p.y, p.x) * 0.13); 
    p3 += dot(p3, p3.yzx + 3.333); 
    return frac(p3.x * p3.y * p3.z);
}


inline float noise(float3 x) {
    const float3 step = float3(110, 241, 171);

    float3 i = floor(x);
    float3 f = frac(x);
    
    // For performance, compute the base input to a 1D hash from the integer part of the argument and the 
    // incremental change to the 1D based on the 3D -> 1D wrapping
    float n = dot(i, step);

    float3 u = f * f * (3.0 - 2.0 * f);

    return lerp(
        lerp(
            lerp(hash(n + dot(step, float3(0, 0, 0))), hash(n + dot(step, float3(1, 0, 0))), u.x),
            lerp(hash(n + dot(step, float3(0, 1, 0))), hash(n + dot(step, float3(1, 1, 0))), u.x), u.y),
        lerp(
            lerp(hash(n + dot(step, float3(0, 0, 1))), hash(n + dot(step, float3(1, 0, 1))), u.x),
            lerp(hash(n + dot(step, float3(0, 1, 1))), hash(n + dot(step, float3(1, 1, 1))), u.x), u.y), u.z);
}

const float3x3 Mfbm4 = float3x3(
     0.00,  0.80,  0.60,
    -0.80,  0.36, -0.48,
    -0.60, -0.48,  0.64
);

float fbm4(float3 q) {
    float f  = 0.5000 * noise(q); 
    q = mul(Mfbm4, q) * 2.02;
    f += 0.2500 * noise(q); 
    q = mul(Mfbm4, q) * 2.03;
    f += 0.1250 * noise(q); 
    q = mul(Mfbm4, q) * 2.01;
    f += 0.0625 * noise(q);
    return f;
}

inline float Mod(float a, float b)
{
    return frac(abs(a / b)) * abs(b);
}

inline float2 Mod(float2 a, float2 b)
{
    return frac(abs(a / b)) * abs(b);
}

inline float3 Mod(float3 a, float3 b)
{
    return frac(abs(a / b)) * abs(b);
}

inline float smin(float a, float b, float k)
{
    k *= 1.0;
    float r = exp2(-a / k) + exp2(-b / k);
    return -k * log2(r);
}

inline float smax(float a, float b, float k)
{
    return smin(a, b, -k);
}

inline float Repeat(float pos, float span)
{
    return Mod(pos, span) - span * 0.5;
}

inline float2 Repeat(float2 pos, float2 span)
{
    return Mod(pos, span) - span * 0.5;
}

inline float3 Repeat(float3 pos, float3 span)
{
    return Mod(pos, span) - span * 0.5;
}

inline float3 Rotate(float3 p, float angle, float3 axis)
{
    float3 a = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float r = 1.0 - c;
    float3x3 m = float3x3(
        a.x * a.x * r + c,
        a.y * a.x * r + a.z * s,
        a.z * a.x * r - a.y * s,
        a.x * a.y * r - a.z * s,
        a.y * a.y * r + c,
        a.z * a.y * r + a.x * s,
        a.x * a.z * r + a.y * s,
        a.y * a.z * r - a.x * s,
        a.z * a.z * r + c
    );
    return mul(m, p);
}

inline float3 TwistY(float3 p, float power)
{
    float s = sin(power * p.y);
    float c = cos(power * p.y);
    float3x3 m = float3x3(
          c, 0.0,  -s,
        0.0, 1.0, 0.0,
          s, 0.0,   c
    );
    return mul(m, p);
}

inline float3 TwistX(float3 p, float power)
{
    float s = sin(power * p.y);
    float c = cos(power * p.y);
    float3x3 m = float3x3(
        1.0, 0.0, 0.0,
        0.0,   c,   s,
        0.0,  -s,   c
    );
    return mul(m, p);
}

inline float3 TwistZ(float3 p, float power)
{
    float s = sin(power * p.y);
    float c = cos(power * p.y);
    float3x3 m = float3x3(
          c,   s, 0.0,
         -s,   c, 0.0,
        0.0, 0.0, 1.0
    );
    return mul(m, p);
}

#endif
