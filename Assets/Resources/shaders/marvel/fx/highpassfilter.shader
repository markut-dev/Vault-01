Shader "HighPassFilter"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _Sharpness ("Threshold", Float) = 8
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" }
        Pass
        {
            Name "HighPassFilter"
            Tags { "LightMode" = "UniversalForward" }
            ZTest Always
            ZWrite Off
            Cull Off
            Blend One Zero

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float _Sharpness;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                return OUT;
            }

            float luminancia(float3 color) {
                return dot(color, float3(0.2126, 0.7152, 0.0722));
            }

            float4 frag(Varyings IN) : SV_Target
            {
                float2 texelSize = 1.0 / float2(_ScreenParams.x, _ScreenParams.y);
                float3 sum = 0;
                float3 center = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb;
                float3 n[8];
                n[0] = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv + texelSize * float2(-1, -1)).rgb;
                n[1] = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv + texelSize * float2( 0, -1)).rgb;
                n[2] = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv + texelSize * float2( 1, -1)).rgb;
                n[3] = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv + texelSize * float2(-1,  0)).rgb;
                n[4] = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv + texelSize * float2( 1,  0)).rgb;
                n[5] = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv + texelSize * float2(-1,  1)).rgb;
                n[6] = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv + texelSize * float2( 0,  1)).rgb;
                n[7] = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv + texelSize * float2( 1,  1)).rgb;
                for (int i = 0; i < 8; i++) sum += n[i];
                float3 highpass = center * _Sharpness - sum;
                float luma = luminancia(highpass);
                return float4(luma, luma, luma, 1);
            }
            ENDHLSL
        }
    }
    Fallback "Universal Render Pipeline/Unlit"
}