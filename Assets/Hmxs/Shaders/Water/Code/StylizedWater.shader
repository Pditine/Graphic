Shader "Unlit/Test"
{
	Properties
	{
		_WaterDepthFadeFactor("WaterDepthFadeFactor", Range(0, 2)) = 1
		_WaterColorTex("WaterColorTex", 2D) = "white" {}
	}
	SubShader
	{
		Tags
		{
			"RenderType"="Transparent"
			"Queue" = "Transparent"
		}

		Pass
		{
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "StylizedWater.hlsl"
			ENDHLSL
		}
	}
}