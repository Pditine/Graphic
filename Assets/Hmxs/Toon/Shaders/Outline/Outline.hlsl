#ifndef HMXS_OUTLINE_HLSL
#define HMXS_OUTLINE_HLSL

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

CBUFFER_START(UnityPerMaterial)
    float4 _OutlineColor;
    float _OutlineWidth;
CBUFFER_END

struct Attributes
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float4 uv4 : TEXCOORD4;
};

struct Varyings
{
    float4 positionCS : SV_POSITION;
};

Varyings vertNormal(Attributes IN)
{
    Varyings OUT;
    VertexPositionInputs vertexInputs = GetVertexPositionInputs(IN.positionOS.xyz);
    VertexNormalInputs normalInputs = GetVertexNormalInputs(IN.normalOS);
    float3 normalWS = normalInputs.normalWS;
    float3 positionWS = vertexInputs.positionWS + normalWS * _OutlineWidth;
    OUT.positionCS = TransformWorldToHClip(positionWS);
    return OUT;
}

Varyings vertSmoothedNormal(Attributes IN)
{
    Varyings OUT;
    VertexPositionInputs vertexInputs = GetVertexPositionInputs(IN.positionOS.xyz);
    float3 positionWS = vertexInputs.positionWS + IN.uv4.xyz * _OutlineWidth;
    OUT.positionCS = TransformWorldToHClip(positionWS);
    return OUT;
}

float4 frag(Varyings IN) : SV_Target
{
    return _OutlineColor;
}

#endif
