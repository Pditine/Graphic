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

			void SetMoon(v2f i, inout float3 color)
			{
				float3 viewDir = normalize(GetWorldSpaceViewDir(i.positionWS));
				// 如果一个点,不在月亮应该在的地方,那么这个点就不是月亮(脱裤子放屁)
				// 通过视角和月亮方向的点积判断,太阳同理
				float hideMoon = saturate(dot(_MoonDir.xyz, viewDir));
				hideMoon = _MoonSize - hideMoon < 0 ? 1 : 0;
				float4 moonTex = _MoonIntensity * SAMPLE_TEXTURE2D(_MoonTexture, sampler_MoonTexture, i.moonUV.xy) * hideMoon;
				color +=  moonTex * _MoonGlowColor.rgb;
			}
			
			float3 SetSun(v2f i, float mask, float horizontalLine)
			{
				float3 sunColor = _SunGlowColor.rgb;
				float3 sunLightDir = -_SunDir.xyz;
				float3 viewDir = normalize(GetWorldSpaceViewDir(i.positionWS));
				float sundot = saturate(dot(sunLightDir, viewDir));
				float sun = _SunHalo.x * Pow4(sundot);
				sun += _SunHalo.y * pow(sundot, 32.0);
				sun += _SunHalo.z  * pow(sundot, 128.0);
				sun += _SunHalo.w * pow(sundot, 2048.0);
				float3 sunDisc = SAMPLE_TEXTURE2D(_SunDiscGradient, sampler_SunDiscGradient, float2(sundot,sundot)) * mask;
				return sunDisc + (sun+horizontalLine) * _SunIntensity*sunColor * Pow4(sundot);
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
				// UNITY_SETUP_INSTANCE_ID(input); 
				// UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o); 
				o.positionCS = mul(UNITY_MATRIX_MVP, i.positionOS);
				o.uv = i.uv;
				o.positionWS = TransformObjectToWorld(i.positionOS);
				float3 rMoon = normalize(cross(_MoonDir.xyz, float3(0, -1, 0)));
				float3 uMoon = cross(_MoonDir.xyz, rMoon);
				// _MoonDistance用于缩放月球的UV,使之贴合纹理
				o.moonUV.xy = float2(dot(rMoon, i.positionOS.xyz), dot(uMoon, i.positionOS.xyz)) * _MoonDistance + 0.5;
				o.positionOS = i.positionOS;
				return o;
			}
			
			half4 frag(v2f i) : SV_Target
			{
				float worldUp = normalize(i.positionWS).y;
				float3 dayGradient = SAMPLE_TEXTURE2D(_SkyRampMap, sampler_SkyRampMap, worldUp * 0.5 + 0.5);
				float3 nightGradient = SAMPLE_TEXTURE2D(_SkyWorldYRampMap, sampler_SkyWorldYRampMap, worldUp * 0.5 + 0.5);

				//horizontalLine
				//worldUp = worldUp*2+1;
				float horizon = abs(i.uv.y * 5) + 0.3;
				horizon = 1-smoothstep(0.0, 0.6, horizon);
				//worldUpMask 比地平线稍低的渐变
				float worldUpMask = worldUp + 0.1;
				worldUpMask = smoothstep(0, 0.1, worldUpMask);
				
				float3 color = 0;
				float3 skyGradient = lerp(dayGradient,nightGradient,saturate((1-saturate(_SunDir.y*5))));
				//sun
				color += skyGradient;
				color += SetSun(i, worldUpMask,horizon);
				//Moon
				//color =0;
				SetMoon(i, color);
				//star
				float3 star = _StarIntensity*SAMPLE_TEXTURECUBE(_StarTexture, sampler_StarTexture, RotateAroundY(i.positionOS.xyz,0.1));;
				color += star;
				return float4(color, 1);
			}
			ENDHLSL
		}
	}
}