// 基于曲面细分和几何着色器的草地，支持交互物体和风吹效果
Shader"LiJianhao/Grass3"
{
	Properties
	{
		
	}

	// 由于我们的着色器是基于URP的，所以我们需要使用HLSLINCLUDE和ENDHLSL来包裹我们的HLSL代码。
	HLSLINCLUDE
	#pragma vertex vert
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
		// float4 pos : SV_POSITION;
		float3 norm : NORMAL;
		// float2 uv : TEXCOORD0;
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
	float3 _InteractorPosition; // 交互物位置，C#脚本中设置

	a2v vert(a2v v)
	{
		return v;
	}
	
	[maxvertexcount(64)]
	void geom(point v2g IN[1], inout TriangleStream<g2f> triStream)
	{
		float3 worldNormal = float3(0, 1, 0);
		float3 worldPos = TransformObjectToWorld(IN[0].pos.xyz);
		g2f o1;
		// o1.pos = TransformWorldToHClip(worldPos);
		o1.norm = worldNormal;
		o1.worldPos = worldPos;
		// o1.uv = IN[0].uv;
		
		triStream.Append(o1);
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
            #pragma fragment frag
			
			half4 frag(g2f i) : SV_Target
			{
				return 1;
			}
		   ENDHLSL
	   }
	}
}
