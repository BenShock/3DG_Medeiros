Shader "Custom/backdrop"
{
    Properties
    {
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        [MainTexture] _BaseMap("Base Map", 2D) = "white" {}
        _Layer2("2nd layer", 2D) = "white" {}
        LayerSpeeds("Layer Speeds", Vector) = (0, 0, 0, 0)
    }

    SubShader
    {
        Tags { "Queue" = "Background-1000" "RenderType" = "Background" "RenderPipeline" = "UniversalPipeline" "PreviewType"="Skybox" }

        ZWrite Off

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
            };

            TEXTURE2D(_BaseMap);
            TEXTURE2D(_Layer2);
            SAMPLER(sampler_BaseMap);
            SAMPLER(sampler_Layer2);

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                float4 _BaseMap_ST;
                float4 _Layer2_ST;
            CBUFFER_END

            float4 LayerSpeeds;

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = IN.positionOS;//TransformWViewToHClip(IN.positionOS.xyz);
                OUT.positionHCS.x *= 2;
                OUT.positionHCS.y *= -2;
                //GetViewToHClipMatrix()[0][0];
                OUT.positionHCS.z = 0;
                OUT.positionHCS.w = 1;
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                OUT.uv.x *= 2/(GetViewToHClipMatrix()[0][0]);
                
                OUT.uv2 = TRANSFORM_TEX(IN.uv, _Layer2);
                OUT.uv2.x *= 2/(GetViewToHClipMatrix()[0][0]);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half4 color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv + (_Time.y * -LayerSpeeds.xy)) * _BaseColor;
                color.xyz += SAMPLE_TEXTURE2D(_Layer2, sampler_Layer2, IN.uv2 + (_Time.y * -LayerSpeeds.zw) ) * _BaseColor;
                return color * 4;
            }
            ENDHLSL
        }
    }
}
