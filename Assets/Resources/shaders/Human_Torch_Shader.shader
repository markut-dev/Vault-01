Shader "Marvel/Characters/Human Torch"
{
    Properties
    {
        _Color ("Main Color", Color) = (1,1,1,1)
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _NoiseScale ("Noise Scale", Vector) = (1,1,1,1)
        _NoiseSpeed ("Noise Speed", Vector) = (1,1,1,1)
        _NoiseBias ("Noise Bias", Float) = 1.3
        _NoiseContrast ("Noise Contrast", Float) = 0.05
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
            };
            
            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float3 viewDirWS : TEXCOORD2;
                float3 positionWS : TEXCOORD3;
                float3 normalOS : TEXCOORD4;
                float3 sh : TEXCOORD5;
            };
            
            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float4 _MainTex_ST;
                float4 _NoiseScale;
                float4 _NoiseSpeed;
                float _NoiseBias;
                float _NoiseContrast;
            CBUFFER_END
            
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            
            // Noise function
            float2 unity_noise_randomValue(float2 uv)
            {
                uv = uv * float2(12.9898, 78.233);
                return frac(sin(uv) * 43758.5453);
            }
            
            float unity_noise_interpolate(float a, float b, float t)
            {
                return (1.0 - t) * a + (t * b);
            }
            
            float unity_valueNoise(float2 uv)
            {
                float2 i = floor(uv);
                float2 f = frac(uv);
                f = f * f * (3.0 - 2.0 * f);
                
                float2 c0 = i + float2(0.0, 0.0);
                float2 c1 = i + float2(1.0, 0.0);
                float2 c2 = i + float2(0.0, 1.0);
                float2 c3 = i + float2(1.0, 1.0);
                
                float r0 = unity_noise_randomValue(c0).x;
                float r1 = unity_noise_randomValue(c1).x;
                float r2 = unity_noise_randomValue(c2).x;
                float r3 = unity_noise_randomValue(c3).x;
                
                float bottomOfGrid = unity_noise_interpolate(r0, r1, f.x);
                float topOfGrid = unity_noise_interpolate(r2, r3, f.x);
                float t = unity_noise_interpolate(bottomOfGrid, topOfGrid, f.y);
                return t;
            }
            
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                
                // Calculate noise
                float2 noiseUV = IN.positionOS.xz * _NoiseScale.xy + _Time.y * _NoiseSpeed.xy;
                float noise = unity_valueNoise(noiseUV);
                noise = noise * _NoiseContrast + _NoiseBias;
                
                // Apply noise to position
                float3 positionOS = IN.positionOS.xyz;
                positionOS.y += noise;
                
                OUT.positionHCS = TransformObjectToHClip(positionOS.xyz);
                OUT.positionWS = TransformObjectToWorld(positionOS.xyz);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                OUT.viewDirWS = GetWorldSpaceViewDir(OUT.positionWS);
                OUT.normalOS = IN.normalOS;
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                
                // Calculate spherical harmonics
                float3 normalWS = OUT.normalWS;
                OUT.sh = SampleSH(normalWS);
                
                return OUT;
            }
            
            float4 frag(Varyings IN) : SV_Target
            {
                float4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
                float3 normalWS = normalize(IN.normalWS);
                
                // Basic lighting
                float3 lightDirWS = normalize(_MainLightPosition.xyz);
                float NdotL = saturate(dot(normalWS, lightDirWS));
                float3 diffuse = _MainLightColor.rgb * NdotL;
                
                // Ambient
                float3 ambient = IN.sh;
                
                // Combine colors
                float3 baseColor = mainTex.rgb * _Color.rgb;
                float3 finalColor = (diffuse + ambient) * baseColor;
                
                return float4(finalColor, 1.0);
            }
            ENDHLSL
        }
    }
    Fallback "Universal Render Pipeline/Lit"
}