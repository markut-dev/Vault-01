Shader "Marvel/Lightmap/Self-Illuminated-Tex - Transparent"
{
    Properties
    {
        _ColorFade ("Fade Color", Color) = (1,1,1,1)
        _ColorAmbient ("Ambient Color", Color) = (0,0,0,1)
        _Color ("Main Color", Color) = (1,1,1,1)
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _LightMap ("Lightmap (RGB) AO (A)", 2D) = "black" {}
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Transparent" "Queue" = "Transparent+10" }
        Pass
        {
            Name "ForwardLit"
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
                float2 uv2 : TEXCOORD1;
            };

            struct Varyings {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_LightMap);
            SAMPLER(sampler_LightMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _LightMap_ST;
                float4 _ColorFade;
                float4 _ColorAmbient;
                float4 _Color;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                OUT.uv2 = TRANSFORM_TEX(IN.uv2, _LightMap);
                return OUT;
            }

            float4 frag(Varyings IN) : SV_Target
            {
                float4 baseCol = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv) * _Color;
                float4 lightmap = SAMPLE_TEXTURE2D(_LightMap, sampler_LightMap, IN.uv2);
                float3 illum = baseCol.rgb * lightmap.rgb + _ColorFade.rgb;
                float alpha = baseCol.a * lightmap.a * _ColorFade.a;
                return float4(illum, alpha);
            }
            ENDHLSL
        }
    }
    Fallback "Universal Render Pipeline/Unlit"
}