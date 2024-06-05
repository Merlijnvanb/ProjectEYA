Shader "Raymarching/MainMarcher"
{

Properties
{
    [Header(Base)]
    [MainColor] _Color("Color", Color) = (0.5, 0.5, 0.5, 1)

    [Header(Pass)]
    [Enum(UnityEngine.Rendering.CullMode)] _Cull("Culling", Int) = 2
    [Enum(UnityEngine.Rendering.BlendMode)] _BlendSrc("Blend Src", Float) = 5 
    [Enum(UnityEngine.Rendering.BlendMode)] _BlendDst("Blend Dst", Float) = 10
    [Toggle][KeyEnum(Off, On)] _ZWrite("ZWrite", Float) = 1

    [Header(Raymarching)]
    _Loop("Loop", Range(1, 100)) = 30
    _MinDistance("Minimum Distance", Range(0.001, 0.1)) = 0.01
    _DistanceMultiplier("Distance Multiplier", Range(0.001, 2.0)) = 1.0
    _ShadowLoop("Shadow Loop", Range(1, 100)) = 10
    _ShadowMinDistance("Shadow Minimum Distance", Range(0.001, 0.1)) = 0.01
    _ShadowExtraBias("Shadow Extra Bias", Range(-1.0, 1.0)) = 0.01
    [PowerSlider(10.0)] _NormalDelta("NormalDelta", Range(0.00001, 0.1)) = 0.0001

// @block Properties
[Header(Additional Properties)]
_Smooth("Smooth", float) = 1.0
[HDR]_PlaneColor("Plane Color", Color) = (1.0, 1.0, 1.0, 1.0)
[HDR]_SphereColor("Sphere Color", Color) = (1.0, 1.0, 1.0, 1.0)
[HDR]_PlayerColor("Player Color", Color) = (1.0, 1.0, 1.0, 1.0)
// @endblock
}

SubShader
{

Tags 
{ 
    "RenderType" = "Opaque"
    "Queue" = "Geometry"
    "IgnoreProjector" = "True" 
    "RenderPipeline" = "UniversalPipeline" 
    "DisableBatching" = "True"
}

LOD 200

HLSLINCLUDE

#define WORLD_SPACE 

#define OBJECT_SHAPE_NONE

#define CHECK_IF_INSIDE_OBJECT

#define DISTANCE_FUNCTION DistanceFunction
#define POST_EFFECT PostEffect

#include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
#include "Assets\uRaymarching\Runtime\Shaders\Include\UniversalRP/Primitives.hlsl"
#include "Assets\uRaymarching\Runtime\Shaders\Include\UniversalRP/Math.hlsl"
#include "Assets\uRaymarching\Runtime\Shaders\Include\UniversalRP/Structs.hlsl"
#include "Assets\uRaymarching\Runtime\Shaders\Include\UniversalRP/Utils.hlsl"

// @block DistanceFunction
float4x4 _Plane;
float4x4 _Sphere;
float4x4 _Player;

float _Smooth;

inline float DistanceFunction(float3 wpos)
{
    float4 pPos = mul(_Plane, float4(wpos, 1.0));
    float4 playerPos = mul(_Player, float4(wpos, 1.0));
    float p = Plane(pPos, float3(0, 1, 0));
    float s = Sphere(Repeat(wpos, 15.), 5.);
    float playerSphere = Sphere(playerPos, 15.);

    return min(smax(-playerSphere, smin(s, p, _Smooth), _Smooth), p);
}
// @endblock

#define PostEffectOutput float4

// @block PostEffect
float4 _PlaneColor;
float4 _SphereColor;
float4 _PlayerColor;

// float3 CalculateFresnelEffect(CustomLightingData d, Light light)
// {
//     Light light = GetMainLight();
//     float EdgeIllumination = pow(1 - saturate(dot(d.viewDirectionWS, d.normalWS)), d.edgePower);
//     float ShadowTerm = pow(saturate(dot(d.normalWS, -(light.direction))), d.shadowPower);

//     return (max(step(0.2, (EdgeIllumination * ShadowTerm)), ((EdgeIllumination * ShadowTerm) * 0.25)) * d.fresnelStrength) * light.color;
// }

inline void PostEffect(RaymarchInfo ray, inout PostEffectOutput o)
{
    float3 wpos = ray.endPos;
    float4 pPos = mul(_Plane, float4(wpos, 1.0));
    float4 sPos = mul(_Sphere, float4(wpos, 1.0));
    float4 playerPos = mul(_Player, float4(wpos, 1.0));
    float p = Plane(pPos, float3(0, 1, 0));
    float s = Sphere(sPos, 5.);
    float playerSphere = Sphere(playerPos, 30.);
    float3 a = normalize(saturate(float3(1.0 / p, 1.0 / s, 1.0 / playerSphere)));
    o = lerp(o,  // remove normalize when found issue of smax lighting thing
        a.x * _PlaneColor +
        a.y * _SphereColor + 
        a.z * _PlayerColor, .5);
    //o += CalculateFresnelEffect();
}
// @endblock

ENDHLSL

Pass
{
    Name "Unlit"

    Blend [_BlendSrc] [_BlendDst]
    ZWrite [_ZWrite]
    Cull [_Cull]

    HLSLPROGRAM

    #pragma shader_feature _ALPHAPREMULTIPLY_ON
    #pragma multi_compile_fog
    #pragma multi_compile_instancing
    #pragma prefer_hlslcc gles
    #pragma exclude_renderers d3d11_9x
    #pragma target 2.0

    #pragma vertex Vert
    #pragma fragment Frag
    #include "Assets\uRaymarching\Runtime\Shaders\Include\UniversalRP/ForwardUnlit.hlsl"

    ENDHLSL
}

Pass
{
    Name "DepthNormals"
    Tags { "LightMode" = "DepthNormals" }

    ZWrite On
    Cull [_Cull]

    HLSLPROGRAM

    #pragma shader_feature _ALPHATEST_ON
    #pragma multi_compile_instancing

    #pragma prefer_hlslcc gles
    #pragma exclude_renderers d3d11_9x
    #pragma target 2.0

    #pragma vertex Vert
    #pragma fragment Frag
    #include "Assets\uRaymarching\Runtime\Shaders\Include\UniversalRP/DepthNormals.hlsl"

    ENDHLSL
}

Pass
{
    Name "DepthOnly"
    Tags { "LightMode" = "DepthOnly" }

    ZWrite On
    ColorMask 0
    Cull [_Cull]

    HLSLPROGRAM

    #pragma shader_feature _ALPHATEST_ON
    #pragma multi_compile_instancing

    #pragma prefer_hlslcc gles
    #pragma exclude_renderers d3d11_9x
    #pragma target 2.0

    #pragma vertex Vert
    #pragma fragment Frag
    #include "Assets\uRaymarching\Runtime\Shaders\Include\UniversalRP/DepthOnly.hlsl"

    ENDHLSL
}

Pass
{
    Name "ShadowCaster"
    Tags { "LightMode" = "ShadowCaster" }

    ZWrite On
    ZTest LEqual
    Cull [_Cull]

    HLSLPROGRAM

    #pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
    #pragma multi_compile_instancing

    #pragma prefer_hlslcc gles
    #pragma exclude_renderers d3d11_9x
    #pragma target 2.0

    #pragma vertex Vert
    #pragma fragment Frag
    #include "Assets\uRaymarching\Runtime\Shaders\Include\UniversalRP/ShadowCaster.hlsl"

    ENDHLSL
}

}

FallBack "Hidden/Universal Render Pipeline/FallbackError"
CustomEditor "uShaderTemplate.MaterialEditor"

}