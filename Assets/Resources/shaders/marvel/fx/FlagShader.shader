Shader "Marvel/FX/Flag"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)
        _WaveSpeed ("Wave Speed", Range(0, 10)) = 1
        _WaveAmplitude ("Wave Amplitude", Range(0, 1)) = 0.1
        _WaveFrequency ("Wave Frequency", Range(0, 10)) = 1
        _WindDirection ("Wind Direction", Vector) = (1,0,0,0)
        _AlphaCutoff ("Alpha Cutoff", Range(0,1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" "Queue" = "Transparent" }
        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            Cull Back

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
            };

            struct Varyings {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float3 tangentWS : TEXCOORD2;
                float3 bitangentWS : TEXCOORD3;
                float3 positionWS : TEXCOORD4;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _Color;
                float _WaveSpeed;
                float _WaveAmplitude;
                float _WaveFrequency;
                float4 _WindDirection;
                float _AlphaCutoff;
            CBUFFER_END

            float3 GerstnerWave(float4 wave, float3 p, inout float3 tangent, inout float3 binormal) {
                float steepness = wave.z;
                float wavelength = wave.w;
                float k = 2 * UNITY_PI / wavelength;
                float c = sqrt(9.8 / k);
                float2 d = normalize(wave.xy);
                float f = k * (dot(d, p.xz) - c * _Time.y * _WaveSpeed);
                float a = steepness / k;
                
                tangent += float3(
                    -d.x * d.x * (steepness * sin(f)),
                    d.x * (steepness * cos(f)),
                    -d.x * d.y * (steepness * sin(f))
                );
                binormal += float3(
                    -d.x * d.y * (steepness * sin(f)),
                    d.y * (steepness * cos(f)),
                    -d.y * d.y * (steepness * sin(f))
                );
                return float3(
                    d.x * (a * cos(f)),
                    a * sin(f),
                    d.y * (a * cos(f))
                );
            }

            Varyings vert(Attributes IN) {
                Varyings OUT;
                
                float3 tangent = float3(1, 0, 0);
                float3 binormal = float3(0, 0, 1);
                float3 p = IN.positionOS.xyz;
                
                float3 disp = GerstnerWave(
                    float4(_WindDirection.xyz, _WaveFrequency),
                    p,
                    tangent,
                    binormal
                ) * _WaveAmplitude;
                
                p += disp;
                
                OUT.positionWS = TransformObjectToWorld(p);
                OUT.positionHCS = TransformWorldToHClip(OUT.positionWS);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                
                float3 normalOS = normalize(float3(-tangent.y, 1, -binormal.y));
                OUT.normalWS = TransformObjectToWorldNormal(normalOS);
                OUT.tangentWS = TransformObjectToWorldDir(tangent);
                OUT.bitangentWS = TransformObjectToWorldDir(binormal);
                
                return OUT;
            }

            float4 frag(Varyings IN) : SV_Target {
                float4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
                float4 finalColor = tex * _Color;
                
                // Lighting
                float3 normalWS = normalize(IN.normalWS);
                Light mainLight = GetMainLight();
                float3 diffuse = mainLight.color * saturate(dot(normalWS, mainLight.direction));
                
                finalColor.rgb *= diffuse;
                
                // Alpha cutoff
                clip(finalColor.a - _AlphaCutoff);
                
                return finalColor;
            }
            ENDHLSL
        }
    }
    Fallback "Universal Render Pipeline/Lit"
}