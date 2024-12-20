Shader "Partopia/Scene/CloudPro"
{
    Properties
    {
        [Header(Cloud)]
        [Toggle]_LowCloud("低空云", float) = 0

        [NoScaleOffset]_FrontMap ("Front Map", 2D) = "white" { }
        [NoScaleOffset]_BackMap ("Back Map", 2D) = "white" { }
        _DensityMin("_DensityMin", Range(-1, 1)) = 0
        _DensityMax("_DensityMax", Range(-1, 2)) = 1

        _NoiseMap("扰动图", 2D) = "white" {}
        _NoiseSpeed("扰动速度", Range(0, 2)) = 0.5
        _Cloud_SDF_TSb("Cloud_SDF", Range(0.003, 1.5)) = 0.5

        _S_Cloud_LightRangeMin("云边缘下限", Range(-1, 1)) = 0
        _S_Cloud_LightRangeMax("云边缘上限", Range(-1, 2)) = 1

        [HDR]_Cloud_EdgeColorDay("云亮边颜色",color) = (1,1,1,1)
        _CloudStr("_CloudStr", Range(0, 1)) = 1
        
    }
    SubShader
    {
        Tags
        {
            "Queue"="Transparent-90"
            "RenderType" = "Transparent"
            "IgnoreProjector" = "True"

        }
        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite off
        Cull Off
        //ZTest NotEqual
        Pass
        {
            Name "ForwardLit"
            Tags{"LightMode" = "UniversalForward"}

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.lilith.render-pipelines.lit/ShaderLibrary/Core.hlsl"
            #include "Packages/com.lilith.render-pipelines.lit/ShaderLibrary/Lighting.hlsl"
            
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/VolumeRendering.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 texUV : TEXCOORD0;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;

                float2 uv : TEXCOORD0;

                float2 noiseuv : TEXCOORD1;

                float3 positionWS : TEXCOORD2;

                float3 normalWS : TEXCOORD3;

                float4 tangentWS : TEXCOORD4;    // xyz: tangent, w: sign

                float2 moonUV  : TEXCOORD5;
            };

            CBUFFER_START(UnityPerMaterial)

            half4 _CloudMap_ST;
            float4 _NoiseMap_ST;
            float _NoiseSpeed;

            half _Cloud_SDF_TSb;
            half4 _Cloud_EdgeColorDay;
            half _CloudStr;

            half _S_Cloud_LightRangeMin;
            half _S_Cloud_LightRangeMax;

            float _LowCloud;

            half _DensityMin;
            half _DensityMax;
            

            CBUFFER_END

            float _SkyScale;

            half _SkyOffLine;
            half4 _S_CloudColorDayFar;
            half _S_CloudDensity;
            half _S_CloudHeight;
            half _S_CloudMultiScattering;
            half _S_CloudPhase;

            half _SkyColorBlendMin;
            half _SkyColorBlendMax;
            half4 _HorizonColorDay;
            half4 _S_SkyColorDay;
            half4 _S_SunColorZenithFall;

            half4 _S_SunColorHorizon;

            half4 _S_SunsetFalloff;

            half _SunsetIntensity;

            half _MoonAngularDiameter;
            half _MoonSize;
            half _MoonIndex;
            half4 _S_MoonScatterColor;
            half _DaynightValue;

            TEXTURE2D(_NoiseMap);
            SAMPLER(sampler_NoiseMap);

            TEXTURE2D(_FrontMap);
            SAMPLER(sampler_FrontMap);
            TEXTURE2D(_BackMap);
            SAMPLER(sampler_BackMap);
            SAMPLER(sampler_linear_repeat);

            float4 _SunDirection;

            float4 _MoonDirection;

            float3 _MirrorCameraPos;

            half _CloudAlpha;

            #define PI 3.1415926

            #define TAU 6.2831855

            struct LightingInfo
            {
                half4 rawLightMap;
                half3 lightDir;
                half frontMap;
                half backMap;
            };

            half remap(half s1, half s2, half t1, half t2,half x)
            {
                return (x - s1) / (s2 - s1) * (t2 - t1) + t1;
            }

            half remap01(half s1, half s2,half x)
            {
                return saturate((x - s1) / (s2 - s1));
            }

            float remap2(float2 InMinMax, float2 OutMinMax,float In)
            {
                float Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
                return Out;
            }

            float ComputeLightMap(LightingInfo L)
            {
                float hMap = lerp(L.rawLightMap.y,L.rawLightMap.x,step(0.0f,L.lightDir.x));   // Picks the correct horizontal side.
                float vMap = lerp(L.rawLightMap.z,L.rawLightMap.w,step(0.0f,L.lightDir.y));   // Picks the correct Vertical side.
                float dMap = lerp(L.backMap,L.frontMap,step(0.0f,L.lightDir.z));              // Picks the correct Front/back Pseudo Map
                float lightMap = hMap*L.lightDir.x*L.lightDir.x + vMap*L.lightDir.y*L.lightDir.y + dMap*L.lightDir.z*L.lightDir.z; // Pythagoras!
                        return lightMap;
            }

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                float3x3 matrixV = float3x3(unity_MatrixV[0].xyz, unity_MatrixV[1].xyz, unity_MatrixV[2].xyz);
                float3 positionVS = mul(matrixV, o.positionWS.xyz);
                o.positionCS = mul(UNITY_MATRIX_P, float4(positionVS, 1));
                o.positionCS.z = UNITY_RAW_FAR_CLIP_VALUE * o.positionCS.w;

                o.uv = v.texUV;
                o.noiseuv = TRANSFORM_TEX(v.texUV, _NoiseMap);
                o.noiseuv = o.noiseuv * _NoiseMap_ST.xy + _NoiseMap_ST.zw + float2(frac(_Time.x * _NoiseSpeed),0);

                VertexNormalInputs normalInput = GetVertexNormalInputs(v.normalOS, v.tangentOS);
                o.normalWS = normalInput.normalWS;

                real sign = v.tangentOS.w * GetOddNegativeScale();
                o.tangentWS = half4(normalInput.tangentWS.xyz, sign);

                o.positionWS.y -= _SkyOffLine;
                float3 viewDir = -normalize(o.positionWS);
				float3 right = normalize(cross(normalize(_MoonDirection.xyz), float3(0, 1, 0)));
				float3 up = cross(normalize(_MoonDirection.xyz), right);
				o.moonUV.xy = float2(dot(right, viewDir), dot(up, viewDir));
				o.moonUV.xy = o.moonUV.xy * _MoonDirection.w * _SkyScale + 0.5;

                return o;
            }

            half4 frag(Varyings i) : SV_Target
            {
                float3 viewDir = -SafeNormalize(i.positionWS);
                float3 sunDir = -_SunDirection.xyz;
                float3 moonDir = _MoonDirection.xyz;
                float3 nPos = SafeNormalize(i.positionWS);
                half skyboxU = abs(nPos.y);
                half skyDownU = 1-skyboxU;
                skyDownU *= skyDownU * skyDownU * skyDownU * skyDownU;
                half daynightValue = step(0,sunDir.y);
                half4 currentCol = _S_CloudColorDayFar;
                float cloudExtinction = saturate(1-skyDownU);

                half3 horizonColor = _HorizonColorDay.rgb;
                half horizonPercent = _S_CloudColorDayFar.w;

                
                //Sun
                half sunLightDistance = distance(-sunDir,viewDir) * _SkyScale;

                //日落范围

                half sunsetHoriFalloffUp = smoothstep(_S_SunsetFalloff.x,_S_SunsetFalloff.y,sunLightDistance);

                half sunsetVerticalFalloffUp = 1-smoothstep(_S_SunsetFalloff.z,_S_SunsetFalloff.w,skyboxU * _SkyScale);

                half sunsetFalloff = (1-sunsetHoriFalloffUp) * smoothstep(sunsetHoriFalloffUp,1,sunsetVerticalFalloffUp);

                half sunSkyFalloff = 1-smoothstep(_S_SunColorZenithFall.w,_S_SunColorHorizon.w,sunLightDistance);

                currentCol = lerp(currentCol,_S_SunColorHorizon,_SunsetIntensity * saturate(sunsetFalloff));
                currentCol = lerp(currentCol,_S_SunColorZenithFall,_SunsetIntensity * saturate(sunSkyFalloff));

                //Moon
                float2 moonUV = (i.moonUV.xy - 0.5) * 0.1;
                float moonDist = 1-length(moonUV) * 2;
                float moonArea = saturate(1-distance(moonDir,viewDir));
                half moonPhase = step(1,_MoonIndex);

                half moonFalloffRange = smoothstep(_S_MoonScatterColor.w,_S_MoonScatterColor.w-1,moonDist) * moonArea * moonPhase;

                currentCol.rgb = lerp(currentCol.rgb,_S_MoonScatterColor.rgb,saturate(_SunsetIntensity * moonFalloffRange * moonArea));

    
                //Cloud
                half4 rigRTBk = SAMPLE_TEXTURE2D(_FrontMap, sampler_FrontMap, i.uv);
                half4 rigLBtF = SAMPLE_TEXTURE2D(_BackMap, sampler_BackMap, i.uv);

                LightingInfo L1;
                L1.rawLightMap = half4(rigRTBk.x,rigLBtF.x,rigLBtF.y,rigRTBk.y);


                float3 lightDir = SafeNormalize(lerp(moonDir,-sunDir,daynightValue));

                float sign = i.tangentWS.w;
                float3 bitangent = sign * cross(i.normalWS.xyz, i.tangentWS.xyz);
                half3 lightDirTS = TransformTangentToWorld(-lightDir, half3x3(i.tangentWS.xyz, bitangent.xyz, i.normalWS.xyz));

                L1.lightDir = lightDirTS;

                L1.frontMap = rigLBtF.b;
                L1.backMap = rigRTBk.b;

                half diffuse = ComputeLightMap(L1);

                diffuse = lerp(diffuse,L1.backMap,1-remap01(0.0,0.1,abs(sunDir.y)));

                half DirectDiffuse = remap01(_DensityMin,_DensityMax,diffuse);
                
                half3 cloudLightColor = lerp(lerp(0,_S_SkyColorDay.rgb,_S_SkyColorDay.w),currentCol.rgb,DirectDiffuse * cloudExtinction);

                //final
                half3 finalCol = cloudLightColor;
                half horizonPow = smoothstep(_SkyColorBlendMin,_SkyColorBlendMax,skyboxU);
                finalCol = lerp(lerp(finalCol,horizonColor.rgb,horizonPercent),finalCol,horizonPow);

                finalCol.rgb = pow(finalCol.rgb,2.2);

                half cloudAlphaTime = lerp(0,abs(sin(_Time.y * 0.5)),_LowCloud);

                half cloudAlphaLerp = max(_CloudAlpha,cloudAlphaTime);

                half cloudMask = 1-rigRTBk.b;

                half cloudAlpha = remap01(cloudMask,cloudMask-0.1,cloudAlphaLerp);

                return float4(finalCol, min(rigRTBk.a , _CloudStr * cloudAlpha));
            }
            ENDHLSL
        }
    }
}
