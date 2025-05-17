//////////////////////////////////////////
//
// NOTE: This is *not* a valid shader file
//
///////////////////////////////////////////
Shader "Hidden/GlowConeTap"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,0)
        _MainTex ("", 2D) = "white" {}
    }
    
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        
        Pass
        {
            Name "GlowConeTap"
            Tags { "LightMode"="UniversalForward" }
            
            ZTest Always
            ZWrite Off
            Cull Off
            
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
                float4 uv0 : TEXCOORD0;
                float4 uv1 : TEXCOORD1;
            };
            
            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float4 _MainTex_TexelSize;
                float4 _BlurOffsets;
            CBUFFER_END
            
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                
                // Calculate blur offsets
                float2 texelSize = _MainTex_TexelSize.xy;
                float2 blurOffset = texelSize * _BlurOffsets.xy;
                
                // Calculate UV coordinates for 4 samples
                float2 uv = IN.uv;
                float2 uv1 = uv - blurOffset;
                float2 uv2 = uv + float2(-blurOffset.x, blurOffset.y);
                float2 uv3 = uv + float2(blurOffset.x, -blurOffset.y);
                float2 uv4 = uv + blurOffset;
                
                OUT.uv0.xy = uv1;
                OUT.uv0.zw = uv2;
                OUT.uv1.xy = uv3;
                OUT.uv1.zw = uv4;
                
                return OUT;
            }
            
            float4 frag(Varyings IN) : SV_Target
            {
                // Sample texture at 4 positions
                float4 color = 0;
                color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv0.xy);
                color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv0.zw);
                color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv1.xy);
                color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv1.zw);
                
                // Apply color and alpha
                color.rgb *= _Color.rgb;
                color *= _Color.a;
                
                return color;
            }
            ENDHLSL
        }
    }
    Fallback Off
}