float GetSmoothnessPower(float rawSmoothness)
{
    return exp2(10 * rawSmoothness + 1);
}

float3 rgb2hsv(in float3 c) {
    float4 K = float4(0.0, -0.33333333333333333333, 0.6666666666666666666, -1.);
    float4 p = c.g < c.b ? float4(c.bg, K.wz) : float4(c.gb, K.xy);
    float4 q = c.r < p.x ? float4(p.xyw, c.r) : float4(c.r, p.yzx);
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return float3(  abs(q.z + (q.w - q.y) / (6. * d + e)), 
                    d / (q.x + e), 
                    q.x );
}

float3 hsv2rgb(float3 c)
{
    float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * lerp(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float3 PosterizeRGB(float3 In, float steps)
{
    float3 inHsv = rgb2hsv(In);
    float3 outHsv = floor(inHsv / (1 / steps)) * (1 / steps);
    return hsv2rgb(outHsv);
}

#ifndef SHADERGRAPH_PREVIEW

float3 CalculateFresnelEffect(CustomLightingData d, Light light)
{
    float EdgeIllumination = pow(1 - saturate(dot(d.viewDirectionWS, d.normalWS)), d.edgePower);
    float ShadowTerm = pow(saturate(dot(d.normalWS, -(light.direction))), d.shadowPower);

    return saturate(max(step(0.2, (EdgeIllumination * ShadowTerm)), ((EdgeIllumination * ShadowTerm) * 0.25)) * d.fresnelStrength) * light.color * (light.distanceAttenuation * light.shadowAttenuation);
}

float3 CustomGlobalIllumination(CustomLightingData d)
{
    float3 indirectDiffuse = d.albedo * d.bakedGI * d.ambientOcclusion;

    float3 ambientLight = d.albedo * d.ambientIntensity;
	
    float3 reflectVector = reflect(-d.viewDirectionWS, d.normalWS);
    float fresnel = Pow4(1 - saturate(dot(d.viewDirectionWS, d.normalWS)));
    float3 indirectSpecular = GlossyEnvironmentReflection(reflectVector,
        RoughnessToPerceptualRoughness(1 - d.smoothness),
        d.ambientOcclusion) * fresnel;
	
    return max(ambientLight, indirectDiffuse + indirectSpecular);
}

float3 CustomLightHandling(CustomLightingData d, Light light)
{
    float3 radiance = light.color * (light.distanceAttenuation * light.shadowAttenuation);
	
    float diffuse = saturate(dot(d.normalWS, light.direction));
    // Voor funky shadows verander naar max function en zet cellAmount op 0
    float steppedDiffuse = min(diffuse, (step(d.cellAmount, diffuse)));
    float specularCalc = saturate(dot(d.normalWS, normalize(light.direction + d.viewDirectionWS)));
    float specularDot = max(specularCalc, step(d.specularStrength, specularCalc));
    float specular = pow(specularDot, GetSmoothnessPower(d.smoothness)) * diffuse;

    float3 color = d.albedo * radiance * (steppedDiffuse + specular);
    color += CalculateFresnelEffect(d, light);
	
    return color;
}

#endif


float3 CalculateCustomLighting(CustomLightingData d)
{
    Light mainLight = GetMainLight(d.shadowCoord, d.positionWS, d.shadowMask);
	
	// In mixed subtractive baked lights, main light must be subtracted from bakedGI val
    MixRealtimeAndBakedGI(mainLight, d.normalWS, d.bakedGI);
	
    float3 color = CustomGlobalIllumination(d);
	// Shade the main light
    color += CustomLightHandling(d, mainLight);
	
        // Shade additional cone and point lights. Functions in URP/ShaderLibrary/Lighting.hlsl
        uint numAdditionalLights = GetAdditionalLightsCount();
        for (uint lightI = 0; lightI < numAdditionalLights; lightI++) {
            Light light = GetAdditionalLight(lightI, d.positionWS, d.shadowMask);
            color += CustomLightHandling(d, light);
        }

    return color;

}