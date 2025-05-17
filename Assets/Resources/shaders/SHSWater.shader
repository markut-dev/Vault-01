//////////////////////////////////////////
//
// NOTE: This is *not* a valid shader file
//
///////////////////////////////////////////
Shader "Marvel/FX/Water Surface"
{
    Properties
    {
        _Color ("Water Color", Color) = (0.2,0.5,0.8,1)
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _WaveSpeed ("Wave Speed", Range(0,10)) = 1
        _WaveAmplitude ("Wave Amplitude", Range(0,1)) = 0.1
        _FresnelPower ("Fresnel Power", Range(0.1,8)) = 2.5
        _FresnelColor ("Fresnel Color", Color) = (0.5,0.8,1,1)
    }
    SubShader
    {
        Tags { "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" "Queue" = "Transparent" }
        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            Cull Back
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            struct Attributes {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };
            struct Varyings {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float3 viewDirWS : TEXCOORD2;
            };
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float4 _MainTex_ST;
                float _WaveSpeed;
                float _WaveAmplitude;
                float _FresnelPower;
                float4 _FresnelColor;
            CBUFFER_END
            Varyings vert(Attributes IN) {
                Varyings OUT;
                float3 pos = IN.positionOS.xyz;
                float time = _Time.y * _WaveSpeed;
                pos.y += sin(pos.x * 2 + time) * cos(pos.z * 2 + time) * _WaveAmplitude;
                OUT.positionHCS = TransformObjectToHClip(pos);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                float3 positionWS = TransformObjectToWorld(pos);
                OUT.viewDirWS = GetWorldSpaceViewDir(positionWS);
                return OUT;
            }
            float4 frag(Varyings IN) : SV_Target {
                float4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
                float3 N = normalize(IN.normalWS);
                float3 V = normalize(IN.viewDirWS);
                float fresnel = pow(1.0 - saturate(dot(N, V)), _FresnelPower);
                float3 fresnelCol = fresnel * _FresnelColor.rgb;
                float3 baseCol = tex.rgb * _Color.rgb + fresnelCol;
                return float4(baseCol, _Color.a);
            }
            ENDHLSL
        }
    }
    Fallback "Universal Render Pipeline/Unlit"
}