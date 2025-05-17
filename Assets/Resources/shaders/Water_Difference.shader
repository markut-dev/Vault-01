//////////////////////////////////////////
//
// NOTE: This is *not* a valid shader file
//
///////////////////////////////////////////
Shader "Marvel/FX/Water/Difference URP"
{
    Properties
    {
        _MainTex ("Current Intersection", 2D) = "white" {}
        _OldTex ("Last Intersection", 2D) = "white" {}
    }
    
    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        
        Pass
        {
            Name "Difference"
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
            
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_OldTex);
            SAMPLER(sampler_OldTex);
            
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.uv;
                return OUT;
            }
            
            float4 frag(Varyings IN) : SV_Target
            {
                float current = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).r;
                float last = SAMPLE_TEXTURE2D(_OldTex, sampler_OldTex, IN.uv).r;
                float difference = (current - last) * 0.5 + 0.5;
                return float4(difference, difference, difference, 1.0);
            }
            ENDHLSL
        }
    }
    Fallback Off
}