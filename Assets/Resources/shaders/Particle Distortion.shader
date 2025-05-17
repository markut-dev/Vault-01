Shader "Particles/Distortion"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _DistortionTex ("Distortion (RGB)", 2D) = "bump" {}
        _DistortionAmount ("Distortion Amount", Range(0,1)) = 0.1
    }
    
    SubShader
    {
        Tags 
        { 
            "RenderType" = "Transparent"
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Transparent"
        }
        
        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
            
            Blend SrcAlpha OneMinusSrcAlpha
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
                float4 color : COLOR;
            };
            
            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
            };
            
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_DistortionTex);
            SAMPLER(sampler_DistortionTex);
            
            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _DistortionTex_ST;
                float _DistortionAmount;
            CBUFFER_END
            
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                OUT.color = IN.color;
                return OUT;
            }
            
            float4 frag(Varyings IN) : SV_Target
            {
                float2 distortion = SAMPLE_TEXTURE2D(_DistortionTex, sampler_DistortionTex, IN.uv).rg * 2 - 1;
                float2 distortedUV = IN.uv + distortion * _DistortionAmount;
                float4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, distortedUV);
                return color * IN.color;
            }
            ENDHLSL
        }
    }
    Fallback "Universal Render Pipeline/Lit"
}