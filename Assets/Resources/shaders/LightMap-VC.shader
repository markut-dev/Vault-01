Shader "Marvel/Lightmap/Vertex Color"
{
    Properties
    {
        _Color ("Main Color", Color) = (1,1,1,1)
        _LightMap ("Lightmap (RGB) AO (A)", 2D) = "black" {}
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
			//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv1 : TEXCOORD1;
                float4 color : COLOR;
            };
            
            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 color : TEXCOORD1;
            };
            
            TEXTURE2D(_LightMap);
            SAMPLER(sampler_LightMap);
            
            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float4 _LightMap_ST;
            CBUFFER_END
            
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv1, _LightMap);
                OUT.color = IN.color * _Color;
                return OUT;
            }
            
            float4 frag(Varyings IN) : SV_Target
            {
                float4 lightMap = SAMPLE_TEXTURE2D(_LightMap, sampler_LightMap, IN.uv);
                return lightMap * IN.color;
            }
            ENDHLSL
        }
    }
    Fallback "Universal Render Pipeline/Lit"
}

// Estoy cansado, no me acuerdo de que shader era este.