#pragma once

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"
#include "Utility.hlsl"

CBUFFER_START(StylizedWater)
    float _WaterDepthFadeFactor;
    float _HorizonDistance;
    float4 _HorizonColor;
CBUFFER_END

TEXTURE2D(_WaterColorGradient);
SAMPLER(sampler_WaterColorGradient);

struct Attributes
{
    float4 positionOS : POSITION;
    float2 uv : TEXCOORD0;
    float3 normalOS : NORMAL;
};

struct Varyings
{
    float4 positionCS : SV_POSITION;
    float2 uv : TEXCOORD0;
    float4 positionSS : TEXCOORD1;
    float3 positionWS : TEXCOORD2;
    float3 viewDirWS : TEXCOORD3;
    float3 normalWS : NORMAL;
};

/// Get the water depth relative to the camera.
half GetWaterDepthRelativeToCamera(float4 positionSS, float2 uvSS)
{
    half sceneDepth = SampleSceneDepth(uvSS); // based on DeclareDepthTexture.hlsl in URP
    half sceneDepthEye = LinearEyeDepth(sceneDepth, _ZBufferParams); // Sample the scene depth and convert it to linear eye depth.
    half scenePos = positionSS.w;
    half waterDepth = sceneDepthEye - scenePos; // waterDepth = SceneDepth - ScenePosition
    waterDepth = saturate(waterDepth * _WaterDepthFadeFactor); // Linearly interpolate(can be changed to other interpolation methods)
    return waterDepth;
}

/// Get the water depth in WorldSpace.
half GetWaterDepthWorldSpace(float3 positionWS, float4 positionSS, float3 viewDirWS, float2 uvSS)
{
    half sceneDepth = SampleSceneDepth(uvSS); // based on DeclareDepthTexture.hlsl in URP
    half sceneDepthEye = LinearEyeDepth(sceneDepth, _ZBufferParams); // Sample the scene depth and convert it to linear eye depth.
    float3 scenePos = -viewDirWS / positionSS.w * sceneDepthEye + GetCameraPositionWS(); // Calculate the vector from the camera to the river bottom.
    half waterDepth = positionWS.y - scenePos.y; // waterDepth = River.y - RiverBottom.y
    waterDepth = 1 - saturate(exp(-waterDepth * _WaterDepthFadeFactor)); // Exponential interpolation(can be changed to other interpolation methods)
    return waterDepth;
}

half4 GetWaterAlbedo(float waterDepth, float3 normalWS, float3 viewDirWS, float2 uvSS)
{
    half4 depthColor = SAMPLE_TEXTURE2D(_WaterColorGradient, sampler_WaterColorGradient, float2(waterDepth, 0.5)); // depth based color
    half fresnel = GetFresnel(normalWS, SafeNormalize(viewDirWS), _HorizonDistance); // fresnel effect
    half3 sceneColor = SampleSceneColor(uvSS); // under water color
    half4 resultColor = half4(0, 0, 0, 0);
    HSVLerp_half(depthColor, _HorizonColor, fresnel, resultColor);
    resultColor.rgb = resultColor.rgb + sceneColor * (1 - resultColor.a);
    return resultColor;
}

Varyings vert(Attributes IN)
{
    Varyings OUT;
    OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
    OUT.positionCS = TransformWorldToHClip(OUT.positionWS);
    OUT.positionSS = ComputeScreenPos(OUT.positionCS);
    OUT.viewDirWS = GetWorldSpaceViewDir(OUT.positionWS);
    OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
    OUT.uv = IN.uv;
    return OUT;
}

half4 frag(Varyings IN) : SV_Target
{
    float2 uvSS = IN.positionSS.xy / IN.positionSS.w;
    half waterDepth = GetWaterDepthWorldSpace(IN.positionWS, IN.positionSS, IN.viewDirWS, uvSS);
    half4 resultColor = GetWaterAlbedo(waterDepth, IN.normalWS, IN.viewDirWS, uvSS);
    return resultColor;
}