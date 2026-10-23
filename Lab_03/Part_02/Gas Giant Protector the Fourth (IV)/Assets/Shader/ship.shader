HLSLINCLUDE

#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_SCREEN
#pragma multi_compile_fragment _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
#pragma shader_feature_local_fragment _ENVIRONMENTREFLECTIONS_OFF
#pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
#pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
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
    float4 uv : TEXCOORD0;
    float3 normalWS : NORMAL0;
    float3 view : TEXCOORD1;
    float4 shadow : TEXCOORD2;
    float3 positionWS : TEXCOORD3;
    float3 positionOS : TEXCOORD4;
    float3x3 tangentToWorld : TEXCOORD5;
    float color : COLOR0;
};

TEXTURE2D(_BaseMap);
SAMPLER(sampler_BaseMap);
TEXTURE2D(_AmbientOcc);
SAMPLER(sampler_AmbientOcc);
TEXTURE2D(_NormalMap);
SAMPLER(sampler_NormalMap);
TEXTURE2D(_SpecularMap);
SAMPLER(sampler_SpecularMap);
sampler3D _NoiseMap;

CBUFFER_START(UnityPerMaterial)
    float4 _BaseColor;
    float4 _SpecColor;
    float _SpecPower;
    float _HotSpot;
    float _Flake;
    float4 _BaseMap_ST;
    float4 _NormalMap_ST;
    float4 _DiffuseMin;
    float4 _DiffuseMax;
    float4 _EnvmapMin;
    float4 _EnvmapMax;
    float4 _SpecularMin;
    float4 _SpecularMax;
CBUFFER_END

Varyings vert(Attributes IN)
{
    Varyings OUT;
    OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
    OUT.uv.xy = TRANSFORM_TEX(IN.uv, _BaseMap);
    OUT.uv.zw = TRANSFORM_TEX(IN.uv, _NormalMap);
    OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);

    float3 worldPos = TransformObjectToWorld(IN.positionOS.xyz);
    OUT.positionWS = worldPos;
    OUT.positionOS = IN.positionOS.xyz;

    OUT.view = GetCameraPositionWS() - worldPos;

    VertexPositionInputs positions = GetVertexPositionInputs(IN.positionOS.xyz);
    OUT.shadow = GetShadowCoord(positions);

    OUT.color = saturate(2 * IN.color.x);

    float3 tangentWS = TransformObjectToWorldNormal(IN.tangent);

    OUT.tangentToWorld = CreateTangentToWorld(OUT.normalWS, tangentWS.xyz, IN.tangent.w > 0.0 ? 1.0 : -1.0);

    return OUT;
}

float4 frag(Varyings IN) : SV_Target
{
    float4 color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv.xy) * _BaseColor;
    float4 ambientOcc = SAMPLE_TEXTURE2D(_AmbientOcc, sampler_AmbientOcc, IN.uv.zw); // normal map ambient occlusion
    float4 specMap = SAMPLE_TEXTURE2D(_SpecularMap, sampler_SpecularMap, IN.uv.xy);
    float3 normal = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, IN.uv.zw));

    normal = TransformTangentToWorld(normal, IN.tangentToWorld);
    normal = normalize(normal);

    float flakeFalloff = 1.0f / (1.0f + length(IN.view * 0.35f));

    float3 flakeNormal = normalize(normal + (TransformObjectToWorldNormal(tex3Dbias(_NoiseMap, float4(IN.positionOS.xyz * 10, -3))) * _Flake * flakeFalloff));

    //return float4((1 + normal) / 2, 1);

    Light light = GetMainLight();

    float3 shLight = SampleSH(normal);

    float3 diffuse = saturate(0.1 + dot(normal, normalize(light.direction)));
    float RdotV = saturate((dot(reflect(normalize(-light.direction), normal), normalize(IN.view)) + 1) * 0.5);
    float RdotVFlake = saturate((dot(reflect(normalize(-light.direction), flakeNormal), normalize(IN.view)) + 1) * 0.5);
    float NdotV = max(0, dot(normal, normalize(IN.view)));

    float3 envmap = GlossyEnvironmentReflection(normalize(reflect(-IN.view, normal)), IN.positionWS.xyz, 0.0f, 1.0f, float3(0, 0, 1)).xyz;

    envmap *= lerp(_EnvmapMin, _EnvmapMax, NdotV);

    float3 specular = pow(RdotVFlake, _SpecPower) * _SpecColor * lerp(_SpecularMin, _SpecularMax, NdotV) * 2;
    specular += pow(RdotV, _SpecPower * 80) * _HotSpot * 5; // hotspot
    specular *= specMap;

    float shadow = lerp(MainLightRealtimeShadow(IN.shadow), 1.0, GetMainLightShadowFade(IN.positionWS)).x;

    float4 extinction = lerp(_DiffuseMin, _DiffuseMax, NdotV);

    color *= extinction; // extinction

    float4 result = color;
    result.xyz += specular;// specular
    result.xyz *= diffuse; // diffuse
    result.xyz *= light.color; // tint by sun color
    result.xyz *= shadow; // shadow
    result.xyz += shLight * color; // ambient
    result.xyz += extinction * (shLight + (diffuse * 0.5 * light.color * shadow)) * (1 - pow(NdotV, 0.5)) * 0.25 * specMap; // rim light
    result.xyz *= IN.color * ambientOcc; // ambient occlusion
    result.xyz += envmap * IN.color; // reflections

    return result;
}

