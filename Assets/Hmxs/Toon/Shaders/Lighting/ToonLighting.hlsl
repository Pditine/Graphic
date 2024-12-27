#ifndef HMXS_TOONLIGHTING_HLSL
#define HMXS_TOONLIGHTING_HLSL

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

TEXTURE2D(_BaseMap);        SAMPLER(sampler_BaseMap);
TEXTURE2D(_DiffuseRamp);    SAMPLER(sampler_DiffuseRamp);
TEXTURE2D(_NormalMap);      SAMPLER(sampler_NormalMap);

CBUFFER_START(UnityPerMaterial)
    float4 _BaseColor;

    float _NormalStrength;

    float _DiffuseStrength;
    float _DiffuseAdditive;

    float _SpecularStep;
    float _SpecularStepSmooth;
    float4 _SpecularColor;

    float _RimStepSmooth;
    float _RimStep;
    float4 _RimColor;

    float _ShadowStep;
    float _ShadowStepSmooth;
CBUFFER_END

struct Attributes
{
    float4 positionOS   : POSITION;
    float3 normalOS     : NORMAL;
    float4 tangentOS    : TANGENT;
    float2 uv           : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionCS   : SV_POSITION;
    float2 uv           : TEXCOORD0;
    float3 normalWS     : TEXCOORD1;
    float3 tangentWS    : TEXCOORD2;
    float3 positionWS   : TEXCOORD3;
    float fogFactor     : TEXCOORD4;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

Varyings vert(Attributes IN)
{
    Varyings OUT;

    UNITY_SETUP_INSTANCE_ID(IN);
    UNITY_TRANSFER_INSTANCE_ID(IN, OUT);

    VertexPositionInputs vertexInputs = GetVertexPositionInputs(IN.positionOS.xyz);
    VertexNormalInputs normalInputs = GetVertexNormalInputs(IN.normalOS, IN.tangentOS);

    OUT.positionCS = vertexInputs.positionCS;
    OUT.uv = IN.uv;
    OUT.normalWS = normalInputs.normalWS;
    OUT.tangentWS = normalInputs.tangentWS;
    OUT.positionWS = vertexInputs.positionWS;
    OUT.fogFactor = ComputeFogFactor(vertexInputs.positionCS.z);

    return OUT;
}

float4 frag(Varyings IN) : SV_TARGET
{
    UNITY_SETUP_INSTANCE_ID(IN);

    // normal map
    float3 normalWS = normalize(IN.normalWS);
    float3 tangentWS = normalize(IN.tangentWS);
    float3 binormalWS = normalize(cross(normalWS, tangentWS));
    float3x3 TBN = float3x3(tangentWS, binormalWS, normalWS);
    float3 normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, IN.uv), _NormalStrength);
    float3 normal = normalize(mul(normalTS, TBN));

    // calculate
    Light mainLight = GetMainLight();
    float3 lightDirWS = mainLight.direction;
    float3 viewDirWS = GetWorldSpaceNormalizeViewDir(IN.positionWS);
    float3 halfDirWS = normalize(lightDirWS + viewDirWS);

    float NdotL = saturate(dot(normal, lightDirWS));
    float NdotH = saturate(dot(normal, halfDirWS));
    float NdotV = saturate(dot(normal, viewDirWS));

    // base color
    float4 baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv) * _BaseColor;

    // shadow
    float4 shadowCoord = TransformWorldToShadowCoord(IN.positionWS);
    float shadow = MainLightRealtimeShadow(shadowCoord);
    float shadowNdotL = smoothstep(_ShadowStep - _ShadowStepSmooth, _ShadowStep + _ShadowStepSmooth, NdotL);

    // ambient
    float3 ambient = SampleSH(normal) * baseColor.rgb;

    // diffuse
    float diffuseStrength = saturate(NdotL * _DiffuseStrength + _DiffuseAdditive);
    float diffuseFactor = SAMPLE_TEXTURE2D(_DiffuseRamp, sampler_DiffuseRamp, float2(diffuseStrength, 0.5)).r;
    float3 diffuse = baseColor.rgb * mainLight.color * diffuseFactor * shadow * shadowNdotL;

    // specular
    float specularStep = 1 - _SpecularStep * 0.05;
    float specularStepSmooth = _SpecularStepSmooth * 0.05;
    float specularFactor = smoothstep(specularStep  - specularStepSmooth, specularStep + specularStepSmooth, NdotH) ;
    float3 specular = _SpecularColor.rgb * specularFactor * shadow * shadowNdotL;

    // rim
    float rimStep = 1 - _RimStep;
    float rimStepSmooth = _RimStepSmooth * 0.5;
    float rimFactor = smoothstep(rimStep - rimStepSmooth, rimStep + rimStepSmooth, 0.5 - NdotV);
    float3 rim = _RimColor.rgb * rimFactor;

    float3 finalColor = ambient + diffuse + specular + rim;
    finalColor = MixFog(finalColor, IN.fogFactor);
    return float4(finalColor, baseColor.a);
}

#endif // HMXS_TOONLIGHTING_HLSL
