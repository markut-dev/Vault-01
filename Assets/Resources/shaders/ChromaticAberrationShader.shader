//////////////////////////////////////////
//
// NOTE: This is *not* a valid shader file
//
///////////////////////////////////////////
Shader "Hidden/ChromaticAberrationShader"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _ChromaticAberrationIntensity ("Chromatic Aberration Intensity", Range(0, 1)) = 0.5
    }
    
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        
        Pass
        {
            Name "ChromaticAberration"
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
                float4 _MainTex_TexelSize;
                float _ChromaticAberrationIntensity;
            CBUFFER_END
            
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.uv;
                return OUT;
            }
            
            float4 frag(Varyings IN) : SV_Target
            {
                // Sample base texture
                float4 baseColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
                
                // Calculate chromatic aberration offset
                float2 uvOffset = IN.uv - 0.5;
                float2 uvSquared = uvOffset * uvOffset;
                float2 aberrationOffset = _ChromaticAberrationIntensity * _MainTex_TexelSize.xy * uvOffset;
                
                // Apply chromatic aberration
                float2 distortedUV = IN.uv - aberrationOffset * dot(uvSquared, float2(1.0, 1.0));
                float4 distortedColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, distortedUV);
                
                // Combine colors
                float4 finalColor = baseColor;
                finalColor.g = distortedColor.g;
                
                return finalColor;
            }
            ENDHLSL
        }
    }
    Fallback Off
}