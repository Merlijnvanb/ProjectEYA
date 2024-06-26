Shader "Raymarching/UniversalRP_HexFloor"
{

Properties
{
    [Header(Base)][Space]
    [MainColor] _BaseColor("Color", Color) = (0.5, 0.5, 0.5, 1)
    [HideInInspector][MainTexture] _BaseMap("Albedo", 2D) = "white" {}
    [Gamma] _Metallic("Metallic", Range(0.0, 1.0)) = 0.5
    _Smoothness("Smoothness", Range(0.0, 1.0)) = 0.5
    [ToggleOff] _EnvironmentReflections("Environment Reflections", Float) = 1.0

    [Header(ClearCoat (Forward Only))][Space]
    [Toggle] _ClearCoat("Clear Coat", Float) = 0.0
    [HideInInspector] _ClearCoatMap("Clear Coat Map", 2D) = "white" {}
    _ClearCoatMask("Clear Coat Mask", Range(0.0, 1.0)) = 0.0
    _ClearCoatSmoothness("Clear Coat Smoothness", Range(0.0, 1.0)) = 1.0

    [Header(Pass)][Space]
    [Enum(UnityEngine.Rendering.CullMode)] _Cull("Culling", Int) = 2
    [Enum(UnityEngine.Rendering.BlendMode)] _BlendSrc("Blend Src", Float) = 5 
    [Enum(UnityEngine.Rendering.BlendMode)] _BlendDst("Blend Dst", Float) = 10
    [Toggle][KeyEnum(Off, On)] _ZWrite("ZWrite", Float) = 1

    [Header(Raymarching)][Space]
    _Loop("Loop", Range(1, 100)) = 30
    _MinDistance("Minimum Distance", Range(0.001, 0.1)) = 0.01
    _DistanceMultiplier("Distance Multiplier", Range(0.001, 2.0)) = 1.0
    _ShadowLoop("Shadow Loop", Range(1, 100)) = 10
    _ShadowMinDistance("Shadow Minimum Distance", Range(0.001, 0.1)) = 0.01
    _ShadowExtraBias("Shadow Extra Bias", Range(-1.0, 1.0)) = 0.01
    [PowerSlider(10.0)] _NormalDelta("NormalDelta", Range(0.00001, 0.1)) = 0.0001

// @block Properties
[Header(Additional Properties)]
_TopColor("TopColor", Color) = (1, 1, 1, 0)
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
    "UniversalMaterialType" = "Lit"
    "DisableBatching" = "True"
}

LOD 300

HLSLINCLUDE

#define OBJECT_SHAPE_CUBE

#define DISTANCE_FUNCTION DistanceFunction
#define POST_EFFECT PostEffect

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
#include "Assets\uRaymarching\Runtime\Shaders\Include\UniversalRP/Primitives.hlsl"
#include "Assets\uRaymarching\Runtime\Shaders\Include\UniversalRP/Math.hlsl"
#include "Assets\uRaymarching\Runtime\Shaders\Include\UniversalRP/Structs.hlsl"
#include "Assets\uRaymarching\Runtime\Shaders\Include\UniversalRP/Utils.hlsl"

// @block DistanceFunction
inline float DistanceFunction(float3 pos)
{
    // combine even hex tiles and odd hex tiles

    float radius = 0.2;
    float space = 0.1;
    float wave = 0.1;
    float3 objectScale = GetScale();
    float height = objectScale.y * 0.5 - wave;
    float3 scale = objectScale * 0.5;

    float pitch = radius * 2 + space;
    float3 offset = float3(pitch * 0.5, 0.0, pitch * 0.866);
    float3 loop = float3(offset.x * 2, 1.0, offset.z * 2);
	
    float3 p1 = pos;
    float3 p2 = pos + offset;

    // calculate indices
    float2 pi1 = floor(p1 / loop).xz;
    float2 pi2 = floor(p2 / loop).xz;
    pi1.y = pi1.y * 2 + 1;
    pi2.y = pi2.y * 2;

    p1 = Repeat(p1, loop);
    p2 = Repeat(p2, loop);

    // draw hexagonal prisms with random heights
   float dy1 = wave * sin(10 * Rand(pi1) + 5 * PI * _Time.x);
    float dy2 = wave * sin(10 * Rand(pi2) + 5 * PI * _Time.x);
    float d1 = HexagonalPrismY(float3(p1.x, pos.y + dy1, p1.z), float2(radius, height));
    float d2 = HexagonalPrismY(float3(p2.x, pos.y + dy2, p2.z), float2(radius, height));

    // maximum indices
    loop.z *= 0.5;
    float2 mpi1 = floor((scale.xz + float2(space * 0.5,    radius)) / loop.xz);
    float2 mpi2 = floor((scale.xz + float2(radius + space, radius)) / loop.xz);

    // remove partial hexagonal prisms
    // if (pi1.x >= mpi1.x || pi1.x <  -mpi1.x) d1 = max(d1, space);
    // if (pi1.y >= mpi1.y || pi1.y <= -mpi1.y) d1 = max(d1, space);
    float o1 = any(
        step(mpi1.x, pi1.x) +
        step(pi1.x + 1, -mpi1.x) +
        step(mpi1.y, abs(pi1.y)));
    d1 = o1 * max(d1, 0.1) + (1 - o1) * d1;

    //  if (!all(max(mpi2 - abs(pi2), 0.0))) d2 = max(d2, space);
    float o2 = any(step(mpi2, abs(pi2)));
    d2 = o2 * max(d2, 0.1) + (1 - o2) * d2;

    // combine
    return min(d1, d2);
}
// @endblock

#define PostEffectOutput SurfaceData

// @block PostEffect
float4 _TopColor;

inline void PostEffect(RaymarchInfo ray, inout PostEffectOutput o)
{
    float3 localPos = ToLocal(ray.endPos);
    o.emission += smoothstep(0.48, 0.50, localPos.y) * _TopColor;
    o.occlusion *= 1.0 - 1.0 * ray.loop / ray.maxLoop;
    o.albedo *= o.occlusion;
}
// @endblock

ENDHLSL

Pass
{
    Name "ForwardLit"
    Tags { "LightMode" = "UniversalForward" }

    Blend [_BlendSrc] [_BlendDst]
    ZWrite [_ZWrite]
    Cull [_Cull]

    HLSLPROGRAM

    #pragma shader_feature_local _RECEIVE_SHADOWS_OFF
    #pragma shader_feature_local_fragment _SURFACE_TYPE_TRANSPARENT
    #pragma shader_feature_local_fragment _ALPHATEST_ON
    #pragma shader_feature_local_fragment _ _ALPHAPREMULTIPLY_ON _ALPHAMODULATE_ON
    #pragma shader_feature_local_fragment _EMISSION
    #pragma shader_feature_local_fragment _SPECULARHIGHLIGHTS_OFF
    #pragma shader_feature_local_fragment _ENVIRONMENTREFLECTIONS_OFF
    #pragma shader_feature_local_fragment _CLEARCOAT_ON
    #ifdef _CLEARCOAT_ON
        #define _CLEARCOAT
    #endif

    #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
    #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
    #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
    #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
    #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
    #pragma multi_compile_fragment _ _SHADOWS_SOFT
    #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
    #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
    #pragma multi_compile_fragment _ _LIGHT_LAYERS
    #pragma multi_compile_fragment _ _LIGHT_COOKIES
    #pragma multi_compile _ _CLUSTERED_RENDERING

    #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
    #pragma multi_compile _ SHADOWS_SHADOWMASK
    #pragma multi_compile _ DIRLIGHTMAP_COMBINED
    #pragma multi_compile _ LIGHTMAP_ON
    #pragma multi_compile _ DYNAMICLIGHTMAP_ON
    #pragma multi_compile_fog
    #pragma multi_compile_fragment _ DEBUG_DISPLAY

    #pragma multi_compile_instancing
    #pragma instancing_options renderinglayer
    #pragma multi_compile _ DOTS_INSTANCING_ON

    #pragma prefer_hlslcc gles
    #pragma exclude_renderers d3d11_9x
    #pragma target 2.0

    #pragma vertex Vert
    #pragma fragment Frag
    #include "Assets\uRaymarching\Runtime\Shaders\Include\UniversalRP/ForwardLit.hlsl"

    ENDHLSL
}

Pass
{
    Name "GBuffer"
    Tags { "LightMode" = "UniversalGBuffer" }

    ZWrite [_ZWrite]
    ZTest LEqual
    Cull [_Cull]

    HLSLPROGRAM
    #pragma exclude_renderers gles gles3 glcore

    #pragma shader_feature_local _NORMALMAP
    #pragma shader_feature_local_fragment _ALPHATEST_ON
    #pragma shader_feature_local_fragment _EMISSION
    #pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED

    #pragma shader_feature_local_fragment _SPECULARHIGHLIGHTS_OFF
    #pragma shader_feature_local_fragment _ENVIRONMENTREFLECTIONS_OFF
    #pragma shader_feature_local_fragment _SPECULAR_SETUP
    #pragma shader_feature_local _RECEIVE_SHADOWS_OFF
    #pragma shader_feature_local_fragment _ENVIRONMENTREFLECTIONS_OFF
    #pragma shader_feature_local_fragment _CLEARCOAT_ON
    #ifdef _CLEARCOAT_ON
        #define _CLEARCOAT
    #endif

    #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
    #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
    #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
    #pragma multi_compile_fragment _ _SHADOWS_SOFT
    #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
    #pragma multi_compile_fragment _ _LIGHT_LAYERS
    #pragma multi_compile_fragment _ _RENDER_PASS_ENABLED

    #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
    #pragma multi_compile _ SHADOWS_SHADOWMASK
    #pragma multi_compile _ DIRLIGHTMAP_COMBINED
    #pragma multi_compile _ LIGHTMAP_ON
    #pragma multi_compile _ DYNAMICLIGHTMAP_ON
    #pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT

    #pragma multi_compile_instancing
    #pragma instancing_options renderinglayer
    #pragma multi_compile _ DOTS_INSTANCING_ON

    #pragma vertex Vert
    #pragma fragment Frag
    #include "Assets\uRaymarching\Runtime\Shaders\Include\UniversalRP/DeferredLit.hlsl"
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
    Name "DepthNormals"
    Tags { "LightMode" = "DepthNormals" }

    ZWrite On
    Cull [_Cull]

    HLSLPROGRAM

    #pragma shader_feature _ALPHATEST_ON
    #pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT
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