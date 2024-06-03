#ifndef MYHLSLINCLUDE_INCLUDED
#define MYHLSLINCLUDE_INCLUDED

float hash (float2 n)
{
    return frac(sin(dot(n, float2(123.456789, 987.654321))) * 54321.9876 );
}

float noise(float2 p)
{
    float2 i = floor(p);
    float2 u = smoothstep(0.0, 1.0, frac(p));
    float a = hash(i + float2(0,0));
    float b = hash(i + float2(1,0));
    float c = hash(i + float2(0,1));
    float d = hash(i + float2(1,1));
    float r = lerp(lerp(a, b, u.x),lerp(c, d, u.x), u.y);
    return r * r;
}

void Collision_float(bool collid, out float Out)
{
    float valur = 1.0f;

    Out = valur;
}

#endif