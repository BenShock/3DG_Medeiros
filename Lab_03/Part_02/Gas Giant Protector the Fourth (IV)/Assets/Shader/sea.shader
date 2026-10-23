HLSLINCLUDE

#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_SCREEN
#pragma multi_compile_fragment _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
#pragma shader_feature_local_fragment _ENVIRONMENTREFLECTIONS_OFF
#pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
#pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
#pragma multi_compile _ _LOWLOD
#if (UNITY_VERSION >= 60010000)
    #pragma multi_compile _ _CLUSTER_LIGHT_LOOP
    #pragma multi_compile_fragment _ _REFLECTION_PROBE_ATLAS
#endif

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

struct Attributes
{
    float4 positionOS : POSITION;
    float2 uv : TEXCOORD0;
    float4 normalOS : NORMAL0;
    float4 color : COLOR0;
    float4 tangent : TANGENT0;
};

struct Varyings
{
    float4 positionHCS : SV_POSITION;
    float2 uv : TEXCOORD0;
    float3 normalWS : NORMAL0;
    float3 view : TEXCOORD1;
    float4 screenUV : TEXCOORD2;
    float3 positionWS : TEXCOORD3;
    float4 shadow : TEXCOORD4;
    float3x3 tangentToWorld : TEXCOORD5;
};

sampler2D gReflectionTexture;
TEXTURE2D(_NormalMap);
SAMPLER(sampler_NormalMap);

CBUFFER_START(UnityPerMaterial)
    float4 _NormalMap_ST;
CBUFFER_END

Varyings vert(Attributes IN)
{
    Varyings OUT;
    OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
    OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);

    float3 worldPos = TransformObjectToWorld(IN.positionOS.xyz);
    OUT.positionWS = worldPos;
    
    OUT.uv = TRANSFORM_TEX((worldPos.xz * 0.1f), _NormalMap);

    OUT.view = GetCameraPositionWS() - worldPos;

    VertexPositionInputs positions = GetVertexPositionInputs(IN.positionOS.xyz);
    OUT.shadow = GetShadowCoord(positions);

    float3 tangentWS = TransformObjectToWorldNormal(IN.tangent);

    OUT.tangentToWorld = CreateTangentToWorld(OUT.normalWS, tangentWS.xyz, IN.tangent.w > 0.0 ? 1.0 : -1.0);

    OUT.screenUV = OUT.positionHCS;
    OUT.screenUV.y = -OUT.screenUV.y;
    OUT.screenUV.xy += OUT.screenUV.w;
    OUT.screenUV.xy *= 0.5;

    return OUT;
}

float4 frag(Varyings IN) : SV_Target
{
    float3 normal1 = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, IN.uv.xy + (_Time.x * float2(-0, 6))));
    float3 normal2 = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, (IN.uv.xy + (_Time.x * float2(0, 2))) * 0.5));

    float3 normal = normalize(lerp(float3(0, 0, 1), normal1 + normal2, 0.5f));

    normal = TransformTangentToWorld(normal, IN.tangentToWorld);
    normal = normalize(normal);

    Light light = GetMainLight();

    float RdotV = saturate((dot(reflect(normalize(-light.direction), normal), normalize(IN.view)) + 1) * 0.5);
    float NdotV = max(0, dot(normal, normalize(IN.view)));
    
    float3 diffuse = saturate(0.1 + dot(normal, normalize(light.direction)));

    // this formula is stupid but looks nice and i sorely apologize to whoever has to look at this code
    float3 specular = ((pow(RdotV, 2) * 0.15) + (pow(RdotV, 11) * 0.4) + (pow(RdotV, 160) * 4) + (pow(RdotV, 320) * 16) + (pow(RdotV, 500) * 64)) * light.color * 0.1;

    float shadow = lerp(MainLightRealtimeShadow(IN.shadow), 1.0, GetMainLightShadowFade(IN.positionWS)).x;

    float2 screenSpaceNormalOffset = mul((float3x3)UNITY_MATRIX_V, normal);

    screenSpaceNormalOffset *= NdotV * 3;

    //#define _LOWLOD

    #ifdef _LOWLOD
    float3 skyCapColor = float3(0.12, 0.20, 0.41);
    float3 skyHorizonColor = float3(10.93, 15.87, 20.93) * 0.2;
    float3 reflectionSample = GlossyEnvironmentReflection(normalize(reflect(-IN.view, normal)), IN.positionWS.xyz, 0.0f, 1.0f, float3(0, 0, 1)).xyz;
    #else
    float3 reflectionSample = tex2Dproj(gReflectionTexture, IN.screenUV + float4(screenSpaceNormalOffset, 0, 0));
    #endif

    reflectionSample *= saturate(0.1 + pow(1-NdotV, 1));

    float fog = saturate(length(IN.view) / 5000.0f);

    float3 foam = pow((1-max(0, dot(normal, float3(0,1,0.5)))), 2) + (pow((max(0, dot(normal, float3(0,1,0)))), 600) * 0.01);

    float4 result;
    result.xyz = specular + (foam * float3(0.8, 0.9, 1.0) * diffuse);// specular
    result.xyz *= light.color; // tint by sun color
    result.xyz *= shadow; // shadow
    result.xyz += reflectionSample * (1-foam); // reflection
    result.xyz += (foam * float3(0.6, 0.7, 0.8)) * (1 + diffuse) * 0.5f; // foam ambient
    result.xyz = lerp(result.xyz, pow(float3(0.6235294, 0.7411765, 0.8745099), 2) * 5.0f, fog);

    result.w = saturate(1-pow(length(IN.view) / 3000.0f, 3)); // abuse alpha so it blends into sky better

    return result;
}

ENDHLSL

Shader "Custom/sea"
{
    Properties
    {
        [Normal] _NormalMap("Normal Map", 2D) = "bump" {}
    }

    SubShader
    {
        Tags { "Queue"="Transparent-50" "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDHLSL
        }
    }
}
