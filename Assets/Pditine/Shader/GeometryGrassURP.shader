// 基于曲面细分和几何着色器的草地，支持交互物体和风吹效果
Shader"LiJianhao/Grass2"
{
	Properties
	{
		_TopColor("Top Color", Color) = (1,1,0,1)
		_BottomColor("Bottom Color", Color) = (0,1,0,1)
		_GrassHeight("Grass Height", Float) = 1
		_GrassWidth("Grass Width", Float) = 0.06
		_RandomHeight("Grass Height Randomness", Float) = 0.25
		_WindSpeed("Wind Speed", Float) = 100
		_WindStrength("Wind Strength", Float) = 0.05
		_Radius("Interactor Radius", Float) = 0.3
		_Strength("Interactor Strength", Float) = 5
		_Rad("Blade Radius", Range(0,1)) = 0.6
		_BladeForward("Blade Forward Amount", Float) = 0.38
		_BladeCurve("Blade Curvature Amount", Range(1, 4)) = 2
		_AmbientStrength("Ambient Strength",  Range(0,1)) = 0.5
		_GrassNumber("Grass Number", Range(0, 10)) = 4 // todo:曲面细分
		_MinDist("Min Distance", Float) = 40
		_MaxDist("Max Distance", Float) = 60
	}

	// 由于我们的着色器是基于URP的，所以我们需要使用HLSLINCLUDE和ENDHLSL来包裹我们的HLSL代码。
	HLSLINCLUDE
	#pragma vertex vert
	#pragma fragment frag
	#pragma require geometry
	#pragma geometry geom

	#define GrassSegments 5 // 每个草片的段数
	// #define GrassBlades 4 // 每个顶点的草片数

	// 用于生成shader变体
	#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
	#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
	#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
	#pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
	#pragma multi_compile_fragment _ _SHADOWS_SOFT
	#pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
	#pragma multi_compile _ SHADOWS_SHADOWMASK
	#pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
	#pragma multi_compile_fog   
	#pragma multi_compile _ DIRLIGHTMAP_COMBINED
	#pragma multi_compile _ LIGHTMAP_ON
		
	// urp支持三件套
	#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
	#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
	#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"	

	// 顶点输入结构体
	struct a2v
	{
		float4 positionOS : POSITION;
		float3 normal :NORMAL;
		float2 texcoord : TEXCOORD0;
		float4 color : COLOR;
		float4 tangent :TANGENT;
	};

	// 顶点输出结构体,传递给几何
	struct v2g
	{
		float4 pos : SV_POSITION;
		float3 norm : NORMAL;
		float2 uv : TEXCOORD0;
		float4 color : COLOR;
		float4 tangent : TANGENT;
	};

	// 几何输出结构体,传递给片元
	struct g2f
	{
		float4 pos : SV_POSITION;
		float3 norm : NORMAL;
		float2 uv : TEXCOORD0;
		float3 diffuseColor : COLOR;
		float3 worldPos : TEXCOORD3;
		float fogFactor : TEXCOORD5;
	};

	half _GrassHeight;
	half _GrassWidth;
	half _WindSpeed;
	float _WindStrength;
	half _Radius, _Strength;
	float _Rad;
	float _RandomHeight;
	float _BladeForward;
	float _BladeCurve;
	float _MinDist, _MaxDist;
	float _GrassNumber;
	uniform float3 _PositionMoving; // 交互物位置，C#脚本中设置
	
	/// https://forum.unity.com/threads/am-i-over-complicating-this-random-function.454887/#post-2949326
	/// Simple noise function, sourced from http://answers.unity.com/answers/624136/view.html
	/// Extended discussion on this function can be found at the following link:
	/// Returns a number in the 0...1 range.
	float rand(float3 co)
	{
		return frac(sin(dot(co.xyz, float3(12.9898, 78.233, 53.539))) * 43758.5453);
	}

	/// Construct a rotation matrix that rotates around the provided axis, sourced from:
	/// https://gist.github.com/keijiro/ee439d5e7388f3aafc5296005c8c3f33
	float3x3 AngleAxis3x3(float angle, float3 axis)
	{
		float c, s;
		sincos(angle, s, c);

		float t = 1 - c;
		float x = axis.x;
		float y = axis.y;
		float z = axis.z;

		return float3x3(
			t * x * x + c, t * x * y - s * z, t * x * z + s * y,
			t * x * y + s * z, t * y * y + c, t * y * z - s * x,
			t * x * z - s * y, t * y * z + s * x, t * z * z + c
			);
	}

	// 计算阴影的裁剪空间位置
	float4 GetShadowPositionHClip(float3 input, float3 normal)
	{
		float3 positionWS = TransformObjectToWorld(input.xyz);
		float3 normalWS = TransformObjectToWorldNormal(normal);

		float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, 0));
		
	#if UNITY_REVERSED_Z // 是否使用反向 Z 缓冲
			positionCS.z = min(positionCS.z, UNITY_NEAR_CLIP_VALUE);
	#else
			positionCS.z = max(positionCS.z, UNITY_NEAR_CLIP_VALUE);
	#endif
			return positionCS;
		}

	// 计算用于片元着色器的草片数据
	g2f GrassVertex(float3 vertexPos, float width, float height, float offset, float curve, float2 uv, float3x3 rotation, float3 faceNormal, float3 color) {
		g2f OUT;
		float3 offsetvertices = vertexPos + mul(rotation, float3(width, height, curve) + float3(0, 0, offset));
		OUT.pos = GetShadowPositionHClip(offsetvertices, faceNormal);
		OUT.norm = faceNormal;
		OUT.diffuseColor = color;
		OUT.uv = uv;
		VertexPositionInputs vertexInput = GetVertexPositionInputs(vertexPos + mul(rotation, float3(width, height, curve)));
		OUT.worldPos = vertexInput.positionWS;
		float fogFactor = ComputeFogFactor(OUT.pos.z);
		OUT.fogFactor = fogFactor;
		return OUT;
	}

	v2g vert(a2v v)
	{
		v2g OUT;
		OUT.pos = v.positionOS;
		OUT.uv = v.texcoord;
		OUT.color = v.color;
		OUT.norm = TransformObjectToWorldNormal(v.normal);
		OUT.tangent = v.tangent;
		return OUT;
	}
	
	[maxvertexcount(64)]
	void geom(point v2g IN[1], inout TriangleStream<g2f> triStream)
	{
		// 获得一个随机的前向偏移
		float forward = rand(IN[0].pos.yyz) * _BladeForward;

		// 草片的法线
		float3 faceNormal = float3(0, 1, 0);
		float3 worldPos = TransformObjectToWorld(IN[0].pos.xyz);

		// 随着距离的增加，distanceFade接近0，单个定点的草片数减少
		float distanceFromCamera = distance(worldPos, _WorldSpaceCameraPos);
		float distanceFade = 1 - saturate((distanceFromCamera - _MinDist) / _MaxDist);

		// 风的影响
		// todo:使用流动贴图
		float3 v0 = IN[0].pos.xyz;
		float3 wind = float3(sin(_Time.x * _WindSpeed + v0.x) + sin(_Time.x * _WindSpeed + v0.z * 2) + sin(_Time.x * _WindSpeed * 0.1 + v0.x), 0,
			cos(_Time.x * _WindSpeed + v0.x * 2) + cos(_Time.x * _WindSpeed + v0.z));
		wind *= _WindStrength;

		// 交互物体的影响
		float3 dis = distance(_PositionMoving, worldPos); // 与交互物体的距离
		float3 radius = 1 - saturate(dis / _Radius); // 交互效果的范围，距离越近，效果越大
		float3 sphereDisp = worldPos - _PositionMoving; // 计算交互引起的位移
		sphereDisp *= radius; // 距离衰减
		sphereDisp = clamp(sphereDisp.xyz * _Strength, -0.8, 0.8); // 强度

		// 草片的颜色
		float3 color = (IN[0].color).rgb;
		// set grass height from tool, uncomment if youre not using the tool!
		// _GrassHeight *= IN[0].uv.y;
		// _GrassWidth *= IN[0].uv.x;
		
		// 草片高度，有随机性
		_GrassHeight *= clamp(rand(IN[0].pos.xyz), 1 - _RandomHeight, 1 + _RandomHeight);

		// 对于此次处理的顶点的每个草片
		for (int j = 0; j < (_GrassNumber * distanceFade); j++)
		{
			// 随机旋转矩阵
			float3x3 facingRotationMatrix = AngleAxis3x3(rand(IN[0].pos.xyz) * TWO_PI + j, float3(0, 1, -0.1));

			float3x3 transformationMatrix = facingRotationMatrix;

			faceNormal = mul(faceNormal, transformationMatrix);
			float radius = j / (float)_GrassNumber;
			float offset = (1 - radius) * _Rad;
			// 对于草片的每个段
			for (int i = 0; i < GrassSegments; i++)
			{
				// 变细变高
				float t = i / (float)GrassSegments;
				float segmentHeight = _GrassHeight * t;
				float segmentWidth = _GrassWidth * (1 - t);

				// 最下面的段要稍细一点
				segmentWidth = i == 0 ? _GrassWidth * 0.3 : segmentWidth;

				float segmentForward = pow(abs(t), _BladeCurve) * forward;

				// 草片朝向的旋转矩阵
				float3x3 transformMatrix = i == 0 ? facingRotationMatrix : transformationMatrix;

				// 获得风吹，交互物体的影响后，草片的位置，第一个顶点不会受到影响
				float3 newPos = i == 0 ? v0 : v0 + ((float3(sphereDisp.x, sphereDisp.y, sphereDisp.z) + wind) * t);

				// 草片的底部顶点
				triStream.Append(GrassVertex(newPos, segmentWidth, segmentHeight, offset, segmentForward, float2(0, t), transformMatrix, faceNormal, color));
				triStream.Append(GrassVertex(newPos, -segmentWidth, segmentHeight, offset, segmentForward, float2(1, t), transformMatrix, faceNormal, color));
				
			}
			// 草片的顶部顶点
			triStream.Append(GrassVertex(v0 + float3(sphereDisp.x * 1.5, sphereDisp.y, sphereDisp.z * 1.5) + wind, 0, _GrassHeight, offset, forward, float2(0.5, 1), transformationMatrix, faceNormal, color));
			
			triStream.RestartStrip();
		}
	}
	ENDHLSL
	
	SubShader
	{
		Tags{ "RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline" }

		Cull Off
		Pass
		{
			HLSLPROGRAM

			float4 _TopColor;
			float4 _BottomColor;
			float _AmbientStrength;
			
			half4 frag(g2f i) : SV_Target
			{
				float4 shadowCoord = TransformWorldToShadowCoord(i.worldPos);
			#if _MAIN_LIGHT_SHADOWS_CASCADE || _MAIN_LIGHT_SHADOWS
			Light mainLight = GetMainLight(shadowCoord);
			#else
				Light mainLight = GetMainLight();
			#endif
				float shadow = mainLight.shadowAttenuation;

			// extra point lights support
			float3 extraLights;
			int pixelLightCount = GetAdditionalLightsCount();
			for (int j = 0; j < pixelLightCount; ++j) {
				Light light = GetAdditionalLight(j, i.worldPos, half4(1, 1, 1, 1));
				float3 attenuatedLightColor = light.color * (light.distanceAttenuation * light.shadowAttenuation);
				extraLights += attenuatedLightColor;
			}
			float4 baseColor = lerp(_BottomColor, _TopColor, saturate(i.uv.y)) * float4(i.diffuseColor, 1);

			// multiply with lighting color
			float4 litColor = (baseColor * float4(mainLight.color,1));

			litColor += float4(extraLights,1);
			// multiply with vertex color, and shadows
			float4 final = litColor * shadow;
			// add in basecolor when lights turned down
			final += saturate((1 - shadow) * baseColor * 0.2);
			// fog
			float fogFactor = i.fogFactor;

			// Mix the pixel color with fogColor. 
			final.rgb = MixFog(final.rgb, fogFactor);
			// add in ambient color
			final += (unity_AmbientSky * _AmbientStrength);
		   return final;
		   }
		   ENDHLSL
	   }
		
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }

			ZWrite On
			ZTest LEqual

			HLSLPROGRAM

			#define SHADERPASS_SHADOWCASTER

			#pragma shader_feature_local _ DISTANCE_DETAIL

			half4 frag(g2f input) : SV_TARGET
			{
				return 1;
			}

			ENDHLSL
		}
	}
}
