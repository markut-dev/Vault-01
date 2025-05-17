Shader "Marvel/FX/Flag URP"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _WaveScale ("WaveScale", Vector) = (1,1,1,0)
        _WavePeriod ("WavePeriod", Vector) = (1,1,1,0)
        _WaveAmp ("WaveAmp", Vector) = (1,1,1,0)
        _XScale ("XScale", Float) = 1
        _XBias ("XBias", Float) = 0.25
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
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
            
            Cull Off
            
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
            };
            
            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float3 positionWS : TEXCOORD2;
            };
            
            CBUFFER_START(UnityPerMaterial)
                float4 _WaveScale;
                float4 _WavePeriod;
                float4 _WaveAmp;
                float _XScale;
                float _XBias;
                float4 _MainTex_ST;
            CBUFFER_END
            
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            
            float3 CalculateWave(float3 position, float3 normal)
            {
                float3 wavePos = position * _WaveScale.xyz + _Time.y * _WavePeriod.xyz;
                
                // Calculate wave offsets
                float3 waveOffsets = 0;
                waveOffsets.x = sin(wavePos.x * 6.283185) * _WaveAmp.x;
                waveOffsets.y = sin(wavePos.y * 6.283185) * _WaveAmp.y;
                waveOffsets.z = sin(wavePos.z * 6.283185) * _WaveAmp.z;
                
                // Apply wave to normal
                float3 waveNormal = normal + waveOffsets;
                waveNormal = normalize(waveNormal);
                
                // Calculate vertex offset
                float xOffset = position.x * _XScale + _XBias;
                float3 vertexOffset = waveNormal * xOffset;
                
                return vertexOffset;
            }
            
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                
                // Calculate wave offset
                float3 waveOffset = CalculateWave(IN.positionOS.xyz, IN.normalOS);
                float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz + waveOffset);
                
                OUT.positionHCS = TransformWorldToHClip(positionWS);
                OUT.positionWS = positionWS;
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                
                return OUT;
            }
            
            float4 frag(Varyings IN) : SV_Target
            {
                // Sample texture
                float4 texColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
                
                // Calculate lighting
                float3 normalWS = normalize(IN.normalWS);
                float3 viewDirWS = normalize(_WorldSpaceCameraPos - IN.positionWS);
                
                // Basic lighting
                float3 lightDirWS = normalize(_MainLightPosition.xyz);
                float NdotL = saturate(dot(normalWS, lightDirWS));
                float3 diffuse = _MainLightColor.rgb * NdotL;
                
                // Ambient
                float3 ambient = SampleSH(normalWS);
                
                // Final color
                float3 finalColor = (diffuse + ambient) * texColor.rgb;
                return float4(finalColor, texColor.a);
            }
            ENDHLSL
        }
    }
    Fallback "Universal Render Pipeline/Lit"
}