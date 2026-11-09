Shader "Custom/Per_Fragment_Shader"
{
    Properties
    {
        _Color ("Diffuse Material Color", Color) = (1,1,1,1)
        _SpecColor ("Specular Material Color", Color) = (1,1,1,1)
        _Shininess ("Shininess", Float) = 10
        _MainTex ("Texture Image", 2D) = "white" {}
    }
    SubShader
    {
        Pass {
            Tags { "LightMode"="ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            uniform sampler2D _MainTex;

            float4 _LightColor0;
            float4 _Color;
            float4 _SpecColor;
            float _Shininess;

            struct vertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
            };

            struct vertexOutput {
                float4 pos : SV_POSITION;
                float4 col : COLOR;
                float4 tex : TEXCOORD0;
            };

            vertexOutput vert(vertexInput input)
            {
                vertexOutput output;

                output.tex = input.texcoord;

                float4x4 modelMatrix = unity_ObjectToWorld;
                float4x4 modelMatrixInverse = unity_WorldToObject;

                float3 normalDirection = normalize(mul(float4(input.normal,0.0), modelMatrixInverse).xyz);
                float3 viewDirection = normalize(_WorldSpaceCameraPos - mul(modelMatrix, input.vertex).xyz);

                float3 lightDirection;
                float attenuation;

                if(0.0 == _WorldSpaceLightPos0.w)
                {
                    attenuation = 1.0;
                    lightDirection = normalize(_WorldSpaceLightPos0.xyz);
                }
                else
                {
                    float3 vertexToLightSource = _WorldSpaceLightPos0.xyz - mul(modelMatrix, input.vertex).xyz;
                    float distance = length(vertexToLightSource);
                    attenuation = 1.0 / distance;
                    lightDirection = normalize(vertexToLightSource); 
                }

                float3 ambientLighting = UNITY_LIGHTMODEL_AMBIENT.rgb * _Color.rgb;
                
                float3 diffuseReflection = attenuation * _LightColor0.rgb * _Color.rgb * max(0.0, dot(normalDirection, lightDirection));
                
                float3 specularReflection;
                if(dot(normalDirection, lightDirection) < 0.0)
                {
                    specularReflection = float3(0.0,0.0,0.0);
                }
                else
                {
                    specularReflection = attenuation * _LightColor0.rgb * _SpecColor.rgb * pow(max(0.0, dot(reflect(-lightDirection, normalDirection), viewDirection)), _Shininess);
                }

                output.col = float4(ambientLighting + diffuseReflection + specularReflection, 1.0);
                output.pos = UnityObjectToClipPos(input.vertex);

                return output;
            }

            float4 frag(vertexOutput input) : COLOR
            {
                // return input.col;
                return tex2D(_MainTex, input.tex.xy);
            }
            ENDCG
        }

        Pass {
            Tags { "LightMode" = "ForwardAdd" }
            Blend One One

            CGPROGRAM
            #pragma vertex vert  
            #pragma fragment frag 
            #include "UnityCG.cginc"

            uniform sampler2D _MainTex;
            uniform float4 _MainTex_ST;


            float4 _LightColor0;
            float4 _Color;
            float4 _SpecColor;
            float _Shininess;

            struct vertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct vertexOutput {
                float4 pos : SV_POSITION;
                float4 col : COLOR;
            };

            vertexOutput vert(vertexInput input) 
            {
                vertexOutput output;
 
                float4x4 modelMatrix = unity_ObjectToWorld;
                float4x4 modelMatrixInverse = unity_WorldToObject;

                float3 normalDirection = normalize(mul(float4(input.normal, 0.0), modelMatrixInverse).xyz);
                float3 viewDirection = normalize(_WorldSpaceCameraPos - mul(modelMatrix, input.vertex).xyz);
                
                float3 lightDirection;
                float attenuation;

                if (0.0 == _WorldSpaceLightPos0.w) 
                {
                    attenuation = 1.0; 
                    lightDirection = normalize(_WorldSpaceLightPos0.xyz);
                } 
                else 
                {
                    float3 vertexToLightSource = _WorldSpaceLightPos0.xyz - mul(modelMatrix, input.vertex).xyz;
                    float distance = length(vertexToLightSource);
                    attenuation = 1.0 / distance; 
                    lightDirection = normalize(vertexToLightSource);
                }

                float3 diffuseReflection = attenuation * _LightColor0.rgb * _Color.rgb * max(0.0, dot(normalDirection, lightDirection));

                float3 specularReflection;
                if (dot(normalDirection, lightDirection) < 0.0) 
                {
                    specularReflection = float3(0.0, 0.0, 0.0); 
                }
                else 
                {
                    specularReflection = attenuation * _LightColor0.rgb * _SpecColor.rgb * pow(max(0.0, dot(reflect(-lightDirection, normalDirection), viewDirection)), _Shininess);
                }

                output.col = float4(diffuseReflection + specularReflection, 1.0);
                output.pos = UnityObjectToClipPos(input.vertex);
                return output;
             }
 
            float4 frag(vertexOutput input) : COLOR
            {
                return input.col;
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
}
