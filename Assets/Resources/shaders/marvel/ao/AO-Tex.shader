Shader "Marvel/AO/Diffuse"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)
        _AOTex ("AO (RGB)", 2D) = "white" {}
        _AOPower ("AO Power", Range(0, 2)) = 1
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "Queue" = "Geometry" }
        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
            Cull Back

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normalOS : NORMAL;
            };

            struct Varyings {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_AOTex);
            SAMPLER(sampler_AOTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _AOTex_ST;
                float4 _Color;
                float _AOPower;
            CBUFFER_END

            Varyings vert(Attributes IN) {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                return OUT;
            }

            float4 frag(Varyings IN) : SV_Target {
                float4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
                float4 ao = SAMPLE_TEXTURE2D(_AOTex, sampler_AOTex, IN.uv);
                
                float3 normalWS = normalize(IN.normalWS);
                Light mainLight = GetMainLight();
                float3 lighting = mainLight.color * saturate(dot(normalWS, mainLight.direction));
                
                float3 finalColor = tex.rgb * _Color.rgb * lighting * lerp(1, ao.rgb, _AOPower);
                return float4(finalColor, 1);
            }
            ENDHLSL
        }
    }
    Fallback "Universal Render Pipeline/Lit"
}