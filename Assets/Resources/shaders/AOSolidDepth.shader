Shader "Hidden/AO Solid Depth"
{
    Properties
    {
        _AORadius ("AO Radius", Vector) = (1,1,1,1)
    }
    
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        
        Pass
        {
            Name "SolidDepth"
            Tags { "LightMode"="UniversalForward" }
            
            Cull Off
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            struct Attributes
            {
                float4 positionOS : POSITION;
            };
            
            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float4 color : TEXCOORD0;
            };
            
            CBUFFER_START(UnityPerMaterial)
                float4 _AORadius;
            CBUFFER_END
            
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                
                // Calculate color based on AO radius
                float3 color = float3(1.0, 1.0, 1.0) - _AORadius.yyy;
                OUT.color = float4(color, 1.0);
                
                return OUT;
            }
            
            float4 frag(Varyings IN) : SV_Target
            {
                return IN.color;
            }
            ENDHLSL
        }
    }
    Fallback Off
}