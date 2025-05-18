Shader "Marvel/Lightmap/Vertex Color - Transparent"
{
    Properties
    {
        _ColorFade ("Fade Color", Color) = (1,1,1,1)
        _ColorAmbient ("Ambient Color", Color) = (0,0,0,1)
        _LightMap ("Lightmap (RGB)", 2D) = "black" {}
    }
    SubShader
    {
        Tags { "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" "Queue" = "Transparent+10" }
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
                float2 uv1 : TEXCOORD0;
                float4 color : COLOR;
            };

            struct Varyings {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 color : TEXCOORD1;
            };

            TEXTURE2D(_LightMap);
            SAMPLER(sampler_LightMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _ColorFade;
                float4 _ColorAmbient;
                float4 _LightMap_ST;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv1, _LightMap);
                OUT.color = IN.color;
                return OUT;
            }

            float4 frag(Varyings IN) : SV_Target
            {
                float4 lightMap = SAMPLE_TEXTURE2D(_LightMap, sampler_LightMap, IN.uv);
                float3 baseColor = lightMap.rgb * IN.color.rgb;
                float3 finalColor = lerp(_ColorAmbient.rgb, baseColor, _ColorFade.a) * _ColorFade.rgb;
                return float4(finalColor, IN.color.a * _ColorFade.a);
            }
            ENDHLSL
        }
    }
    Fallback "Universal Render Pipeline/Unlit"
}