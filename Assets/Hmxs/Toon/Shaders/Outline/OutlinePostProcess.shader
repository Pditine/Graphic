Shader "Hmxs/OutlinePostProcess"
{
	Properties
	{
		[HDR] _OutlineColor("Outline Color", Color) = (1, 1, 1, 1)
		_OutlineWidth("Outline Width", Range(0, 0.01)) = 0.002
	}
	SubShader
	{
		Tags
		{
			"RenderType"="Opaque"
			"RenderPipeline"="UniversalPipeline"
		}

		Cull Off
		ZWrite Off
		Blend SrcAlpha OneMinusSrcAlpha

		Pass
		{
			HLSLPROGRAM

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

			#pragma vertex vert
			#pragma fragment frag

			struct Attributes
			{
				uint vertexID : SV_VertexID;
			};

			struct Varyings
			{
				float4 positionCS : SV_Position;
				float2 uv : TEXCOORD0;
				float2 offset[8] : TEXCOORD1;
			};

			TEXTURE2D(_OutlineMask);
			SAMPLER(sampler_linear_clamp_OutlineMask);

			float4 _OutlineColor;
			float _OutlineWidth;

			Varyings vert(Attributes IN)
			{
				Varyings OUT;
				OUT.positionCS = GetFullScreenTriangleVertexPosition(IN.vertexID);
				OUT.uv = GetFullScreenTriangleTexCoord(IN.vertexID);

				const float correction = _ScreenParams.x / _ScreenParams.y;

				OUT.offset[0] = float2(-1, correction * sqrt(2) / 2) * _OutlineWidth;
				OUT.offset[1] = float2( 0, correction) * _OutlineWidth;
				OUT.offset[2] = float2( 1, correction * sqrt(2) / 2) * _OutlineWidth;
				OUT.offset[3] = float2(-1, 0)		   * _OutlineWidth;
				OUT.offset[4] = float2( 1, 0)		   * _OutlineWidth;
				OUT.offset[5] = float2(-1,-correction * sqrt(2) / 2) * _OutlineWidth;
				OUT.offset[6] = float2( 0,-correction) * _OutlineWidth;
				OUT.offset[7] = float2( 1,-correction * sqrt(2) / 2) * _OutlineWidth;
				return OUT;
			}

			float4 frag(Varyings IN) : SV_Target
			{
				const float kernelX[8] = {
					-1, 0, 1,
					-2,    2,
					-1, 0, 1
				};
				const float kernelY[8] = {
					-1, -2, -1,
					 0,      0,
					 1,  2,  1
				};
				float gx = 0;
				float gy = 0;
				float mask = 0;
				for (int i = 0; i < 8; i++)
				{
					mask = SAMPLE_TEXTURE2D_X(_OutlineMask, sampler_linear_clamp_OutlineMask, IN.uv + IN.offset[i]).a;
					gx += mask * kernelX[i];
					gy += mask * kernelY[i];
				}
				const float alpha = SAMPLE_TEXTURE2D_X(_OutlineMask, sampler_linear_clamp_OutlineMask, IN.uv).a;
				float4 color = _OutlineColor;
				color.a = saturate(abs(gx) + abs(gy)) * (1 - alpha);
				return color;
			}

			ENDHLSL
		}
	}
}
