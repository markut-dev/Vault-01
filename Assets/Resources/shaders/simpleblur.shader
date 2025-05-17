Shader "SimpleBlur"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _Horizontal ("Horizontal (Private)", Float) = 1
        _Weights0 ("Weights0 (Private)", Vector) = (0,0,0,0)
        _Weights1 ("Weights1 (Private)", Vector) = (0,0,0,0)
        _Weights2 ("Weights2 (Private)", Vector) = (0,0,0,0)
        _Weights3 ("Weights3 (Private)", Vector) = (0,0,0,0)
    }
    
    SubShader
    {
        Tags 
        { 
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Geometry"
        }
        
        Pass
        {
            Name "Blur"
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
                float4 uv1 : TEXCOORD1;
                float4 uv2 : TEXCOORD2;
                float4 uv3 : TEXCOORD3;
            };
            
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _MainTex_TexelSize;
            
            CBUFFER_START(UnityPerMaterial)
                float _Horizontal;
                float4 _Weights0;
                float4 _Weights1;
                float4 _Weights2;
                float4 _Weights3;
            CBUFFER_END
            
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.uv;
                
                // Calculate UV offsets for blur
                float2 texelSize = _MainTex_TexelSize.xy;
                float2 offset1 = float2(0.001953125, -0.001953125);
                float2 offset2 = float2(0.00390625, -0.00390625);
                float2 offset3 = float2(0.005859375, -0.005859375);
                
                OUT.uv1 = IN.uv.xyxy + offset1.xxyy;
                OUT.uv2 = IN.uv.xyxy + offset2.xxyy;
                OUT.uv3 = IN.uv.xyxy + offset3.xxyy;
                
                return OUT;
            }
            
            float4 frag(Varyings IN) : SV_Target
            {
                float4 weights = float4(0.4, 0.15, 0.1, 0.05);
                
                float4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv) * weights.x;
                color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv1.xy) * weights.y;
                color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv1.zw) * weights.y;
                color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv2.xy) * weights.z;
                color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv2.zw) * weights.z;
                color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv3.xy) * weights.w;
                color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv3.zw) * weights.w;
                
                return color;
            }
            ENDHLSL
        }
    }
    Fallback Off
}