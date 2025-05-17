//////////////////////////////////////////
//
// NOTE: This is *not* a valid shader file
//
///////////////////////////////////////////
Shader "Marvel/FX/Water/Integration URP" {
    Properties
    {
        _MainTex ("Height", 2D) = "white" {}
        _SpeedTex ("Speed", 2D) = "white" {}
        _ImpulseTex ("Impulse", 2D) = "white" {}
        _Dampening ("Dampening", Float) = 0.99
        _DeltaTime ("Delta Time", Float) = 1
        _Instability ("Instability", Float) = 60
    }
    
    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        
        Pass
        {
            Name "Integration"
            Tags { "LightMode"="UniversalForward" }
            
            ZTest Always
            ZWrite Off
            Cull Off
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };
            
            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };
            
            CBUFFER_START(UnityPerMaterial)
                float _Dampening;
                float _DeltaTime;
                float _Instability;
            CBUFFER_END
            
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_SpeedTex);
            SAMPLER(sampler_SpeedTex);
            TEXTURE2D(_ImpulseTex);
            SAMPLER(sampler_ImpulseTex);
            
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.uv;
                return OUT;
            }
            
            float4 frag(Varyings IN) : SV_Target
            {
                float height = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).r;
                float speed = SAMPLE_TEXTURE2D(_SpeedTex, sampler_SpeedTex, IN.uv).r;
                float impulse = SAMPLE_TEXTURE2D(_ImpulseTex, sampler_ImpulseTex, IN.uv).r;
                
                // Convert from [0,1] to [-1,1] range
                height = height * 2.0 - 1.0;
                speed = speed * 2.0 - 1.0;
                
                // Integrate height and speed
                float newHeight = height + speed * _DeltaTime;
                float newSpeed = speed * _Dampening + impulse * _Instability;
                
                // Convert back to [0,1] range
                newHeight = newHeight * 0.5 + 0.5;
                newSpeed = newSpeed * 0.5 + 0.5;
                
                return float4(newHeight, newSpeed, 0.0, 1.0);
            }
            ENDHLSL
        }
    }
    Fallback Off
}