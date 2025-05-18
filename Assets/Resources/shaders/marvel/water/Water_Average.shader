Shader "Marvel/FX/Water/Average"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _Horizontal ("Horizontal (Private)", Float) = 1
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" }
        Pass
        {
            Name "Average"
            Tags { "LightMode" = "UniversalForward" }
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
                float4 _MainTex_TexelSize;
                float _Horizontal;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.uv;
                return OUT;
            }

            float4 frag(Varyings IN) : SV_Target
            {
                float2 offset = _Horizontal > 0.5 ? float2(_MainTex_TexelSize.x, 0) : float2(0, _MainTex_TexelSize.y);
                float sum = 0.0;
                sum += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv - 3.0 * offset).r;
                sum += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv - 2.0 * offset).r;
                sum += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv - 1.0 * offset).r;
                sum += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).r;
                sum += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv + 1.0 * offset).r;
                sum += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv + 2.0 * offset).r;
                sum += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv + 3.0 * offset).r;
                return float4(sum / 7.5, 0, 0, 1);
            }
            ENDHLSL
        }
    }
    Fallback Off
}