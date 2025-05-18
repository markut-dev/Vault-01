Shader "Marvel/FX/Water/Speed Update"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _HeightTex ("Height (Private)", 2D) = "white" {}
        _SmoothTex ("Smoothed (Private)", 2D) = "white" {}
        _ImpulseTex ("Impulse (Private)", 2D) = "white" {}
        _AverageTex ("Average (Private)", 2D) = "white" {}
        _Dampening ("Dampening (Private)", Float) = 0.99
        _DeltaTime ("Delta Time (Private)", Float) = 1
        _GravityPressure ("Gravity Pressure (Private)", Float) = 0.2
        _Friction ("Friction (Private)", Float) = 0.99
        _Persistence ("Persistence (Private)", Float) = 30
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" }
        Pass
        {
            Name "SpeedUpdate"
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
            TEXTURE2D(_HeightTex);
            SAMPLER(sampler_HeightTex);
            TEXTURE2D(_SmoothTex);
            SAMPLER(sampler_SmoothTex);
            TEXTURE2D(_ImpulseTex);
            SAMPLER(sampler_ImpulseTex);
            TEXTURE2D(_AverageTex);
            SAMPLER(sampler_AverageTex);

            CBUFFER_START(UnityPerMaterial)
                float _Dampening;
                float _DeltaTime;
                float _GravityPressure;
                float _Friction;
                float _Persistence;
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
                float baseVal = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).r;
                float height = SAMPLE_TEXTURE2D(_HeightTex, sampler_HeightTex, IN.uv).r;
                float smooth = SAMPLE_TEXTURE2D(_SmoothTex, sampler_SmoothTex, IN.uv).r;
                float impulse = SAMPLE_TEXTURE2D(_ImpulseTex, sampler_ImpulseTex, IN.uv).r;
                float average = SAMPLE_TEXTURE2D(_AverageTex, sampler_AverageTex, IN.uv).r;
                float v = (height + impulse + smooth + average - baseVal) * _GravityPressure;
                v = v * _Dampening * _Friction + baseVal * _Persistence * _DeltaTime;
                return float4(v, 0, 0, 1);
            }
            ENDHLSL
        }
    }
    Fallback Off
}