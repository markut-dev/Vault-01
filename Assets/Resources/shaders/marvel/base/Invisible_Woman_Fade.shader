Shader "Marvel/Base/Invisible Woman Fade"
{
    Properties {
        _Color ("Main Color", Color) = (1,1,1,1)
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _DistortionTex ("Distortion (RG)", 2D) = "bump" {}
        _DistortionAmount ("Distortion Amount", Range(0,1)) = 0.1
        _FadeAmount ("Fade Amount", Range(0,1)) = 0.5
        _RimColor ("Rim Color", Color) = (0.5,0.5,0.5,1)
        _RimPower ("Rim Power", Range(0.1,8.0)) = 3.0
    }
    SubShader {
        Tags { 
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
            "IgnoreProjector" = "True"
        }
        LOD 200

        Pass {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            Cull Back

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            // URP Keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
            #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
            #pragma multi_compile_fragment _ _LIGHT_LAYERS
            #pragma multi_compile_fragment _ _LIGHT_COOKIES
            #pragma multi_compile _ _FORWARD_PLUS

            // Unity Keywords
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            #pragma instancing_options renderinglayer
            #pragma multi_compile _ DOTS_INSTANCING_ON

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"

            struct Attributes {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
                float2 lightmapUV : TEXCOORD1;
            };

            struct Varyings {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float2 uvDistortion : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
                float3 positionWS : TEXCOORD3;
                float3 viewDirWS : TEXCOORD4;
                float2 lightmapUV : TEXCOORD5;
                float fogFactor : TEXCOORD6;
                float4 shadowCoord : TEXCOORD7;
            };

            TEXTURE2D(_MainTex);
            TEXTURE2D(_DistortionTex);
            SAMPLER(sampler_MainTex);
            SAMPLER(sampler_DistortionTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _DistortionTex_ST;
                half4 _Color;
                float _DistortionAmount;
                float _FadeAmount;
                half4 _RimColor;
                float _RimPower;
            CBUFFER_END

            Varyings vert(Attributes input) {
                Varyings output = (Varyings)0;

                // Transformaciones básicas
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.positionCS = TransformWorldToHClip(output.positionWS);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.viewDirWS = GetWorldSpaceViewDir(output.positionWS);

                // UVs
                output.uv = TRANSFORM_TEX(input.uv, _MainTex);
                output.uvDistortion = TRANSFORM_TEX(input.uv, _DistortionTex);

                // Lightmap
                OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);

                // Shadows
                output.shadowCoord = TransformWorldToShadowCoord(output.positionWS);

                // Fog
                output.fogFactor = ComputeFogFactor(output.positionCS.z);

                return output;
            }

            half4 frag(Varyings input) : SV_Target {
                // Distorsión
                half2 distortion = SAMPLE_TEXTURE2D(_DistortionTex, sampler_DistortionTex, input.uvDistortion).rg * 2 - 1;
                float2 distortedUV = input.uv + distortion * _DistortionAmount;

                // Textura base
                half4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, distortedUV);
                half4 col = tex * _Color;

                // Iluminación principal
                Light mainLight = GetMainLight(input.shadowCoord);
                half3 normalWS = normalize(input.normalWS);
                half NdotL = saturate(dot(normalWS, mainLight.direction));
                
                // Rim lighting
                half3 viewDirWS = normalize(input.viewDirWS);
                half rim = 1.0 - saturate(dot(viewDirWS, normalWS));
                rim = pow(rim, _RimPower);
                col.rgb += _RimColor.rgb * rim;

                // Iluminación final
                half3 lighting = mainLight.color * NdotL * mainLight.shadowAttenuation;
                
                // Luces adicionales
                #ifdef _ADDITIONAL_LIGHTS
                uint pixelLightCount = GetAdditionalLightsCount();
                for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex) {
                    Light light = GetAdditionalLight(lightIndex, input.positionWS);
                    half NdotL = saturate(dot(normalWS, light.direction));
                    lighting += light.color * NdotL * light.distanceAttenuation * light.shadowAttenuation;
                }
                #endif

                // Aplicar iluminación
                col.rgb *= lighting;

                // Lightmap
                #ifdef LIGHTMAP_ON
                    half3 bakedGI = SampleLightmap(input.lightmapUV, normalWS);
                    col.rgb *= bakedGI;
                #endif

                // Fade
                col.a *= (1 - _FadeAmount);

                // Fog
                col.rgb = MixFog(col.rgb, input.fogFactor);

                return col;
            }
            ENDHLSL
        }

        // Shadow casting support
        Pass {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            ZWrite On
            ZTest LEqual
            Cull Back

            HLSLPROGRAM
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            struct Attributes {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
            };

            struct Varyings {
                float4 positionCS : SV_POSITION;
            };

            float3 _LightDirection;

            Varyings ShadowPassVertex(Attributes input) {
                Varyings output;
                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
                float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));
                output.positionCS = positionCS;
                return output;
            }

            half4 ShadowPassFragment(Varyings input) : SV_TARGET {
                return 0;
            }
            ENDHLSL
        }
    }
    FallBack "Universal Render Pipeline/Unlit"
}