Shader "Hmxs/Toon"
{
	Properties
	{
		[Hearder(Base)]
		_BaseMap ("Base Map", 2D) = "white" {}
		_BaseColor ("Base Color", Color) = (1,1,1,1)

		[Space]
		[Header(Normal)]
		[Normal]_NormalMap ("Normal Map", 2D) = "bump" {}
		_NormalStrength ("Normal Strength", Range(0, 1)) = 1

		[Space]
		[Header(Diffuse)]
		_DiffuseRamp ("Diffuse Ramp", 2D) = "white" {}
		_DiffuseStrength ("Diffuse Strength", Range(0, 1)) = 1
		_DiffuseAdditive ("Diffuse Additive", Range(0, 1)) = 0

		[Space]
		[Header(Specular)]
		[HDR]_SpecularColor ("Specular Color", Color) = (1,1,1,1)
		_SpecularStep ("Specular Step", Range(0, 1)) = 0.6
		_SpecularStepSmooth ("Specular Step Smooth", Range(0, 1)) = 0.05

		[Space]
		[Header(Rim)]
		_RimColor ("Rim Color", Color) = (1,1,1,1)
		_RimStep ("Rim Step", Range(0, 1)) = 0.65
		_RimStepSmooth ("Rim Step Smooth", Range(0, 1)) = 0.4

		[Sapce]
		[Header(Shadow)]
		_ShadowStep ("Shadow Step", Range(0, 1)) = 0.5
		_ShadowStepSmooth ("Shadow Step Smooth", Range(0, 1)) = 0.04
	}
	SubShader
	{
		Tags
		{
			"RenderType" = "Opaque"
			"RenderPipeline" = "UniversalPipeline"
		}

		Pass
		{
			Tags
			{
				"LightMode"="UniversalForward"
			}
			Name "ForwardLit"

			HLSLPROGRAM
			#include "Lighting/ToonLighting.hlsl"
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma multi_compile_fog
            #pragma multi_compile_instancing
			ENDHLSL
		}
	}
}
