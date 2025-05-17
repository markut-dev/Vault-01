// Alejandro: Esto de aquí fué actualizado para URP.
// WARNING: Este shader no tiene soporte para tangentes inteligentes, depende 100% de que el modelo tenga tangente.
Shader "Chad/Chad Test"
{
    Properties
    {
        _Color ("Main Color", Color) = (1,1,1,1)
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _LightMap ("Lightmap (RGB) AO (A)", 2D) = "black" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        LOD 100

        Pass
        {
            Name "Unlit"
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
                float4 color : COLOR;
                float4 tangent : TANGENT;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
                float4 color : COLOR;
                float tangentMask : TEXCOORD2;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
            CBUFFER_END

            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
            TEXTURE2D(_LightMap); SAMPLER(sampler_LightMap);

            float4 _MainTex_ST;
            float4 _LightMap_ST;

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                OUT.uv2 = TRANSFORM_TEX(IN.uv2, _LightMap);
                OUT.color = IN.color * _Color;
                OUT.tangentMask = IN.tangent.x > 0.1 ? 1.0 : 0.0;
                return OUT;
            }

            float4 frag(Varyings IN) : SV_Target
            {
                float4 texColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
                float4 finalColor = lerp(texColor, IN.color, IN.tangentMask);
                float4 lightmap = SAMPLE_TEXTURE2D(_LightMap, sampler_LightMap, IN.uv2);
                return finalColor * lightmap;
            }
            ENDHLSL
        }
    }
    Fallback "Hidden/Shader Graph/FallbackError"
} 