Shader "Custom/HandDrawnToon_MultiLight"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BrushTex ("Brush Stroke Texture", 2D) = "white" {}
        _ToonRamp ("Toon Ramp", 2D) = "white" {}
        _ShadowThreshold ("Shadow Threshold", Range(0,1)) = 0.5
        _OutlineColor ("Outline Color", Color) = (0,0,0,1)
        _OutlineThickness ("Outline Thickness", Range(0, 2)) = 0.01
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Pass
        {
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
                float2 uv : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                float4 positionCS : SV_POSITION;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_BrushTex);
            SAMPLER(sampler_BrushTex);
            float4 _MainTex_ST;
            float _ShadowThreshold;
            float4 _OutlineColor;
            float _OutlineThickness;

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                OUT.worldPos = TransformObjectToWorld(IN.positionOS.xyz);
                return OUT;
            }

            float4 frag(Varyings IN) : SV_Target
            {
                float3 normal = normalize(IN.normalWS);
                float3 viewDir = normalize(_WorldSpaceCameraPos - IN.worldPos);
                Light mainLight = GetMainLight();
                float3 lightDir = normalize(mainLight.direction);
                float NdotL = dot(normal, lightDir);

                // Sample Base Texture
                float4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);

                // Apply Point & Spot Lights
                uint pixelLightCount = GetAdditionalLightsCount();
                for (uint i = 0; i < pixelLightCount; i++)
                {
                    Light light = GetAdditionalLight(i, IN.worldPos);
                    float3 additionalLightDir = normalize(light.direction);
                    float additionalNdotL = dot(normal, additionalLightDir);

                    float lightFactor = smoothstep(0, _ShadowThreshold, additionalNdotL);
                    col.rgb += light.color * lightFactor;
                }

                // Apply Shadows & Brush Texture
                float shadowFactor = step(_ShadowThreshold, NdotL);
                float brushEffect = SAMPLE_TEXTURE2D(_BrushTex, sampler_BrushTex, IN.uv * 5).r; 
                shadowFactor = lerp(shadowFactor, brushEffect, 0.5); 
                col.rgb *= shadowFactor;

                return col;
            }
            ENDHLSL
        }
    }
}
