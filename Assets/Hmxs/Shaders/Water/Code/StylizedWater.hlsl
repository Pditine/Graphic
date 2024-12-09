#pragma once

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

CBUFFER_START(StylizedWater)
    float _WaterDepthFadeFactor;
CBUFFER_END

TEXTURE2D(_WaterColorTex);
SAMPLER(sampler_WaterColorTex);

struct Attributes
{
    float4 positionOS : POSITION;
    float2 uv : TEXCOORD0;
};

struct Varyings
{
    float4 positionCS : SV_POSITION;
    float2 uv : TEXCOORD0;
    float4 positionSS : TEXCOORD1;
    float3 positionWS : TEXCOORD2;
    half3 viewDirWS : TEXCOORD3;
};

/// Get the water depth relative to the camera.
half GetWaterDepthRelativeToCamera(float4 positionSS, float2 uvSS)
{
    half sceneDepth = SampleSceneDepth(uvSS);
    half sceneDepthEye = LinearEyeDepth(sceneDepth, _ZBufferParams); // Sample the scene depth and convert it to linear eye depth.
    half scenePos = positionSS.w;
    half waterDepth = sceneDepthEye - scenePos; // waterDepth = SceneDepth - ScenePosition
    waterDepth = saturate(waterDepth * _WaterDepthFadeFactor); // Linearly interpolate(can be changed to other interpolation methods)
    return waterDepth;
}

/// Get the water depth in WorldSpace.
half GetWaterDepthWorldSpace(float3 positionWS, float4 positionSS, float3 viewDirWS, float2 uvSS)
{
    half sceneDepth = SampleSceneDepth(uvSS);
    half sceneDepthEye = LinearEyeDepth(sceneDepth, _ZBufferParams); // Sample the scene depth and convert it to linear eye depth.
    float3 scenePos = -viewDirWS / positionSS.w * sceneDepthEye + GetCameraPositionWS(); // Calculate the vector from the camera to the river bottom.
    half waterDepth = positionWS.y - scenePos.y; // waterDepth = River.y - RiverBottom.y
    waterDepth = 1 - saturate(exp(-waterDepth * _WaterDepthFadeFactor)); // Exponential interpolation(can be changed to other interpolation methods)
    return waterDepth;
}

Varyings vert(Attributes IN)
{
    Varyings OUT;
    OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
    OUT.positionCS = TransformWorldToHClip(OUT.positionWS);
    OUT.positionSS = ComputeScreenPos(OUT.positionCS);
    OUT.viewDirWS = GetWorldSpaceViewDir(OUT.positionWS);
    OUT.uv = IN.uv;
    return OUT;
}

half4 frag(Varyings input) : SV_Target
{
    half waterDepth = GetWaterDepthWorldSpace(input.positionWS, input.positionSS, input.viewDirWS, input.positionSS.xy / input.positionSS.w);
    half4 waterDepthColor = SAMPLE_TEXTURE2D(_WaterColorTex, sampler_WaterColorTex, float2(waterDepth, 0.5));
    return waterDepthColor;
}