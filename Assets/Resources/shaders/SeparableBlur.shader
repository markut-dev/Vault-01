//////////////////////////////////////////
//
// NOTE: This is *not* a valid shader file
//
///////////////////////////////////////////
Shader "Hidden/SeparableBlur"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _BlurAmount ("Blur Amount", Range(0,10)) = 1
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "Queue" = "Geometry" }
        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
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
                float _BlurAmount;
            CBUFFER_END
            Varyings vert(Attributes IN) {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                return OUT;
            }
            float4 frag(Varyings IN) : SV_Target {
                float4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
                float blur = _BlurAmount * 0.01;
                float4 blurTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv + float2(blur, 0));
                blurTex += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv - float2(blur, 0));
                blurTex += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv + float2(0, blur));
                blurTex += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv - float2(0, blur));
                return blurTex * 0.25;
            }
            ENDHLSL
        }
    }
    Fallback "Universal Render Pipeline/Unlit"
}