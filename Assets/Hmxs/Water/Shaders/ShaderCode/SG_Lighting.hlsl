#pragma once
#ifndef SHADERGRAPH_PREVIEW
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#endif

void MainLighting_float(float3 normalWS, float3 positionWS, float3 viewWS, float ambientStrength, float specularSmoothness, float specularHardness, float3 specularColor, out float3 ambient, out float3 diffuse, out float3 specular)
{
    ambient = float3(0.0f, 0.0f, 0.0f);
    diffuse = float3(0.0f, 0.0f, 0.0f);
    specular = float3(0.0f, 0.0f, 0.0f);

    // do not calculate lighting in preview
    #ifndef SHADERGRAPH_PREVIEW
    specularSmoothness = exp2(10 * specularSmoothness + 1);
    normalWS = normalize(normalWS);
    viewWS = SafeNormalize(viewWS); // prevent viewWS from being zero
    Light mainLight = GetMainLight(TransformWorldToShadowCoord(positionWS));

    // ambient
    ambient = mainLight.color * ambientStrength;

    // diffuse
    float3 lightDirWS = SafeNormalize(float3(mainLight.direction));
    float NdotL = saturate(dot(normalWS, lightDirWS));
    diffuse = mainLight.color * NdotL;

    // specular
    float3 halfDir = SafeNormalize(float3(mainLight.direction) + float3(viewWS));
    float NdotH = saturate(dot(normalWS, halfDir));
    float specularTerm = pow(NdotH, specularSmoothness);
    specularTerm = lerp(specularTerm, step(0.5f, specularTerm), specularHardness);
    specular = mainLight.color * specularTerm * specularColor.rgb;
    #endif
}

void AdditionalLighting_float(float3 normalWS, float3 positionWS, float3 viewWS, float specularSmoothness, float specularHardness, float3 specularColor, out float3 diffuse, out float3 specular)
{
    diffuse = float3(0.0f, 0.0f, 0.0f);
    specular = float3(0.0f, 0.0f, 0.0f);
    // do not calculate lighting in preview
    #ifndef SHADERGRAPH_PREVIEW
    specularSmoothness = exp2(10 * specularSmoothness + 1);
    normalWS = normalize(normalWS);
    viewWS = SafeNormalize(viewWS); // prevent viewWS from being zero

    for (int i = 0; i < GetAdditionalLightsCount(); i++)
    {
        Light additionalLight = GetAdditionalLight(i, positionWS);
        float3 lightColor = additionalLight.color * additionalLight.distanceAttenuation * additionalLight.shadowAttenuation;

        // diffuse
        float3 lightDirWS = SafeNormalize(float3(additionalLight.direction));
        float NdotL = saturate(dot(normalWS, lightDirWS));
        diffuse += lightColor * NdotL;

        // specular
        float3 halfDir = SafeNormalize(float3(additionalLight.direction) + float3(viewWS));
        float NdotH = saturate(dot(normalWS, halfDir));
        float specularSoftTerm = pow(NdotH, specularSmoothness);
        float specularHardTerm = smoothstep(0.005, 0.01, specularSoftTerm);
        float specularTerm = lerp(specularSoftTerm, specularHardTerm, specularHardness);
        specular += lightColor * specularTerm * specularColor.rgb;
    }
    #endif
}
