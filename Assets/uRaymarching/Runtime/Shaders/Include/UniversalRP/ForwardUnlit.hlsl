#ifndef URAYMARCHING_FORWARD_UNLIT_HLSL
#define URAYMARCHING_FORWARD_UNLIT_HLSL

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
#include "Assets/Shaders/CustomLighting.hlsl"
#include "./Primitives.hlsl"
#include "./Raymarching.hlsl"
#include "./Structs.hlsl"

int _Loop;
float _MinDistance;
float4 _Color;

float _SurfaceSmoothness;
float _AmbientOcclusion;

float _EdgePower;
float _ShadowPower;
float _FresnelStrength;

float _CellAmount;
float _SpecularStrength;
float _PosterizeSteps;

float _AmbientIntensity;

struct Attributes
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionCS : SV_POSITION;
    float4 positionSS : TEXCOORD0;
    float3 normalWS : TEXCOORD1;
    float3 positionWS : TEXCOORD2;
    float fogCoord : TEXCOORD3;
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

struct FragOutput
{
    float4 color : SV_Target;
    float depth : SV_Depth;
};

Varyings Vert(Attributes input)
{
    Varyings output = (Varyings)0;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
    output.positionCS = vertexInput.positionCS;
    output.positionWS = vertexInput.positionWS;
    output.normalWS = TransformObjectToWorldNormal(input.normalOS);
    output.positionSS = ComputeNonStereoScreenPos(output.positionCS);
    output.positionSS.z = -TransformWorldToView(output.positionWS).z;
    output.fogCoord = ComputeFogFactor(output.positionCS.z);

    return output;
}

FragOutput Frag(Varyings input)
{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

    RaymarchInfo ray;
    INITIALIZE_RAYMARCH_INFO(ray, input, _Loop, _MinDistance);
    Raymarch(ray);

    InputData inputData = (InputData)0;
    inputData.positionWS = ray.endPos;
    inputData.normalWS = DecodeNormalWS(ray.normal);
    inputData.viewDirectionWS = SafeNormalize(GetCameraPosition() - ray.endPos);
    inputData.shadowCoord = TransformWorldToShadowCoord(ray.endPos);

    FragOutput o;


    CustomLightingData d;

    d.positionWS = inputData.positionWS;
    d.normalWS = inputData.normalWS;
    d.viewDirectionWS = inputData.viewDirectionWS;
    d.shadowCoord = inputData.shadowCoord;

    d.smoothness = _SurfaceSmoothness;
    d.ambientOcclusion = _AmbientOcclusion;
    d.ambientIntensity = _AmbientIntensity;

    float2 lightmapUV;
    OUTPUT_LIGHTMAP_UV(LightmapUV, unity_LightmapST, lightmapUV);
	
    float3 vertexSH;
    OUTPUT_SH(DecodeNormalWS(ray.normal), vertexSH);
	
    d.bakedGI = SAMPLE_GI(lightmapUV, vertexSH, DecodeNormalWS(ray.normal));
    d.shadowMask = SAMPLE_SHADOWMASK(lightmapUV);

    d.edgePower = _EdgePower;
    d.shadowPower = _ShadowPower;
    d.fresnelStrength = _FresnelStrength;

    d.cellAmount = _CellAmount;
    d.specularStrength = _SpecularStrength;
    d.posterizeSteps = _PosterizeSteps;

    //o.color = float4(1.0, 1.0, 1.0, 1.0);
    o.depth = ray.depth;

    AlphaDiscard(o.color.a, _Cutoff);

#ifdef _ALPHAPREMULTIPLY_ON
    o.color.rgb *= o.color.a;
#endif

#ifdef POST_EFFECT
    d.albedo = POST_EFFECT(ray, o.color);
#endif

    o.color.rgb = CalculateCustomLighting(d);
    o.color.rgb = MixFog(o.color.rgb, input.fogCoord);

    return o;
}

#endif