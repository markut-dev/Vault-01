Shader "Marvel/FX/Water/Difference"
{
    Properties
    {
        _MainTex ("Current intersection", 2D) = "white" {}
        _OldTex ("Last intersection", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" }
        Pass
        {
            Name "Difference"
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
            TEXTURE2D(_OldTex);
            SAMPLER(sampler_OldTex);

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.uv;
                return OUT;
            }

            float4 frag(Varyings IN) : SV_Target
            {
                float current = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).r;
                float old = SAMPLE_TEXTURE2D(_OldTex, sampler_OldTex, IN.uv).r;
                float diff = (current - old) * 0.5 + 0.5;
                return float4(diff, 0, 0, 1);
            }
            ENDHLSL
        }
    }
    Fallback Off
}