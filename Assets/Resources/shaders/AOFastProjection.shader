Shader "Hidden/AO Fast Projection"
{
    Properties
    {
        _AORadius ("AO Radius", Vector) = (1,1,1,1)
        _TileSize ("Tile Size", Float) = 1
        _BlurGutterSize ("Blur Gutter Size", Float) = 1
    }
    
    SubShader
    {
        Tags { "Queue"="Geometry+900" "RenderType"="Opaque" }
        
        Pass
        {
            Name "Projection"
            Tags { "LightMode"="UniversalForward" }
            
            ZTest GEqual
            ZWrite Off
            Cull Front
            Blend DstColor Zero
            ColorMask RGB
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            
            struct Attributes
            {
                float4 positionOS : POSITION;
                float4 color : COLOR;
                float2 uv : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
            };
            
            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 screenPos : TEXCOORD1;
                float4 projPos : TEXCOORD2;
                float3 viewDir : TEXCOORD3;
                float3 aoParams : TEXCOORD4;
            };
            
            CBUFFER_START(UnityPerMaterial)
                float4 _AORadius;
                float _TileSize;
                float _BlurGutterSize;
            CBUFFER_END
            
            TEXTURE2D(_ShadowTex);
            SAMPLER(sampler_ShadowTex);
            
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                
                // Transform position
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                
                // Calculate screen position
                float4 screenPos = ComputeScreenPos(OUT.positionHCS);
                OUT.screenPos = screenPos;
                
                // Calculate projection position
                float4 projPos = OUT.positionHCS;
                projPos.xy = (projPos.xy / projPos.w) * 0.5 + 0.5;
                OUT.projPos = projPos;
                
                // Calculate view direction
                float3 worldPos = TransformObjectToWorld(IN.positionOS.xyz);
                float3 viewDir = GetWorldSpaceViewDir(worldPos);
                OUT.viewDir = viewDir;
                
                // Calculate AO parameters
                float2 tileSize = _TileSize * _ScreenParams.zw;
                float2 blurGutter = _BlurGutterSize * tileSize;
                OUT.aoParams = float3(blurGutter, _AORadius.z);
                
                // Calculate UVs
                float2 uv = IN.uv;
                uv = uv * (1.0 + blurGutter) - blurGutter * 0.5;
                OUT.uv = uv;
                
                return OUT;
            }
            
            float4 frag(Varyings IN) : SV_Target
            {
                // Sample depth
                float2 screenUV = IN.screenPos.xy / IN.screenPos.w;
                float sceneDepth = SampleSceneDepth(screenUV);
                float linearDepth = LinearEyeDepth(sceneDepth, _ZBufferParams);
                
                // Calculate AO
                float3 viewDir = normalize(IN.viewDir);
                float3 aoDir = viewDir * IN.aoParams.z;
                float ao = 1.0 - saturate(dot(aoDir, viewDir));
                
                // Sample shadow texture
                float2 shadowUV = IN.uv;
                float shadow = SAMPLE_TEXTURE2D(_ShadowTex, sampler_ShadowTex, shadowUV).r;
                
                // Combine results
                float4 color = float4(1.0 - ao * shadow, 1.0 - ao * shadow, 1.0 - ao * shadow, 1.0);
                return color;
            }
            ENDHLSL
        }
    }
    Fallback Off
}