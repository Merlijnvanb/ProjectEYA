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
[HDR]_EnvironmentColorUp("Environment Color Up", Color) = (1.0, 1.0, 1.0, 1.0)
[HDR]_EnvironmentColorDown("Environment Color Down", Color) = (1.0, 1.0, 1.0, 1.0)
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

float _Speed = 0;
float _MaxSpeed = 1;

inline float ComputeTerrain(float3 wpos)
{
    float normalizedSpeed = Remap(_Speed / _MaxSpeed, 0., 1., 0., 0.4);

    float hNormal = dot(sin(wpos*.0173), cos(wpos.zxy*.0191))*30;
    float h = dot(sin(wpos*.0173*(sin(_Time * 0.1)/3. + 1.0)),cos(wpos*.0191*(sin(_Time * 0.1)/3. + 1.0)))*30;
    float h2 = pow(h, 2.0);

    float d = hNormal + sin(wpos.y*.03)/3;
    float d2 = h2/10. + sin(wpos.y*.3)/3;

    float tunnel = 15. - length(wpos.xy)-hNormal;

    return lerp(smax(d, tunnel, 80.), smax(d2, tunnel, 80.), normalizedSpeed);
}


inline float DistanceFunction(float3 wpos)
{
    float4 playerPos = mul(_Player, float4(wpos, 1.0));
    float playerSphere = Sphere(playerPos, 15.);

    return smax(-playerSphere, ComputeTerrain(wpos), _Smooth);
}
// @endblock

#define PostEffectOutput float4

// @block PostEffect

float4 _PlayerColor;
float4 _EnvironmentColorUp;
float4 _EnvironmentColorDown;

inline void PostEffect(RaymarchInfo ray, inout PostEffectOutput o)
{
    float3 wpos = ray.endPos;
    float3 normalWS = DecodeNormalWS(ray.normal);


    float4 playerPos = mul(_Player, float4(wpos, 1.0));
    float playerSphere = Sphere(playerPos, 15.);

    float terrain = ComputeTerrain(wpos);

    float upPointing = saturate(dot(float3(0., 1., 0.), normalWS)) * normalize(terrain);
    float downPointing = saturate(dot(float3(0., -1., 0.), normalWS)) * normalize(terrain);
    
    o = upPointing * _EnvironmentColorUp + downPointing * _EnvironmentColorDown;


    float ao = 1.0 - pow(1.0 * ray.loop / ray.maxLoop, 2);
    o.rgb *= ao;
    o.a *= pow(ao, 5);

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