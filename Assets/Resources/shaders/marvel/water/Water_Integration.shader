Shader "Marvel/FX/Water/Integration"
{
    Properties
    {
        _MainTex ("Height (Private)", 2D) = "white" {}
        _SpeedTex ("Speed (Private)", 2D) = "white" {}
        _ImpulseTex ("Impulse (Private)", 2D) = "white" {}
        _Dampening ("_Dampening", Float) = 0.99
        _DeltaTime ("_DeltaTime", Float) = 1
        _Instability ("_Instability", Float) = 60
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" }
        Pass
        {
            Name "Integration"
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
            TEXTURE2D(_SpeedTex);
            SAMPLER(sampler_SpeedTex);

            CBUFFER_START(UnityPerMaterial)
                float _Dampening;
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
                float h = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).r;
                float s = SAMPLE_TEXTURE2D(_SpeedTex, sampler_SpeedTex, IN.uv).r;
                float v = (h + 2.0 * s - 1.0) * _Dampening;
                return float4(v * 0.5 + 0.5, 0, 0, 1);
            }
            ENDHLSL
        }
    }
    Fallback Off
}