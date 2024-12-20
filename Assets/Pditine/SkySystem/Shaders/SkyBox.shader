Shader "LiJianhao/SkyBox" {
	Properties
	{
		_Color("Color",Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
	}
	SubShader
	{
		Pass
		{
			Tags {"Queue"="Background" "RenderType"="Background" "PreviewType"="Skybox" "IgnoreProjector"="True"}
			Cull Off
			ZWrite Off
			
			HLSLPROGRAM
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#pragma target 3.0

			#pragma vertex vert
			#pragma fragment frag
			
			struct a2v
			{
				float4 positionOS : POSITION;
				float2 uv:TEXCOORD0;
			};

			struct v2f
			{
				float4 positionCS : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 positionWS : TEXCOORD1;
				float2 moonUV : TEXCOORD2;
				float3 positionOS : TEXCOORD3;
			};

			TEXTURE2D(_MainTex);
			SAMPLER(sampler_MainTex);
			TEXTURE2D(_SkyRampMap);
			SAMPLER(sampler_SkyRampMap);
			TEXTURE2D(_SkyWorldYRampMap);
			SAMPLER(sampler_SkyWorldYRampMap);
			TEXTURE2D(_SunDiscGradient);
			SAMPLER(sampler_SunDiscGradient);
			TEXTURE2D(_MoonTexture);
			SAMPLER(sampler_MoonTexture);
			TEXTURECUBE(_StarTexture);
			SAMPLER(sampler_StarTexture);
			float4 _Color, _MoonGlowColor, _SunGlowColor;
			float4 _SunDir, _SunHalo, _MoonDir;
			float _StarIntensity, _SunIntensity, _MoonIntensity, _MoonDistance;
			float _MoonSize, _SunSize;

			float3 SetMoon(v2f i)
			{
				float3 viewDir = normalize(GetWorldSpaceViewDir(i.positionWS));
				// 如果一个点,不在月亮应该在的地方,那么这个点就不是月亮(脱裤子放屁)
				// 通过视角和月亮方向的点积判断,太阳同理
				float moonValue = saturate(dot(_MoonDir.xyz, viewDir));
				moonValue = _MoonSize - moonValue < 0 ? 1 : 0;
				float4 moonTex = _MoonIntensity * SAMPLE_TEXTURE2D(_MoonTexture, sampler_MoonTexture, i.moonUV.xy) * moonValue;
				return moonTex * _MoonGlowColor.rgb;
			}
			
			float3 SetSun(v2f i, float skyLineValue)
			{
				float3 sunColor = _SunGlowColor.rgb;
				float3 sunLightDir = -_SunDir.xyz;
				float3 viewDir = normalize(GetWorldSpaceViewDir(i.positionWS));
				// 对于太阳的影响,我们不进行和月亮一样的截断处理
				float sunValue = saturate(dot(sunLightDir, viewDir));
				float sun = 0;
				// 此时sunValue表示围绕太阳一圈的点
				sun += _SunHalo.x * pow(sunValue, 4.0);
				sun += _SunHalo.y * pow(sunValue, 32.0);
				sun += _SunHalo.z * pow(sunValue, 128.0);
				sun += _SunHalo.w * pow(sunValue, 2048.0);
				
				float3 sunDisc = SAMPLE_TEXTURE2D(_SunDiscGradient, sampler_SunDiscGradient, float2(sunValue, 0));
				// 当太阳在地平线上时,地平线附近的颜色会受到太阳的影响
				return sunDisc + (sun + skyLineValue) * _SunIntensity * sunColor * Pow4(sunValue);
			}

			// 非常好代码，使我的星星旋转，爱来自三角函数
			float3 RotateAroundY(float3 postion,float speed)
			{
				speed *= _Time.x;
				float x = cos(speed)*postion.x+sin(speed)*postion.z;
				float y = postion.y;
				float z = -sin(speed)*postion.x+cos(speed)*postion.z;
				return float3(x,y,z);
			}

			v2f vert(a2v i)
			{
				v2f o = (v2f)0;
				o.positionCS = mul(UNITY_MATRIX_MVP, i.positionOS);
				o.uv = i.uv;
				o.positionWS = TransformObjectToWorld(i.positionOS);
				float3 moonRight = normalize(cross(_MoonDir.xyz, float3(0, -1, 0)));
				float3 moonUp = cross(_MoonDir.xyz, moonRight);
				// _MoonDistance用于缩放月球的UV,使之贴合纹理
				o.moonUV.xy = float2(dot(moonRight, i.positionOS.xyz), dot(moonUp, i.positionOS.xyz)) * _MoonDistance + 0.5;
				o.positionOS = i.positionOS;
				return o;
			}
			
			half4 frag(v2f i) : SV_Target
			{
				float worldUp = normalize(i.positionWS).y;
				float3 dayGradient = SAMPLE_TEXTURE2D(_SkyRampMap, sampler_SkyRampMap, worldUp * 0.5 + 0.5);
				float3 nightGradient = SAMPLE_TEXTURE2D(_SkyWorldYRampMap, sampler_SkyWorldYRampMap, worldUp * 0.5 + 0.5);
				float3 color = 0;
				
				// _SunDir指向太阳，而非从太阳发射，所以y越大，太阳越高
				// 通过太阳的高度来判断天空颜色, 5是一个调整参数，仅当太阳高度在地线平附近，也就是_SunDir.y在0的附近时才会插值
				float3 skyGradient = lerp(nightGradient, dayGradient, saturate(_SunDir.y * 5));
				color += skyGradient;
				
				// 地平线
				float skyLineValue = abs(i.uv.y * 5) + 0.3;
				// 地平线上靠近太阳或月球的渐变
				skyLineValue = 1 - smoothstep(0.0, 0.6, skyLineValue);
				
				// sun
				color += SetSun(i, skyLineValue);
				
				// Moon
				color += SetMoon(i);
				
				// star
				float3 star = _StarIntensity * SAMPLE_TEXTURECUBE(_StarTexture, sampler_StarTexture, RotateAroundY(i.positionOS.xyz, 0.1));
				color += star;
				return float4(color, 1);
			}
			ENDHLSL
		}
	}
}