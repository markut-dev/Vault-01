Shader "Hidden/Depth Of Field Visualization"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _BlurTex ("Blur (RGB)", 2D) = "white" {}
        _FocusDistance ("Focus Distance", Float) = 10
        _FocusRange ("Focus Range", Float) = 5
        _BlurAmount ("Blur Amount", Range(0,1)) = 0.5
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
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            
            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };
            
            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 screenPos : TEXCOORD1;
            };
            
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_BlurTex);
            SAMPLER(sampler_BlurTex);
            
            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float _FocusDistance;
                float _FocusRange;
                float _BlurAmount;
            CBUFFER_END
            
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                OUT.screenPos = ComputeScreenPos(OUT.positionHCS);
                return OUT;
            }
            
            float4 frag(Varyings IN) : SV_Target
            {
                float2 screenUV = IN.screenPos.xy / IN.screenPos.w;
                float sceneDepth = SampleSceneDepth(screenUV);
                float linearDepth = LinearEyeDepth(sceneDepth, _ZBufferParams);
                
                float blurFactor = saturate(abs(linearDepth - _FocusDistance) / _FocusRange);
                blurFactor = pow(blurFactor, 2) * _BlurAmount;
                
                float4 sharpColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
                float4 blurColor = SAMPLE_TEXTURE2D(_BlurTex, sampler_BlurTex, IN.uv);
                
                return lerp(sharpColor, blurColor, blurFactor);
            }
            ENDHLSL
        }
    }
    Fallback Off
}