// 基于曲面细分和几何着色器的草地，支持交互物体和风吹效果
Shader"LiJianhao/Grass2"
{
	Properties
	{
		_TopColor("Top Color-草上部的颜色", Color) = (1,1,0,1)
		_BottomColor("Bottom Color-草下部的颜色", Color) = (0,1,0,1)
		_GrassHeight("Grass Height-草的高度", Float) = 1
		_GrassWidth("Grass Width-草的宽度", Float) = 0.06
		_RandomHeight("Grass Height Randomness-草高度的随机值", Float) = 0.25
		_Radius("Interactor Radius-草交互的半径", Float) = 0.3
		_Strength("Interactor Strength-草交互弯曲的力度", Float) = 5
		_Rad("Blade Radius-草的位置随机", Range(0,1)) = 0.6
		_BladeForward("Blade Forward Amount-草的倾倒", Float) = 0.38
		_BladeCurve("Blade Curvature Amount-草的弯曲", Range(1, 4)) = 2
		_AmbientStrength("Ambient Strength-环境光",  Range(0,1)) = 0.5
		_GrassNumber("Grass Number-草的数量(单个顶点)", Range(0, 10)) = 4
		_GrassSegments("Grass Segments-草的段数", Range(0, 10)) = 5
		_TessellationUniform ("Tessellation Uniform-草的数量(曲面细分)", Range(1, 64)) = 1
		_LightValue("Light Value-受光照影响的强度", Range(0,5)) = 0.5
		_WindDistortionMap("Wind Distortion Map", 2D) = "white" {}
		_WindSpeed("Wind Speed-风的速度", Vector) = (0.05, 0.05, 0, 0)
		_WindStrength("Wind Strength-风的力度", Range(0,0.1)) = 0.05
	}

	// 由于我们的着色器是基于URP的，所以我们需要使用HLSLINCLUDE和ENDHLSL来包裹我们的HLSL代码。
	HLSLINCLUDE
	#pragma vertex vert
	#pragma hull hull
	#pragma domain domain
	#pragma geometry geom
	#pragma fragment frag // rider这里会报错,可能是因为frag在subshader
	
	// 用于生成可以显示阴影的shader变体
	#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
	
	// urp支持三件套
	#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
	#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
	#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
	#include "HLSLSupport.cginc"
	
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
		float3 worldPos : TEXCOORD3;
	};

	half _GrassHeight;
	half _GrassWidth;
	float _WindStrength;
	half _Radius, _Strength;
	float _Rad;
	float _RandomHeight;
	float _BladeForward;
	float _BladeCurve;
	float _GrassNumber;
	float _GrassSegments;
	float _TessellationUniform;
	float _LightValue;
	sampler2D _WindDistortionMap;
	float4 _WindDistortionMap_ST;
	float4 _WindSpeed;
	uniform float3 _InteractorPosition; // 交互物位置，C#脚本中设置
	
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
		
		positionCS.z = min(positionCS.z, UNITY_NEAR_CLIP_VALUE);
		return positionCS;
	}

	// 计算用于片元着色器的草片数据
	g2f GrassVertex(float3 vertexPos, float width, float height, float offset, float curve, float2 uv, float3x3 rotation, float3 faceNormal)
	{
		g2f o;
		float3 offsetvertices = vertexPos + mul(rotation, float3(width, height, curve) + float3(0, 0, offset));
		o.pos = GetShadowPositionHClip(offsetvertices, faceNormal);
		o.norm = faceNormal;
		o.uv = uv;
		VertexPositionInputs vertexInput = GetVertexPositionInputs(vertexPos + mul(rotation, float3(width, height, curve)));
		o.worldPos = vertexInput.positionWS;
		return o;
	}

	a2v vert(a2v i)
	{
		return i;
	}

	struct TessellationFactors 
	{
		float edge[3] : SV_TessFactor;
		float inside : SV_InsideTessFactor;
	};

	v2g TessVert(a2v i)
	{
		v2g o;
		o.pos = i.positionOS;
		o.uv = i.texcoord;
		o.color = i.color;
		o.norm = TransformObjectToWorldNormal(i.normal);
		o.tangent = i.tangent;
		return o;
	}

	TessellationFactors PatchConstantFunction(InputPatch<a2v, 3> patch)
	{
	    TessellationFactors o;
	    o.edge[0] = _TessellationUniform;
	    o.edge[1] = _TessellationUniform;
	    o.edge[2] = _TessellationUniform;
	    o.inside = _TessellationUniform;
	    return o;
	}

	[UNITY_domain("tri")]
	[UNITY_outputcontrolpoints(3)]
	[UNITY_outputtopology("triangle_cw")]
	[UNITY_partitioning("integer")]
	[UNITY_patchconstantfunc("PatchConstantFunction")]
	a2v hull (InputPatch<a2v, 3> patch, uint id : SV_OutputControlPointID)
	{
		return patch[id];
	}
	
	[UNITY_domain("tri")]
	v2g domain(TessellationFactors factors, OutputPatch<a2v, 3> patch, float3 barycentricCoordinates : SV_DomainLocation)
	{
		a2v v; // 名字只能是v

		#define MY_DOMAIN_PROGRAM_INTERPOLATE(fieldName) v.fieldName = \
			patch[0].fieldName * barycentricCoordinates.x + \
			patch[1].fieldName * barycentricCoordinates.y + \
			patch[2].fieldName * barycentricCoordinates.z;

		MY_DOMAIN_PROGRAM_INTERPOLATE(positionOS)
		MY_DOMAIN_PROGRAM_INTERPOLATE(normal)
		MY_DOMAIN_PROGRAM_INTERPOLATE(tangent)

		return TessVert(v);
	}
	
	[maxvertexcount(64)]
	void geom(point v2g IN[1], inout TriangleStream<g2f> triStream)
	{
		// 获得一个随机的前向偏移
		float forward = rand(IN[0].pos.yyz) * _BladeForward;
		
		float3 worldNormal = float3(0, 1, 0);
		float3 worldPos = TransformObjectToWorld(IN[0].pos.xyz);

		// 随着距离的增加，distanceFade接近0，单个定点的草片数减少
		// float distanceFromCamera = distance(worldPos, _WorldSpaceCameraPos);
		// float distanceFade = 1 - saturate((distanceFromCamera - _MinDist) / _MaxDist);

		// 风的影响
		float3 v0 = IN[0].pos.xyz;
		// float3 wind = float3(sin(_Time.x * _WindSpeed + v0.x) + sin(_Time.x * _WindSpeed + v0.z * 2) + sin(_Time.x * _WindSpeed * 0.1 + v0.x), 0,
		// 	cos(_Time.x * _WindSpeed + v0.x * 2) + cos(_Time.x * _WindSpeed + v0.z));
		// wind *= _WindStrength;
		float2 uv = IN[0].pos.xz * _WindDistortionMap_ST.xy + _WindDistortionMap_ST.zw + _WindSpeed * _Time.y;
		float2 windSample = (tex2Dlod(_WindDistortionMap, float4(uv, 0, 0)).xy * 2 - 1) * _WindStrength;
		float3 wind = normalize(float3(windSample.x, windSample.y, 0));

		// 交互物体的影响
		float3 dis = distance(_InteractorPosition, worldPos); // 与交互物体的距离
		float3 radius = 1 - saturate(dis / _Radius); // 交互效果的范围，距离越近，效果越大
		float3 sphereDisp = worldPos - _InteractorPosition; // 计算交互引起的位移
		sphereDisp *= radius; // 距离衰减
		sphereDisp = clamp(sphereDisp.xyz * _Strength, -0.8, 0.8); // 强度
		
		// 草片高度，有随机性
		_GrassHeight *= clamp(rand(IN[0].pos.xyz), 1 - _RandomHeight, 1 + _RandomHeight);
		
		// 对于此次处理的顶点的每个草片
		for (int j = 0; j < _GrassNumber; j++)
		{
			// 随机旋转矩阵
			float3x3 facingRotationMatrix = AngleAxis3x3(rand(IN[0].pos.xyz) * TWO_PI + j, float3(0, 1, -0.1));

			float3x3 transformationMatrix = facingRotationMatrix;

			worldNormal = mul(worldNormal, transformationMatrix);
			float offset = (1 - j / _GrassNumber) * _Rad;
			
			// 对于草片的每个段
			for (int i = 0; i < _GrassSegments; i++)
			{
				// 变细变高
				float t = i / _GrassSegments;
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
				triStream.Append(GrassVertex(newPos, segmentWidth, segmentHeight, offset, segmentForward, float2(0, t), transformMatrix, worldNormal));
				triStream.Append(GrassVertex(newPos, -segmentWidth, segmentHeight, offset, segmentForward, float2(1, t), transformMatrix, worldNormal));
				
			}
			// 草片的顶部顶点
			triStream.Append(GrassVertex(v0 + float3(sphereDisp.x * 1.5, sphereDisp.y, sphereDisp.z * 1.5) + wind, 0, _GrassHeight, offset, forward, float2(0.5, 1), transformationMatrix, worldNormal));
			
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
			
			Tags
			{
				"RenderType" = "Opaque"
				"LightMode" = "UniversalForward"
			}
			HLSLPROGRAM

			#pragma vertex vert
			#pragma geometry geom
			#pragma hull hull
			#pragma domain domain
            #pragma fragment frag
			#pragma target 4.6

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
				
			float3 extraLights;
			int pixelLightCount = GetAdditionalLightsCount();
			// 对于每个除了主光源之外的光源
			for (int j = 0; j < pixelLightCount; ++j) {
				Light light = GetAdditionalLight(j, i.worldPos, half4(1, 1, 1, 1));
				float3 attenuatedLightColor = light.color * (light.distanceAttenuation * light.shadowAttenuation);
				extraLights += attenuatedLightColor;
			}
			// 通过uv的y值插值颜色
			float4 baseColor = lerp(_BottomColor, _TopColor, saturate(i.uv.y));
			
			float4 lightColor = baseColor * float4(mainLight.color,1);
			lightColor += float4(extraLights,1);
			// 通过LightValue插值颜色，否则颜色会太亮，同时增加光对明暗效果的影响
			float lightValue = (lightColor.r + lightColor.g + lightColor.b) /3 * _LightValue;
			lightColor = lerp( baseColor - float4(0.5,0.5,0.5,0), lightColor, lightValue); 
				
			float4 final = lightColor * shadow;
			final += saturate((1 - shadow) * baseColor * 0.2);
				
			final += (unity_AmbientSky * _AmbientStrength);
		   return final;
		   }
		   ENDHLSL
	   }
// 草相互接收阴影效果会非常奇怪
//		Pass
//		{
//			Name "ShadowCaster"
//			Tags{ "LightMode" = "ShadowCaster" }
//
//			ZWrite On
//			ZTest LEqual
//
//			HLSLPROGRAM
//			
//			#pragma vertex vert
//			#pragma geometry geom
//			#pragma hull hull
//			#pragma domain domain
//          #pragma fragment frag
//			#pragma target 4.6
//			
//			#define SHADERPASS_SHADOWCASTER
//
//			#pragma shader_feature_local _ DISTANCE_DETAIL
//
//			half4 frag(g2f input) : SV_TARGET
//			{
//				return 1;
//			}

//			ENDHLSL
//		}
	}
}
