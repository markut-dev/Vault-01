Shader "Hidden/AO Fast Depth"
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
            Name "FastDepth"
            Tags { "LightMode"="UniversalForward" }
            
            Cull Front
            
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
                float depth : TEXCOORD0;
            };
            
            CBUFFER_START(UnityPerMaterial)
                float4 _AORadius;
            CBUFFER_END
            
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.depth = OUT.positionHCS.z;
                return OUT;
            }
            
            float4 frag(Varyings IN) : SV_Target
            {
                float depth = abs(IN.depth);
                float ao = saturate(depth * _AORadius.z + _AORadius.y);
                float4 color = 1.0 - ao;
                return color;
            }
            ENDHLSL
        }
    }
    Fallback Off
}