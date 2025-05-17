Shader "Hidden/AO Gaussian"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _Weights ("Weights", Vector) = (0.2270270270, 0.3162162162, 0.0702702703, 0.0081081081)
    }
    
    SubShader
    {
        Tags { "Queue"="Overlay" "RenderType"="Transparent" }
        
        Pass
        {
            Name "Gaussian"
            Tags { "LightMode"="UniversalForward" }
            
            ZTest Always
            ZWrite Off
            Cull Off
            Blend SrcAlpha OneMinusSrcAlpha
            
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
            };
            
            CBUFFER_START(UnityPerMaterial)
                float4 _Weights;
            CBUFFER_END
            
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _MainTex_TexelSize;
            
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.uv;
                return OUT;
            }
            
            float4 frag(Varyings IN) : SV_Target
            {
                float2 texelSize = _MainTex_TexelSize.xy;
                float4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv) * _Weights.x;
                
                // Horizontal blur
                for (int i = 1; i < 4; i++)
                {
                    float2 offset = float2(texelSize.x * i, 0.0);
                    color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv + offset) * _Weights[i];
                    color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv - offset) * _Weights[i];
                }
                
                return color;
            }
            ENDHLSL
        }
    }
    Fallback Off
}