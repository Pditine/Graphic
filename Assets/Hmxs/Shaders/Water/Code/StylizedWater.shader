Shader "Unlit/Test"
{
	Properties
	{
		_WaterDepthFadeFactor("WaterDepthFadeFactor", Range(0, 2)) = 1
	}
	SubShader
	{
		Tags
		{
			"RenderType"="Transparent"
			"Queue" = "Transparent"
			"IgnoreProjector" = "True"
		}
		LOD 100

		Pass
		{
			Blend SrcColor DstColor
			Blend SrcAlpha OneMinusSrcAlpha

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "StylizedWater.hlsl"
			ENDHLSL
		}
	}
}