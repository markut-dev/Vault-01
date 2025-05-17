//////////////////////////////////////////
//
// NOTE: This is *not* a valid shader file
//
///////////////////////////////////////////
Shader "Hidden/VignettingShader"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _VignetteTex ("Vignette Texture", 2D) = "white" {}
        _VignetteColor ("Vignette Color", Color) = (0,0,0,1)
        _VignetteIntensity ("Vignette Intensity", Range(0,1)) = 0.5
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
            TEXTURE2D(_VignetteTex);
            SAMPLER(sampler_VignetteTex);
            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _VignetteColor;
                float _VignetteIntensity;
            CBUFFER_END
            Varyings vert(Attributes IN) {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                return OUT;
            }
            float4 frag(Varyings IN) : SV_Target {
                float4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
                float4 vignette = SAMPLE_TEXTURE2D(_VignetteTex, sampler_VignetteTex, IN.uv);
                float3 vignetteCol = vignette.rgb * _VignetteColor.rgb * _VignetteIntensity;
                return float4(tex.rgb * (1 - vignetteCol), tex.a);
            }
            ENDHLSL
        }
    }
    Fallback "Universal Render Pipeline/Unlit"
}