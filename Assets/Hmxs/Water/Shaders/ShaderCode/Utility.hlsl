#pragma once

/// color operation
float3 RGB2HSV(float3 In)
{
    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    float4 P = lerp(float4(In.bg, K.wz), float4(In.gb, K.xy), step(In.b, In.g));
    float4 Q = lerp(float4(P.xyw, In.r), float4(In.r, P.yzx), step(P.x, In.r));
    float D = Q.x - min(Q.w, Q.y);
    float E = 1e-10;
    return float3(abs(Q.z + (Q.w - Q.y)/(6.0 * D + E)), D / (Q.x + E), Q.x);
}

float3 HSV2RGB(float3 In)
{
    float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    float3 P = abs(frac(In.xxx + K.xyz) * 6.0 - K.www);
    return In.z * lerp(K.xxx, saturate(P - K.xxx), In.y);
}

void HSVLerp_float(float4 A, float4 B, float T, out float4 OUT)
{
    A.xyz = RGB2HSV(A.xyz);
    B.xyz = RGB2HSV(B.xyz);

    float t = T; // used to lerp alpha, needs to remain unchanged

    float hue;
    float d = B.x - A.x; // hue difference

    if(A.x > B.x)
    {
        float temp = B.x;
        B.x = A.x;
        A.x = temp;

        d = -d;
        T = 1-T;
    }

    if(d > 0.5)
    {
        A.x = A.x + 1;
        hue = (A.x + T * (B.x - A.x)) % 1;
    }

    if(d <= 0.5) hue = A.x + T * d;

    float sat = A.y + T * (B.y - A.y);
    float val = A.z + T * (B.z - A.z);
    float alpha = A.w + t * (B.w - A.w);

    float3 rgb = HSV2RGB(float3(hue,sat,val));

    OUT = float4(rgb, alpha);
}


/// UV Distortion
void SineDistortUV_float(float2 UV, float Amount, out float2 UV_Distorted)
{
    float time = _Time.y;
    UV.y += Amount * 0.01 * (sin(UV.x * 3.5 + time * 0.35) + sin(UV.x * 4.8 + time * 1.05) + sin(UV.x * 7.3 + time * 0.45)) / 3.0;
    UV.x += Amount * 0.12 * (sin(UV.y * 4.0 + time * 0.50) + sin(UV.y * 6.8 + time * 0.75) + sin(UV.y * 11.3 + time * 0.2)) / 3.0;
    UV.y += Amount * 0.12 * (sin(UV.x * 4.2 + time * 0.64) + sin(UV.x * 6.3 + time * 1.65) + sin(UV.x * 8.2 + time * 0.45)) / 3.0;
    UV_Distorted = UV;
}

void VortexDistortUV_float(float2 UV, float Amount, float Radius, out float2 UV_Distorted)
{
    float2 center = float2(0.5, 0.5);
    float2 delta = UV - center;
    float distance = length(delta);
    float angle = atan2(delta.y, delta.x);

    angle += (1.0 - smoothstep(0.0, Radius, distance)) * Amount * _Time.y;

    UV_Distorted = center + float2(cos(angle), sin(angle)) * distance;
}

void GridDistortUV_float(float2 UV, float Amount, float GridSize, out float2 UV_Distorted)
{
    float2 grid = frac(UV * GridSize) - 0.5;
    float2 sineWave = sin(grid * 3.14159 + _Time.y);
    UV_Distorted = UV + sineWave * Amount / GridSize;
}
