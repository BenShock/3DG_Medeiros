HLSLINCLUDE

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

struct Attributes
{
    float4 positionOS : POSITION;
    float4 normalOS : NORMAL0;
    float4 color : COLOR0;
};

struct Varyings
{
    float4 positionHCS : SV_POSITION;
    float3 normalWS : NORMAL0;
    float3 view : TEXCOORD0;
    float3 positionWS : TEXCOORD1;
    float4 color : COLOR0;
};

uniform float4 PlayerPos;

CBUFFER_START(UnityPerMaterial)
    float4 _BaseColor;
CBUFFER_END

Varyings vert(Attributes IN)
{
    Varyings OUT;
    OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
    OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);

    float3 worldPos = TransformObjectToWorld(IN.positionOS.xyz);

    OUT.view = GetCameraPositionWS() - worldPos;
    OUT.positionWS = worldPos;

    OUT.color = IN.color;
    return OUT;
}

float4 frag(Varyings IN) : SV_Target
{
    float4 color = _BaseColor;

    float4 result;
    result.xyz = pow(1 - dot(normalize(IN.normalWS), normalize(IN.view)), 3); // rim light
    result.xyz += pow(1/(length(PlayerPos - IN.positionWS)), 2); // contact light (red)
    result.xyz += pow(1/length(PlayerPos - IN.positionWS), 32) / 2048; // contact light (bright)
    result.xyz *= _BaseColor.xyz * _BaseColor.w; // tinting
    result.xyz += pow(1/length(PlayerPos - IN.positionWS), 4) * 0.25; // contact light (white)
    result.xyz *= IN.color.xyz * IN.color.w; // fading

    result.w = 1; // nuke alpha cuz we don't need it

    return result;
}

ENDHLSL

Shader "Custom/arena border"
{
    Properties
    {
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
    }

    SubShader
    {
        Tags { "Queue" = "Transparent" "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            ZWrite Off
            Blend One One
            Cull Off

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            ENDHLSL
        }
    }
}
