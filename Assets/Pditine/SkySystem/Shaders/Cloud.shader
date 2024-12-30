// 云的渲染
Shader "LiJianhao/Cloud" {
	Properties {
		_MainTex ("Main Texture", 2D) = "white" {}
		_Dissolve("Dissolve",Range(0,1)) = 1
	}
	SubShader {
		Tags {
			"RenderPipeline"="UniversalPipeline"
			"RenderType"="Opaque"
			"Queue"= "Transparent"
		}

		HLSLINCLUDE
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
		
		CBUFFER_START(UnityPerMaterial)
		float4 _MainTex_ST;
		float4 _BaseColor;
		float4 _CloudTopColor, _CloudBottomColor;
		float _Dissolve, _GIIndex, _CloudTime;
		CBUFFER_END
		ENDHLSL

		Pass {
			Name "UnLit"
			Cull Front // 剔除背面
			Blend SrcAlpha OneMinusSrcAlpha // Result=(Source×SrcAlpha)+(Destination×(1−SrcAlpha))
			
			Tags { "Queue" = "Background" }
//			ZWrite Off
//			ZTest Always
			
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			
			struct a2v
			{
				float4 positionOS	: POSITION;
				float4 normalOS		: NORMAL;
				float2 uv		    : TEXCOORD0;
				float2 lightmapUV	: TEXCOORD1;
			};

			struct v2f
			{
				float4 positionCS 	: SV_POSITION;
				float2 uv		    : TEXCOORD0;
				float3 normalWS		: TEXCOORD1;
				float3 positionWS	: TEXCOORD2;
				DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 3);
			};
			
			TEXTURE2D(_MainTex); // Texture2D textureName
			SAMPLER(sampler_MainTex); // SamplerState samplerName
			float4 _SunDir;
			
			v2f vert(a2v i)
			{
				v2f o;
				VertexPositionInputs positionInputs = GetVertexPositionInputs(i.positionOS.xyz);
				//Output.positionCS = positionInputs.positionCS;
				o.positionWS = positionInputs.positionWS;

				// 添加摄像机位置的偏移,在C#中处理云对于摄像机的位置偏移和旋转
				// float3 newWorldPos = positionInputs.positionWS + GetCameraPositionWS();
				float3 newWorldPos = positionInputs.positionWS;
				o.positionCS = TransformWorldToHClip(newWorldPos);
				
				VertexNormalInputs normalInputs = GetVertexNormalInputs(i.normalOS.xyz);
				o.normalWS = normalInputs.normalWS;
				
				// 球谐光照系数
				OUTPUT_SH(o.normalWS.xyz, o.vertexSH);
				o.uv = TRANSFORM_TEX(i.uv, _MainTex);
				return o;
			}
			
			half4 frag(v2f i) : SV_Target
			{
				// 云纹理: r-光照强度，g-背光强度，b-溶解阈值，a-透明度
				half4 baseMap = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex,i.uv);

				Light light = GetMainLight();
				light.direction = _SunDir.xyz; // 在编辑器中设置

				// 考虑光在云面方向上的强度
				float simpleLight = saturate(dot(light.direction, i.normalWS)) * baseMap.r;
				float3 pixelDir = normalize(i.positionWS);
				float backLight = baseMap.g*saturate(dot(pixelDir,light.direction));
				// 云的时间变化,过(0,0) (12,1) (24,0)的抛物线
				// 所以当时间为12时,云的透明度最大
				float timeValue = 1.0f / 6.0f * _CloudTime * (1.0f - 1.0f/24.0f * _CloudTime); 
				float alpha = saturate(baseMap.b - _Dissolve) * baseMap.a * timeValue;

				backLight = 5 * pow(backLight, 8);

				float3 diffuse = lerp(_CloudBottomColor, _CloudTopColor, simpleLight + backLight);
				half3 color = diffuse * _BaseColor.rgb * light.color;
				
				half3 bakedGI = SAMPLE_GI(Input.lightmapUV, i.vertexSH, i.normalWS);
				color += bakedGI * _GIIndex;
				
				half3 reflDir = reflect(-GetWorldSpaceViewDir(i.positionWS),i.normalWS);
				float3 test= GlossyEnvironmentReflection(reflDir,i.positionWS,1,1);
				color += test;
				return half4(color, alpha);
			}
			ENDHLSL
		}
		
	    Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" "Queue" = "Transparent"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            struct a2v
            {
                float4 positionOS : POSITION;
				float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 positionHCS : SV_POSITION;
            	float2 uv : TEXCOORD0;
            };

            sampler2D _MainTex;
            v2f vert(a2v i)
            {
                v2f o;
                o.positionHCS = TransformObjectToHClip(i.positionOS);
            	o.uv = i.uv;
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
            	half4 baseColor = tex2D(_MainTex, i.uv);
            	clip(baseColor.b-_Dissolve);
                return 0;
            }
            ENDHLSL
        }
	}
}