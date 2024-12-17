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
			"Queue"="Transparent"
		}

		HLSLINCLUDE
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

		// 常量缓冲区，节约性能
		CBUFFER_START(UnityPerMaterial)
		float4 _MainTex_ST;
		float4 _BaseColor;
		float4 _CloudTopColor,_CloudBottomColor;
		float _Dissolve,_GIIndex;
		CBUFFER_END
		ENDHLSL

		Pass {
			Name "UnLit"
			Cull Front // 剔除正面
			Blend SrcAlpha OneMinusSrcAlpha // Result=(Source×SrcAlpha)+(Destination×(1−SrcAlpha))
			ZWrite Off
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			
			struct a2v {
				float4 positionOS	: POSITION;
				float4 normalOS		: NORMAL;
				float2 uv		    : TEXCOORD0;
				float2 lightmapUV	: TEXCOORD1;
			};

			struct v2f {
				float4 positionCS 	: SV_POSITION;
				float2 uv		    : TEXCOORD0;
				float3 normalWS		: TEXCOORD1;
				float3 positionWS	: TEXCOORD2;
				DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 3);
			};
			
			TEXTURE2D(_MainTex); // Texture2D textureName
			SAMPLER(sampler_MainTex); // SamplerState samplerName
			float4 _SunDir;

			/// 绕Y轴旋转
			float3 RotateAroundY(float3 postion,float speed)
			{
				speed *= _Time.x;
				float x = cos(speed)*postion.x+sin(speed)*postion.z;
				float y = postion.y;
				float z = -sin(speed)*postion.x+cos(speed)*postion.z;
				return float3(x,y,z);
			}

			// 旋转UV
			float2 RotateUV(float2 uv,float degress)
			{
				degress = DegToRad(degress);
				float u = cos(degress)*uv.x+sin(degress)*uv.y;
				float v = -sin(degress)*uv.x+cos(degress)*uv.y;
				return float2(u,v);
			}
			
			v2f vert(a2v i)
			{
				v2f o;
				VertexPositionInputs positionInputs = GetVertexPositionInputs(i.positionOS.xyz);
				//Output.positionCS = positionInputs.positionCS;
				o.positionWS = positionInputs.positionWS;

				// 添加摄像机位置的偏移
				float3 newWorldPos = (positionInputs.positionWS)+GetCameraPositionWS();
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
				half4 baseMap = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex,i.uv);

				Light light = GetMainLight();
				light.direction = _SunDir.xyz;
				float simpleLight = saturate(dot(light.direction.y,i.normalWS))*baseMap.r;
				float3 pixelDir = normalize(i.positionWS);
				float backLight = baseMap.g*saturate(dot(pixelDir,light.direction));
				float alpha = saturate((baseMap.b)-_Dissolve)*baseMap.a;

				backLight = 5*pow(backLight,8);

				float3 diffuse = lerp(_CloudBottomColor,_CloudTopColor,simpleLight+backLight);
				half3 color = diffuse * _BaseColor.rgb*light.color;
				
				half3 bakedGI = SAMPLE_GI(Input.lightmapUV, i.vertexSH, i.normalWS);
				color+= bakedGI*_GIIndex;
				
				half3 reflDir = reflect(-GetWorldSpaceViewDir(i.positionWS),i.normalWS);
				float3 test= GlossyEnvironmentReflection(reflDir,i.positionWS,1,1);
				color+=test;
				return half4(color, alpha);
			}
			ENDHLSL
		}
		
		// todo:ShadowCaster, for casting shadows

	}
}