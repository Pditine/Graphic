Shader "Hmxs/StylizedWater"
{
	Properties
	{
		_WaterDepthFadeFactor("WaterDepthFadeFactor", Range(0, 2)) = 1
		_WaterColorGradient("WaterColorGradient", 2D) = "white" {}
		_HorizonDistance("HorizonDistance", Range(0, 10)) = 2
		[HDR]_HorizonColor("HorizonColor", Color) = (1, 1, 1, 1)
	}
	SubShader
	{
		Tags
		{
			"RenderPipeline"="UniversalPipeline"
			"RenderType"="Transparent"
			"Queue"="Transparent"
			"IgnoreProjector"="True"
		}

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