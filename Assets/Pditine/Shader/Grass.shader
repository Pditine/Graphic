Shader "LiJianhao/Grass"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Pass
        {
            CGPROGRAM
            #pragma exclude_renderers d3d11
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #pragma geometry geo

            #include "UnityCG.cginc"

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            
            struct geometryOutput
            {
	            float4 pos : SV_POSITION;
            };

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                // UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }

            [maxvertexcount(3)]
            void geo(triangle float4[3] : SV_POSITION, inout TriangleStream<geometryOutput> triStream)
            {
                geometryOutput o;

                o.pos = UnityObjectToClipPos(float4(0.5, 0, 0, 1));
                triStream.Append(o);

                o.pos = UnityObjectToClipPos(float4(-0.5, 0, 0, 1));
                triStream.Append(o);
                
                o.pos = UnityObjectToClipPos(float4(0, 1, 0, 1));
                triStream.Append(o);
            }
            ENDCG
        }
    }
	Fallback "Packages/com.unity.render-pipelines.universal/SimpleLit"
}