struct Attributes_lowlod
{
    float4 positionOS : POSITION;
    float2 uv : TEXCOORD0;
    float4 normalOS : NORMAL0;
    float4 color : COLOR0;
};

struct Varyings_lowlod
{
    float4 positionHCS : SV_POSITION;
    float4 uv : TEXCOORD0;
    float3 positionWS : TEXCOORD1;
    float3 envmapCoord : TEXCOORD2;
    float4 diffuse : COLOR0;
    float3 specular : COLOR1;
    float3 envmap : COLOR2;
};

Varyings_lowlod vert_lowlod(Attributes_lowlod IN)
{
    Varyings_lowlod OUT;
    OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
    OUT.uv.xy = TRANSFORM_TEX(IN.uv, _BaseMap);
    OUT.uv.zw = TRANSFORM_TEX(IN.uv, _NormalMap);
    float3 normalWS = TransformObjectToWorldNormal(IN.normalOS);

    float3 worldPos = TransformObjectToWorld(IN.positionOS.xyz);
    OUT.positionWS = worldPos;

    float3 view = GetCameraPositionWS() - worldPos;

    float radiosity = saturate(2 * IN.color.x);
    
    Light light = GetMainLight();

    float NdotV = max(0, dot(normalWS, normalize(view)));
    float RdotV = saturate((dot(reflect(normalize(-light.direction), normalWS), normalize(view)) + 1) * 0.5);

    float3 shLight = SampleSH(normalWS);

    float3 diffuse = saturate(0.1 + dot(normalWS, normalize(light.direction)));

    float3 extinction = lerp(_DiffuseMin, _DiffuseMax, NdotV);

    OUT.diffuse.xyz = extinction * diffuse * light.color;
    OUT.diffuse.xyz += shLight;
    OUT.diffuse.xyz *= radiosity;
    OUT.diffuse.w = radiosity;

    OUT.specular = pow(RdotV, _SpecPower) * _SpecColor * lerp(_SpecularMin, _SpecularMax, NdotV) * 2 * light.color * diffuse;
    OUT.specular.xyz += extinction * (shLight + (diffuse * 0.5 * light.color)) * (1 - pow(NdotV, 0.5)) * 0.25;

    OUT.envmap = radiosity * lerp(_EnvmapMin, _EnvmapMax, NdotV);

    OUT.envmapCoord = normalize(reflect(-view, normalWS));

    return OUT;
}

float4 frag_lowlod(Varyings_lowlod IN) : SV_Target
{
    float3 envmap = GlossyEnvironmentReflection(normalize(IN.envmapCoord), IN.positionWS.xyz, 0.0f, 1.0f, float3(0, 0, 1));
    float4 ambientOcc = SAMPLE_TEXTURE2D(_AmbientOcc, sampler_AmbientOcc, IN.uv.zw); // normal map ambient occlusion
    float4 specMap = SAMPLE_TEXTURE2D(_SpecularMap, sampler_SpecularMap, IN.uv.xy);
    float4 color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv.xy) * _BaseColor;

    float4 result;

    result.xyz = color;
    result.xyz *= IN.diffuse.xyz * ambientOcc;
    result.xyz += IN.specular.xyz * ambientOcc * specMap;
    result.xyz += IN.envmap.xyz * envmap;
    result.w = color.w;

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

Shader "Custom/ship"
{
    Properties
    {
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        _SpecColor("Specular Color", Color) = (1, 1, 1, 1)
        _SpecPower("Specular Power", Float) = 1
        _HotSpot("Specular Hot Spot", Float) = 0.1
        [MainTexture] _BaseMap("Base Map", 2D) = "white" {}
        [Normal] _NormalMap("Normal Map", 2D) = "bump" {}
        _AmbientOcc("Ambient Occlusion Map", 2D) = "white" {}
        _SpecularMap("Specular Map", 2D) = "white" {}
        _NoiseMap("Noise Map", 3D) = "white" {}
        _Flake("Flake intensity", Float) = 0
        [ColorUsage(true, true)] _DiffuseMin("Diffuse min", Color) = (1, 1, 1, 1)
        [ColorUsage(true, true)] _DiffuseMax("Diffuse max", Color) = (1, 1, 1, 1)
        [ColorUsage(true, true)] _EnvmapMin("Envmap min", Color) = (0, 0, 0, 1)
        [ColorUsage(true, true)] _EnvmapMax("Envmap max", Color) = (0, 0, 0, 1)
        [ColorUsage(true, true)] _SpecularMin("Specular min", Color) = (1, 1, 1, 1)
        [ColorUsage(true, true)] _SpecularMax("Specular max", Color) = (1, 1, 1, 1)
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            HLSLPROGRAM
            
            #pragma multi_compile _ _LOWLOD

            #pragma vertex v
            #pragma fragment f

            #ifdef _LOWLOD

            Varyings_lowlod v(Attributes_lowlod IN)
            {
                return vert_lowlod(IN);
            }
            
            float4 f(Varyings_lowlod IN) : SV_Target
            {
                return frag_lowlod(IN);
            }

            #else

            Varyings v(Attributes IN)
            {
                return vert(IN);
            }
            
            float4 f(Varyings IN) : SV_Target
            {
                return frag(IN);
            }

            #endif

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
