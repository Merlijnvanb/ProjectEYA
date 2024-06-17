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
    _Loop("Loop", Range(1, 200)) = 30
    _MinDistance("Minimum Distance", Range(0.001, 0.1)) = 0.01
    _DistanceMultiplier("Distance Multiplier", Range(0.001, 2.0)) = 1.0
    _ShadowLoop("Shadow Loop", Range(1, 100)) = 10
    _ShadowMinDistance("Shadow Minimum Distance", Range(0.001, 0.1)) = 0.01
    _ShadowExtraBias("Shadow Extra Bias", Range(-1.0, 1.0)) = 0.01
    [PowerSlider(10.0)] _NormalDelta("NormalDelta", Range(0.00001, 0.1)) = 0.0001

// @block Properties
[Header(Additional Properties)]
_Smooth("Smooth", float) = 1.0
_1to2("Stage 1 to 2", float) = 0.
_2to3("Stage 2 to 3", float) = 0.
[HDR]_EnvironmentColorUp("Environment Color Up", Color) = (1.0, 1.0, 1.0, 1.0)
[HDR]_EnvironmentColorDown("Environment Color Down", Color) = (1.0, 1.0, 1.0, 1.0)
[HDR]_PlayerColor("Player Color", Color) = (1.0, 1.0, 1.0, 1.0)

[Header(Custom Lighting)]
_SurfaceSmoothness("Smoothness", float) = .5
_AmbientOcclusion("Ambient Occlusion", float) = .5

_AmbientIntensity("Ambient Intensity", float) = 0.

_EdgePower("Edge Power", float) = 0.
_ShadowPower("Shadow Power", float) = 0.
_FresnelStrength("Fresnel Strength", float) = 0.

_CellAmount("Cell Amount", float) = 0.
_SpecularStrength("Specular Strength", float) = 0.
_PosterizeSteps("Posterize Steps", float) = 0.
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
float4x4 _Player;

float4x4 _Point4;
float4x4 _Point5;
float4x4 _Point6;
float4x4 _PointFinal;

float _Smooth;

float _Speed = 0;
float _MaxSpeed = 1;

float _1to2;
float _2to3;

inline float Terrain1Height(float2 pos)
{
    float duneHeight = cos(pos.y / 300.0) - abs(sin(pos.x / 300.0 * 0.7 + cos(pos.y / 300.0)));

    return duneHeight * 150.0-75.;
}

inline float ComputeTerrain1(float3 wpos)
{
    float height = Terrain1Height(float2(wpos.x, wpos.z));

    return wpos.y - height;
}

inline float ComputeTerrain2(float3 wpos)
{
    float4 point4Pos = mul(_Point4, float4(wpos, 1.0));
    float4 point5Pos = mul(_Point5, float4(wpos, 1.0));
    float4 point6Pos = mul(_Point6, float4(wpos, 1.0));

    float point4Sphere = Sphere(point4Pos, 100.);
    float point5Sphere = Sphere(point5Pos, 100.);
    float point6Sphere = Sphere(point6Pos, 200.);

    float minPoints = min(min(point4Sphere, point5Sphere), point6Sphere);

    float h = dot(sin(wpos*.0173), cos(wpos.zxy*.0191))*30;
//whynowork
    return smax(-minPoints, h, 100.);
}

inline float ComputeTerrain3(float3 wpos)
{
    float normalizedSpeed = Remap(_Speed / _MaxSpeed, 0., 1., 0., 0.4);

    float4 pointFinalPos = mul(_PointFinal, float4(wpos, 1.0));
    float pointFinalSphere = Sphere(pointFinalPos, 1000.);

    float hNormal = dot(sin(wpos*.0173), cos(wpos.zxy*.0191))*30;
    float h = dot(sin(wpos*.0173*(sin(_Time * 0.1)/3. + 1.0)),cos(wpos*.0191*(sin(_Time * 0.1)/3. + 1.0)))*30;
    float h2 = pow(h, 2.0);

    float d = hNormal + sin(wpos.y*.03)/3;
    float d2 = h2/10. + sin(wpos.y*.3)/3;

    float tunnel = 15. - length(wpos.xy)-hNormal;

    return smax(-pointFinalSphere, lerp(smax(d, tunnel, 80.), smax(d2, tunnel, 80.), normalizedSpeed), 200.);
}


inline float DistanceFunction(float3 wpos)
{
    float4 playerPos = mul(_Player, float4(wpos, 1.0));
    float playerSphere = Sphere(playerPos, 15.);

    float dist1to2 = lerp(ComputeTerrain1(wpos), ComputeTerrain2(wpos), _1to2);
    float dist1to3 = lerp(dist1to2, ComputeTerrain3(wpos), _2to3);

    return smax(-playerSphere, dist1to3, 80.);
}
// @endblock

#define PostEffectOutput float4

// @block PostEffect

float4 _PlayerColor;
float4 _EnvironmentColorUp;
float4 _EnvironmentColorDown;

inline float3 PostEffect(RaymarchInfo ray, inout PostEffectOutput o)
{
    float3 wpos = ray.endPos;
    float3 normalWS = DecodeNormalWS(ray.normal);


    float4 playerPos = mul(_Player, float4(wpos, 1.0));
    float playerSphere = Sphere(playerPos, 15.);

    float terrain = DistanceFunction(wpos);

    float upPointing = saturate(dot(float3(0., 1., 0.), normalWS));
    float downPointing = saturate(dot(float3(0., -1., 0.), normalWS));
    
    o = upPointing * _EnvironmentColorUp + downPointing * _EnvironmentColorDown;


    float ao = 1.0 - pow(1.0 * ray.loop / ray.maxLoop, 2);
    o.rgb *= ao;
    o.a *= pow(ao, 5);

    return o.rgb;

    // float h = dot(sin(wpos*.0173),cos(wpos.zxy*.0191))*30.;

    // float2 a = normalize(saturate(float2(1.0 / h, 1.0 / playerSphere)));
    // o *=   // remove normalize when found issue of smax lighting thing
    //     a.x * _EnvironmentColor + 
    //     a.y * _PlayerColor;

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