Shader "Marvel/AO/Vertex Color"
{
    Properties
    {
        _Color ("Main Color", Color) = (1,1,1,1)
        _AOMap ("AO Map (RGB)", 2D) = "white" {}
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
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
            };
            
            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float4 color : COLOR;
            };
            
            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float4 _AOMap_ST;
            CBUFFER_END
            
            TEXTURE2D(_AOMap);
            SAMPLER(sampler_AOMap);
            
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                OUT.uv = TRANSFORM_TEX(IN.uv, _AOMap);
                OUT.color = IN.color;
                return OUT;
            }
            
            float4 frag(Varyings IN) : SV_Target
            {
                float4 aoMap = SAMPLE_TEXTURE2D(_AOMap, sampler_AOMap, IN.uv);
                float3 normalWS = normalize(IN.normalWS);
                
                float3 lightDirWS = normalize(_MainLightPosition.xyz);
                float NdotL = saturate(dot(normalWS, lightDirWS));
                float3 diffuse = _MainLightColor.rgb * NdotL;
                float3 ambient = SampleSH(normalWS);
                
                float3 baseColor = IN.color.rgb * _Color.rgb;
                float3 finalColor = (diffuse + ambient) * baseColor * aoMap.rgb;
                
                return float4(finalColor, 1.0);
            }
            ENDHLSL
        }
    }
    Fallback "Universal Render Pipeline/Lit"
}