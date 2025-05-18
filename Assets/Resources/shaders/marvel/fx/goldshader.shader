Shader "GoldShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1,0.8,0,1)
        _Metallic ("Metallic", Range(0,1)) = 1
        _Smoothness ("Smoothness", Range(0,1)) = 0.8
        _FresnelPower ("Fresnel Power", Range(0,10)) = 2
        _FresnelColor ("Fresnel Color", Color) = (1,0.8,0,1)
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
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normalOS : NORMAL;
                float3 viewDirOS : TEXCOORD1;
            };

            struct Varyings {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float3 viewDirWS : TEXCOORD2;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _Color;
                float _Metallic;
                float _Smoothness;
                float _FresnelPower;
                float4 _FresnelColor;
            CBUFFER_END

            Varyings vert(Attributes IN) {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                OUT.viewDirWS = GetWorldSpaceViewDir(TransformObjectToWorld(IN.positionOS.xyz));
                return OUT;
            }

            float4 frag(Varyings IN) : SV_Target {
                float4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
                
                float3 normalWS = normalize(IN.normalWS);
                float3 viewDirWS = normalize(IN.viewDirWS);
                float3 reflectDir = reflect(-viewDirWS, normalWS);
                
                // Fresnel
                float fresnel = pow(1.0 - saturate(dot(normalWS, viewDirWS)), _FresnelPower);
                
                // Lighting
                Light mainLight = GetMainLight();
                float3 halfDir = normalize(mainLight.direction + viewDirWS);
                float specular = pow(max(dot(normalWS, halfDir), 0.0), _Smoothness * 100);
                
                float3 diffuse = mainLight.color * saturate(dot(normalWS, mainLight.direction));
                float3 specularColor = lerp(float3(1,1,1), _Color.rgb, _Metallic);
                
                float3 finalColor = tex.rgb * _Color.rgb * diffuse;
                finalColor += specular * specularColor;
                finalColor += fresnel * _FresnelColor.rgb;
                
                return float4(finalColor, tex.a * _Color.a);
            }
            ENDHLSL
        }
    }
    Fallback "Universal Render Pipeline/Lit"
}