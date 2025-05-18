Shader "HighPassAdd"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _AddTex ("Add (RGB)", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" }
        Pass
        {
            Name "HighPassAdd"
            Tags { "LightMode" = "UniversalForward" }
            ZTest Always
            ZWrite Off
            Cull Off
            Blend One One

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
            TEXTURE2D(_AddTex);
            SAMPLER(sampler_AddTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _AddTex_ST;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                return OUT;
            }

            float4 frag(Varyings IN) : SV_Target
            {
                float4 col1 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
                float4 col2 = SAMPLE_TEXTURE2D(_AddTex, sampler_AddTex, IN.uv);
                return col1 + col2;
            }
            ENDHLSL
        }
    }
    Fallback "Universal Render Pipeline/Unlit"
}