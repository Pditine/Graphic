#ifndef HMXS_OUTLINE_SHADERS_BLINNPHONGFORWARDLIT_HLSL
#define HMXS_OUTLINE_SHADERS_BLINNPHONGFORWARDLIT_HLSL

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

TEXTURE2D(_MainTex);
SAMPLER(sampler_MainTex);
CBUFFER_START(UnityPerMaterial)
    half4 _Color;
    half _Glossiness;
    half4 _SpecColor;
CBUFFER_END

struct Attributes
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float2 uv : TEXCOORD0;
};

struct Varyings
{
    float4 positionCS : SV_POSITION;
    float2 uv : TEXCOORD0;
    float3 positionWS : TEXCOORD1;
    float3 normalWS : TEXCOORD2;
};

Varyings vert(Attributes IN)
{
    Varyings OUT;

    VertexPositionInputs positionInputs = GetVertexPositionInputs(IN.positionOS.xyz);
    OUT.positionCS = positionInputs.positionCS;
    OUT.positionWS = positionInputs.positionWS;

    VertexNormalInputs normalInputs = GetVertexNormalInputs(IN.normalOS);
    OUT.normalWS = normalInputs.normalWS;

    OUT.uv = IN.uv;

    return OUT;
}

half4 frag(Varyings IN) : SV_Target
{
    half4 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv) * _Color;

    Light mainLight = GetMainLight();
    float3 lightDir = mainLight.direction;
    float3 viewDir = normalize(_WorldSpaceCameraPos - IN.positionWS);
    float3 halfDir = normalize(lightDir + viewDir);

    float3 normalWS = normalize(IN.normalWS);

    half NdotL = saturate(dot(normalWS, lightDir));
    half NdotH = saturate(dot(normalWS, halfDir));

    half3 diffuse = albedo.rgb * mainLight.color * NdotL;

    half specularPower = exp2(_Glossiness * 11) + 2;
    half3 specular = _SpecColor.rgb * pow(NdotH, specularPower) * _Glossiness;

    half3 ambient = SampleSH(normalWS) * albedo.rgb;

    half3 finalColor = ambient + diffuse + specular;
    return half4(finalColor, albedo.a);
}

#endif
