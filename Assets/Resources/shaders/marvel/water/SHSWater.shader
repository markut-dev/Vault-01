Shader "Marvel/FX/Water Surface"
{
    Properties
    {
        _Color ("Main Color", Color) = (1,1,1,1)
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _WaveColor ("Wave Color", Color) = (1,1,1,1)
        _ThresholdValue ("Wave threshold value", Float) = 0.65
        _ThresholdRange ("Wave threshold range", Float) = 0.1
        _WaveTex ("Wave Texture (Private)", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" "Queue" = "Transparent-1" }
        Pass
        {
            Name "WaterSurface"
            Tags { "LightMode" = "UniversalForward" }
            ZWrite Off
            Cull Off
            Blend SrcAlpha OneMinusSrcAlpha

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
                float2 waveUV : TEXCOORD1;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_WaveTex);
            SAMPLER(sampler_WaveTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float4 _MainTex_ST;
                float4 _WaveColor;
                float _ThresholdValue;
                float _ThresholdRange;
                float4 _WaveTex_ST;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                OUT.waveUV = TRANSFORM_TEX(IN.uv, _WaveTex);
                return OUT;
            }

            float4 frag(Varyings IN) : SV_Target
            {
                float4 baseCol = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv) * _Color;
                float wave = SAMPLE_TEXTURE2D(_WaveTex, sampler_WaveTex, IN.waveUV).r;
                float t = abs(wave - _ThresholdValue) / max(_ThresholdRange, 1e-5);
                t = saturate(1.0 - t);
                float3 finalColor = lerp(baseCol.rgb, _WaveColor.rgb, t);
                float alpha = baseCol.a;
                return float4(finalColor, alpha);
            }
            ENDHLSL
        }
    }
    Fallback "Universal Render Pipeline/Unlit"
}