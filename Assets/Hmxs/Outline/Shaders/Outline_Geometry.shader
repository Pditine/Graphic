Shader "Hmxs/Outline_Geometry"
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
			Name "Outline_Geometry"

			Tags
			{
				"LightMode" = "SRPDefaultUnlit"
			}
			Cull Front

			HLSLPROGRAM
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#pragma require geometry
			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag

			struct Attributes
			{
				float4 positionOS : POSITION;
				float4 uv4 : TEXCOORD4;
			};

			struct Varyings
			{
				float4 positionCS : SV_POSITION;
				float3 positionWS : TEXCOORD0;
				float3 normalWS : NORMAL;
			};

			float4 _OutlineColor;
			float _OutlineWidth;

			Varyings vert(Attributes IN)
			{
				Varyings OUT;
				VertexPositionInputs vertexInput = GetVertexPositionInputs(IN.positionOS.xyz);
				OUT.positionCS = vertexInput.positionCS;
				OUT.positionWS = vertexInput.positionWS;

				OUT.normalWS = IN.uv4;
				return OUT;
			}

			[maxvertexcount(3)]
			void geom(triangle Varyings IN[3], inout TriangleStream<Varyings> triStream)
			{
				for (int i = 0; i < 3; i++)
				{
					Varyings v = IN[i];
					float3 expandedPosition = v.positionWS.xyz + v.normalWS * _OutlineWidth;
					v.positionCS = TransformWorldToHClip(float4(expandedPosition, 1.0));
					triStream.Append(v);
				}
				triStream.RestartStrip();
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
