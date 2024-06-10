#ifndef URAYMARCHING_STRUCTS_HLSL
#define URAYMARCHING_STRUCTS_HLSL

struct RaymarchInfo
{
    // Input
    float3 startPos;
    float3 rayDir;
    float3 polyPos;
    float3 polyNormal;
    float4 projPos;
    float minDistance;
    float maxDistance;
    int maxLoop;

    // Output
    int loop;
    float3 endPos;
    float lastDistance;
    float totalLength;
    float depth;
    float3 normal;
};

struct CustomLightingData
{
	// Position and Orientation
    float3 positionWS;
    float3 normalWS;
    float3 viewDirectionWS;
    float4 shadowCoord;
	
	// Surface Attributes
    float3 albedo;
    float smoothness;
    float ambientOcclusion;
    float ambientIntensity;
	
	// Baked lighting
    float3 bakedGI;
    float4 shadowMask;
    //float fogFactor;
    
    // Fresnel Effect
    float edgePower;
    float shadowPower;
    float fresnelStrength;
    
    // Stylized
    float cellAmount;
    float specularStrength;
    float posterizeSteps;
};

#endif