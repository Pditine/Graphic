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
	float _TessellationUniform;
a2v vert(a2v v)
	{
	    return v;
	}

struct TessellationFactors 
	{
	    float edge[3] : SV_TessFactor;
	    float inside : SV_InsideTessFactor;
	};

v2g tessVert(a2v v)
{
    v2g OUT;
    OUT.pos = v.positionOS;
    OUT.uv = v.texcoord;
    OUT.color = v.color;
    OUT.norm = TransformObjectToWorldNormal(v.normal);
    OUT.tangent = v.tangent;
    return OUT;
}

TessellationFactors patchConstantFunction(InputPatch<a2v, 3> patch)
{
    TessellationFactors f;
    f.edge[0] = _TessellationUniform;
    f.edge[1] = _TessellationUniform;
    f.edge[2] = _TessellationUniform;
    f.inside = _TessellationUniform;
    return f;
}

[UNITY_domain("tri")]
[UNITY_outputcontrolpoints(3)]
[UNITY_outputtopology("triangle_cw")]
[UNITY_partitioning("integer")]
[UNITY_patchconstantfunc("patchConstantFunction")]
a2v hull (InputPatch<a2v, 3> patch, uint id : SV_OutputControlPointID)
{
    return patch[id];
}
	
[UNITY_domain("tri")]
v2g domain(TessellationFactors factors, OutputPatch<a2v, 3> patch, float3 barycentricCoordinates : SV_DomainLocation)
{
    a2v v;

    #define MY_DOMAIN_PROGRAM_INTERPOLATE(fieldName) v.fieldName = \
patch[0].fieldName * barycentricCoordinates.x + \
patch[1].fieldName * barycentricCoordinates.y + \
patch[2].fieldName * barycentricCoordinates.z;

    MY_DOMAIN_PROGRAM_INTERPOLATE(positionOS)
    MY_DOMAIN_PROGRAM_INTERPOLATE(normal)
    MY_DOMAIN_PROGRAM_INTERPOLATE(tangent)

    return tessVert(v);
}