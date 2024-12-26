Shader "Hmxs/Outline_Normal"
{
	Properties
	{
		[Header(Base)]
		_MainTex ("Texture", 2D) = "white" {}
		_Color ("Color", Color) = (1, 1, 1, 1)
		_Glossiness ("Smoothness", Range(0, 1)) = 0.5
		_SpecColor ("Specular Color", Color) = (1, 1, 1, 1)

		[Header(Outline)]
		_OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)
		_OutlineWidth ("Outline Width", Range (0, 0.1)) = 0.01
	}
	SubShader
	{
		Tags
		{
			"RenderType"="Opaque"
			"RenderPipeline"="UniversalPipeline"
		}
		LOD 100

		Pass
		{
			Name "Outline_Normal"

			Tags { "LightMode" = "SRPDefaultUnlit" }
			Cull Front

			HLSLPROGRAM
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#pragma vertex vert
			#pragma fragment frag

			struct Attributes
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
			};

			struct Varyings
			{
				float4 positionCS : SV_POSITION;
			};

			float4 _OutlineColor;
			float _OutlineWidth;

			Varyings vert(Attributes input)
			{
				Varyings output;
				VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
				float3 positionWS = vertexInput.positionWS + input.normalOS * _OutlineWidth;
				output.positionCS = TransformWorldToHClip(positionWS);
				return output;
			}

			float4 frag(Varyings input) : SV_Target
			{
				return _OutlineColor;
			}
			ENDHLSL
		}

		Pass
		{
			Name "BlinnPhongForwardLit"
			Tags
			{
				"LightMode"="UniversalForward"
			}
			HLSLPROGRAM
			#include "BlinnPhongForwardLit.hlsl"
			#pragma vertex vert
			#pragma fragment frag
			ENDHLSL
		}
	}
}
