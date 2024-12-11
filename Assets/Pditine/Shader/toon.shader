Shader "Lijianhao/Cartoon"
{
	Properties
	{
		_BaseMap ("BaseMap", 2D) = "white" {}
		_SSSMap ("SSSMap", 2D) = "black" {}
		_ILM ("ILM Map", 2D) = "white" {}
		_DetalMap ("DetalMap", 2D) = "black" {}
		_ToonThesHold ("ToonThesHold", Range(0, 1)) = 0.5
		_ToonHardness ("ToonHardness", float) = 20
		_SpecSize ("SpecSize", Range(0,1)) = 0.1
		_SpecColor ("SpecColor", Color) = (1,1,1,1)
		_OutLineWidth("OutLineWidth" , Float) = 7
		_OutLineColor("OutLineColor", Color) = (0,0,0,1)
		_OutLineZBias("OutLineZbias", Float) = -10
		_RimLightDir("RimLightDir", Vector) = (1,0,-1,0)
		_RimLightColor("RimLightColor", Color) = (1,1,1,1)
	}
	SubShader
	{
		Tags { "lightmode" = "ForwardBase" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma mutli_compile_fwdbase
			
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"

			struct a2v
			{
				float4 vertex : POSITION;
				float2 texcoord0 : TEXCOORD0;
				float2 texcoord1 : TEXCOORD1;
				float3 normal : NORMAL;
				float4 color : COLOR;
			};

			struct v2f
			{

				float4 pos : SV_POSITION;
				float4 uv : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
				float3 worldNormal : TEXCOORD2;
				float4 vertexColor : TEXCOORD3;
				SHADOW_COORDS(4)
			};

			sampler2D _BaseMap;
			float4 _BaseMap_ST;
			sampler2D _SSSMap;
			float4 _SSSMap_ST;
			float _ToonThesHold;
			float _ToonHardness;
			sampler2D _ILM;
			float4 _ILM_ST;
			float _SpecSize;
			float4 _SpecColor;
			sampler2D _DetalMap;
			float4 _DetalMap_ST;
			float4 _RimLightDir;
			float4 _RimLightColor;
			
			v2f vert (a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = float4(v.texcoord0,v.texcoord1);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.vertexColor = v.color;
				TRANSFER_SHADOW(o)
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				half2 uv1 = i.uv.xy;
				half2 uv2 = i.uv.zw;

				//向量
				float3 normalDir = normalize(i.worldNormal);
				float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
				float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
				//颜色
				half4 baseMap = tex2D(_BaseMap, uv1);
				half3 baseColor = baseMap.rgb;
				half baseMask = baseMap.a;
				//暗部颜色
				half4 sssMap = tex2D(_SSSMap, uv1);
				half3 sssColor = sssMap.rgb;
				half sssAlpha = sssMap.a;
				//一堆数据
				half4 ilmMap = tex2D(_ILM, uv1);
				float specIntensity = ilmMap.r;
				float diffuseControl = ilmMap.g * 2 - 1;
				float specSize = ilmMap.b;
				float innerLine = ilmMap.a;
				
				float ao = i.vertexColor.r;
				float atten = lerp(1,SHADOW_ATTENUATION(i),i.vertexColor.g);

				//漫反射
				half NdotL = dot(normalDir, lightDir);
				half halfLambert = NdotL * 0.5 + 0.5;
				half labmbertTerm = halfLambert * ao * atten + diffuseControl;
				half toonDiffuse = saturate((labmbertTerm - _ToonThesHold)*_ToonHardness);
				half3 finalDiffuse = lerp(sssColor,baseColor,toonDiffuse);

				//高光
				float NdotV = dot(normalDir, viewDir) * 0.5 + 0.5;
				float specTerm = NdotV * ao + diffuseControl;
				specTerm = halfLambert * 0.9 + specTerm * 0.1;
				half toonSpec = saturate((specTerm - (1 - specSize * _SpecSize)) * 500);
				half3 specColor = (_SpecColor.rgb + baseColor) * 0.5;
				half3 finalSpec = specColor * toonSpec * specIntensity;
				//描边
				half3 LineColor = lerp(baseColor * 0.2,float3(1,1,1),innerLine);
				half3 detalColor = tex2D(_DetalMap, uv2).rgb;
				detalColor = lerp(baseColor*0.2, float3(1,1,1),detalColor);
				half3 finalLine = detalColor * LineColor;
				//补光
				float3 rimLightDir = normalize(mul((float3x3)unity_MatrixInvV,_RimLightDir.xyz));
				half rimNdotL = dot(normalDir, rimLightDir);
				half rimHalfLambert = rimNdotL * 0.5 + 0.5;
				half rimLabmbertTerm = rimHalfLambert + diffuseControl;
				half toonRim = saturate((rimLabmbertTerm - _ToonThesHold) * 20);
				half3 rimColor = (_RimLightColor.rgb + baseColor) * 0.5 * sssAlpha;
				half3 finalRimLight = toonRim * rimColor * toonDiffuse * baseMask * _RimLightColor.a;
				
				half3 finalColor = (finalDiffuse + finalSpec + finalRimLight)* finalLine;
				finalColor = sqrt(max(exp2(log2(max(finalColor,0.0)) * 2.2), 0.0)); // ???
				return float4(finalColor,1);
			}
			ENDCG
		}
		Pass
		{
			Cull Front
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"

			struct a2v
			{
				float4 vertex : POSITION;
				float2 texcoord0 : TEXCOORD0;
				float2 texcoord1 : TEXCOORD1;
				float3 normal : NORMAL;
				float4 color : COLOR;
			};

			struct v2f
			{

				float4 pos : SV_POSITION;
				float4 uv : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
				float3 worldNormal : TEXCOORD2;
				float4 vertexColor : TEXCOORD3;
			};

			sampler2D _BaseMap;
			float4 _BaseMap_ST;
			// sampler2D _SSSMap;
			// float4 _SSSMap_ST;
			// float _ToonThesHold;
			// float _ToonHardness;
			// sampler2D _ILM;
			// float4 _ILM_ST;
			// float _SpecSize;
			// float4 _SpecColor;
			// sampler2D _DetalMap;
			// float4 _DetalMap_ST;
			float _OutLineWidth;
			float4 _OutLineColor;
			float _OutLineZBias;
			
			v2f vert (a2v v)
			{
				v2f o;

				float3 viewPos = UnityObjectToViewPos(v.vertex);
				float3 worldNormal = UnityObjectToWorldNormal(v.normal);
				float3 outLineDir = normalize(mul((float3x3)unity_MatrixV, worldNormal));
				outLineDir.z += _OutLineZBias * (1 - v.color.b);
				viewPos += outLineDir * _OutLineWidth * 0.001;
				o.pos = mul(UNITY_MATRIX_P, float4(viewPos,1));
				o.uv = float4(v.texcoord0,v.texcoord1);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float3 baseColor = tex2D(_BaseMap, i.uv.xy).rgb;
				half maxComponent = max(max(baseColor.r,baseColor.g),baseColor.b) - 0.004;
				half3 saturatedColor = step(maxComponent.rrr,baseColor) * baseColor;
				saturatedColor = lerp(baseColor.rgb,saturatedColor,0.6f);
				half3 outLineColor = 0.8 * saturatedColor * baseColor * _OutLineColor.rgb;
				return float4(outLineColor,1);
				
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
}
