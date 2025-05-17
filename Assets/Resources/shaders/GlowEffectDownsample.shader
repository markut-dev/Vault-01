//////////////////////////////////////////
//
// NOTE: This is *not* a valid shader file
//
///////////////////////////////////////////
Shader "Hidden/Glow Downsample"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,0)
        _MainTex ("", 2D) = "white" {}
    }
    
    SubShader
    {
        Tags 
        { 
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
        }
        
        Pass
        {
            Name "Downsample"
            Tags { "LightMode" = "UniversalForward" }
            
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
                float2 uv1 : TEXCOORD1;
                float2 uv2 : TEXCOORD2;
                float2 uv3 : TEXCOORD3;
            };
            
            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float4 _MainTex_TexelSize;
            CBUFFER_END
            
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                float2 uv = IN.uv;
                
                // Calculate offsets for 4 samples
                float2 offset = _MainTex_TexelSize.xy;
                OUT.uv = uv + float2(-offset.x, -offset.y);
                OUT.uv1 = uv + float2(offset.x, -offset.y);
                OUT.uv2 = uv + float2(offset.x, offset.y);
                OUT.uv3 = uv + float2(-offset.x, offset.y);
                
                return OUT;
            }
            
            float4 frag(Varyings IN) : SV_Target
            {
                // Sample 4 texels and average them
                float4 color = 0;
                color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
                color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv1);
                color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv2);
                color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv3);
                color *= 0.25;
                
                // Apply color tint and alpha
                float alpha = color.a + _Color.a;
                float3 finalColor = color.rgb * _Color.rgb * alpha;
                
                return float4(finalColor, 0);
            }
            ENDHLSL
        }
    }
    Fallback Off
}