Shader "Marvel/Gaussian2D"
{
    Properties
    {
        _MainTex2D ("Base (RGB)", 2D) = "white" {}
        _Horizontal ("Horizontal", Float) = 1
        _Weights0 ("Weights0", Vector) = (0,0,0,0)
        _Weights1 ("Weights1", Vector) = (0,0,0,0)
        _Weights2 ("Weights2", Vector) = (0,0,0,0)
        _Weights3 ("Weights3", Vector) = (0,0,0,0)
    }
    
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        
        Pass
        {
            Name "GaussianBlur"
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
                float4 blurUV[8] : TEXCOORD1;
            };
            
            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex2D_TexelSize;
                float _Horizontal;
                float4 _Weights0;
                float4 _Weights1;
                float4 _Weights2;
                float4 _Weights3;
            CBUFFER_END
            
            TEXTURE2D(_MainTex2D);
            SAMPLER(sampler_MainTex2D);
            
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.uv;
                
                // Calculate blur offsets
                float2 texelSize = _MainTex2D_TexelSize.xy;
                float2 blurOffset = float2(_Horizontal, 1 - _Horizontal) * texelSize;
                
                // Calculate 8 sample positions
                OUT.blurUV[0].xy = IN.uv + blurOffset * float2(-3.5, -3.5);
                OUT.blurUV[0].zw = IN.uv + blurOffset * float2(-2.5, -2.5);
                OUT.blurUV[1].xy = IN.uv + blurOffset * float2(-1.5, -1.5);
                OUT.blurUV[1].zw = IN.uv + blurOffset * float2(-0.5, -0.5);
                OUT.blurUV[2].xy = IN.uv + blurOffset * float2(0.5, 0.5);
                OUT.blurUV[2].zw = IN.uv + blurOffset * float2(1.5, 1.5);
                OUT.blurUV[3].xy = IN.uv + blurOffset * float2(2.5, 2.5);
                OUT.blurUV[3].zw = IN.uv + blurOffset * float2(3.5, 3.5);
                
                return OUT;
            }
            
            float4 frag(Varyings IN) : SV_Target
            {
                float4 color = 0;
                
                // Sample and weight the texture
                color += SAMPLE_TEXTURE2D(_MainTex2D, sampler_MainTex2D, IN.blurUV[0].xy) * _Weights0.x;
                color += SAMPLE_TEXTURE2D(_MainTex2D, sampler_MainTex2D, IN.blurUV[0].zw) * _Weights0.y;
                color += SAMPLE_TEXTURE2D(_MainTex2D, sampler_MainTex2D, IN.blurUV[1].xy) * _Weights0.z;
                color += SAMPLE_TEXTURE2D(_MainTex2D, sampler_MainTex2D, IN.blurUV[1].zw) * _Weights0.w;
                color += SAMPLE_TEXTURE2D(_MainTex2D, sampler_MainTex2D, IN.blurUV[2].xy) * _Weights1.x;
                color += SAMPLE_TEXTURE2D(_MainTex2D, sampler_MainTex2D, IN.blurUV[2].zw) * _Weights1.y;
                color += SAMPLE_TEXTURE2D(_MainTex2D, sampler_MainTex2D, IN.blurUV[3].xy) * _Weights1.z;
                color += SAMPLE_TEXTURE2D(_MainTex2D, sampler_MainTex2D, IN.blurUV[3].zw) * _Weights1.w;
                
                return color;
            }
            ENDHLSL
        }
    }
    Fallback Off
}