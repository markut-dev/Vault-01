// Alejandro -> cambio a sintaxis URP. Shader autoiluminado con transparencia y soporte para lightmaps.
Shader "Marvel/Base/Self-Illuminated Alpha"
{
    Properties {
        _Color ("Main Color", Color) = (1,1,1,1)
        _Alpha ("Alpha", Range(0,1)) = 1
    }
    SubShader {
        Tags { 
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
        }
        LOD 200

        Pass {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

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
            #pragma multi_compile LIGHTMAP_OFF LIGHTMAP_ON

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"

            struct Attributes {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 color : COLOR;
                float2 lightmapUV : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings {
                float4 positionCS : SV_POSITION;
                float4 color : COLOR;
                float3 normalWS : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float2 lightmapUV : TEXCOORD2;
                float4 shadowCoord : TEXCOORD3;
                float fogFactor : TEXCOORD4;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            CBUFFER_START(UnityPerMaterial)
                half4 _Color;
                half _Alpha;
            CBUFFER_END

            Varyings vert(Attributes input) {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.positionCS = TransformWorldToHClip(output.positionWS);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.color = input.color * _Color;

                // Lightmap
                #ifdef LIGHTMAP_ON
                    output.lightmapUV = input.lightmapUV * unity_LightmapST.xy + unity_LightmapST.zw;
                #endif

                // Shadows
                output.shadowCoord = TransformWorldToShadowCoord(output.positionWS);

                // Fog
                output.fogFactor = ComputeFogFactor(output.positionCS.z);

                return output;
            }

            half4 frag(Varyings input) : SV_Target {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                half4 col = input.color;

                // Iluminación principal
                Light mainLight = GetMainLight(input.shadowCoord);
                half3 normalWS = normalize(input.normalWS);
                half NdotL = saturate(dot(normalWS, mainLight.direction));

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

                // Lightmap
                #ifdef LIGHTMAP_ON
                    half3 bakedGI = SampleLightmap(input.lightmapUV, normalWS);
                    lighting += bakedGI;
                #endif

                // Aplicar iluminación
                col.rgb *= lighting;

                // Aplicar transparencia
                col.a *= _Alpha;

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

            HLSLPROGRAM
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            struct Attributes {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings {
                float4 positionCS : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            float3 _LightDirection;

            Varyings ShadowPassVertex(Attributes input) {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
                float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));
                output.positionCS = positionCS;
                return output;
            }

            half4 ShadowPassFragment(Varyings input) : SV_TARGET {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                return 0;
            }
            ENDHLSL
        }
    }
    FallBack "Universal Render Pipeline/Unlit"
}