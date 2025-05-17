Shader "Hidden/Depth Of Field"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _BlurAmount ("Blur Amount", Range(0,10)) = 1
        _FocusDistance ("Focus Distance", Float) = 10
        _FocusRange ("Focus Range", Float) = 3
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "Queue" = "Geometry" }
        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            
            struct Attributes {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };
            
            struct Varyings {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };
            
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            
            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float _BlurAmount;
                float _FocusDistance;
                float _FocusRange;
            CBUFFER_END
            
            Varyings vert(Attributes IN) {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                return OUT;
            }
            
            float4 frag(Varyings IN) : SV_Target {
                float depth = SampleSceneDepth(IN.uv);
                float linearDepth = LinearEyeDepth(depth, _ZBufferParams);
                float blurFactor = saturate(abs(linearDepth - _FocusDistance) / _FocusRange);
                blurFactor = pow(blurFactor, 2);
                
                float blur = _BlurAmount * blurFactor;
                float4 color = float4(0,0,0,0);
                
                for(int x = -2; x < 2; x++) {
                    for(int y = -2; y < 2; y++) {
                        float2 offset = float2(x, y) * blur * 0.01;
                        color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv + offset);
                    }
                }
                
                return color / 16;
            }
            ENDHLSL
        }
    }
    Fallback "Universal Render Pipeline/Unlit"
}