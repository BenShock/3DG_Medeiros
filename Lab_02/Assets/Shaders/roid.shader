HLSLINCLUDE

#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_SCREEN
#pragma multi_compile_fragment _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

struct Attributes
{
    float4 positionOS : POSITION;
    float2 uv : TEXCOORD0;
    float4 normalOS : NORMAL0;
};

struct Varyings
{
    float4 positionHCS : SV_POSITION;
    float2 uv : TEXCOORD0;
    float3 normalWS : NORMAL0;
    float3 view : TEXCOORD1;
    float4 shadow : TEXCOORD2;
    float3 positionWS : TEXCOORD3;
};

TEXTURE2D(_BaseMap);
SAMPLER(sampler_BaseMap);

CBUFFER_START(UnityPerMaterial)
    float4 _BaseColor;
    float4 _BaseMap_ST;
CBUFFER_END

Varyings vert(Attributes IN)
{
    Varyings OUT;
    OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
    OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
    OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);

    float3 worldPos = TransformObjectToWorld(IN.positionOS.xyz);
    OUT.positionWS = worldPos;

    OUT.view = GetCameraPositionWS() - worldPos;

    VertexPositionInputs positions = GetVertexPositionInputs(IN.positionOS.xyz);
    OUT.shadow = GetShadowCoord(positions);
    return OUT;
}

float4 frag(Varyings IN) : SV_Target
{
    float4 color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv) * _BaseColor;

    Light light = GetMainLight();

    float3 shLight = SampleSH(IN.normalWS);
    float3 diffuse = max(0, dot(normalize(IN.normalWS), normalize(light.direction)));
    float3 specular = max(0, pow(saturate(dot(reflect(normalize(-light.direction), normalize(IN.normalWS)), normalize(IN.view))), 2)) * 0.025f;
    
    float shadow = lerp(MainLightRealtimeShadow(IN.shadow), 1.0, GetMainLightShadowFade(IN.positionWS)).x;

    float4 result = color;
    result.xyz += specular;// specular
    result.xyz *= diffuse; // diffuse
    result.xyz *= light.color; // tint by sun color
    result.xyz *= shadow; // shadow
    result.xyz += shLight * color; // ambient
    result.xyz += (shLight + (diffuse * 0.5 * light.color * shadow)) * (1 - max(0, dot(normalize(IN.normalWS), normalize(IN.view)))) * 0.25; // rim light

    return result;
}


struct VtoP_shadow
{
    float4 positionHCS : SV_POSITION;
};

VtoP_shadow shadowVS(Attributes IN)
{
    VtoP_shadow OUT;

    float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
    float3 normalWS = TransformObjectToWorldNormal(IN.normalOS);
    
    Light light = GetMainLight();

    OUT.positionHCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, light.direction));

    #if UNITY_REVERSED_Z
        OUT.positionHCS.z = min(OUT.positionHCS.z, OUT.positionHCS.w * UNITY_NEAR_CLIP_VALUE);
    #else
        OUT.positionHCS.z = max(OUT.positionHCS.z, OUT.positionHCS.w * UNITY_NEAR_CLIP_VALUE);
    #endif

    return OUT;
}

float4 shadowPS(VtoP_shadow IN) : SV_Target
{
    return 0;
}

ENDHLSL

Shader "Custom/roid"
{
    Properties
    {
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        [MainTexture] _BaseMap("Base Map", 2D) = "white" {}
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull Off
            
            HLSLPROGRAM

            #pragma vertex shadowVS
            #pragma fragment shadowPS
            ENDHLSL
        }
    }
}
