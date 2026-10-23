Shader "Custom/RGB_Cube_Shader"
{
   SubShader { 
      Pass { 
         HLSLPROGRAM 
         
         #include "UnityCG.cginc"

         #pragma vertex vert // vert function is the vertex shader 
         #pragma fragment frag // frag function is the fragment shader
 
         struct vertexInput {
            float4 vertex : POSITION;
            float4 tangent : TANGENT;  
            float3 normal : NORMAL;
            float4 texcoord : TEXCOORD0;  
            float4 texcoord1 : TEXCOORD1; 
            float4 texcoord2 : TEXCOORD2;  
            float4 texcoord3 : TEXCOORD3; 
            fixed4 color : COLOR; 
         };
         struct vertexOutput {
            float4 pos : SV_POSITION;
            float4 col : TEXCOORD0;
         };
 
         vertexOutput vert(vertexInput input) 
         {
            vertexOutput output;
 
            output.pos = UnityObjectToClipPos(input.vertex);
            output.col = input.texcoord; // set the output color

            // other possibilities to play with:

            // output.col = input.vertex;
            // output.col = input.tangent;
            // output.col = float4(input.normal, 1.0);
            // output.col = input.texcoord;
            // output.col = input.texcoord1;
            // output.col = input.texcoord2;
            // output.col = input.texcoord3;
            // output.col = input.color;

            return output;
         }
 
         float4 frag(vertexOutput input) : COLOR 
         {
            return input.col; 
         }
 
         ENDHLSL
      }
   }
}
