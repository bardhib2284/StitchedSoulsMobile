Shader "Custom/PlushyShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NormalMap ("Normal Map", 2D) = "bump" {}
        _FuzzColor ("Fuzz Color", Color) = (1,1,1,1)
        _FuzzIntensity ("Fuzz Intensity", Range(0,1)) = 0.5
        _EdgeSoftness ("Edge Softness", Range(0,1)) = 0.3
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows

        sampler2D _MainTex;
        sampler2D _NormalMap;
        float4 _FuzzColor;
        float _FuzzIntensity;
        float _EdgeSoftness;

        struct Input
        {
            float2 uv_MainTex;
            float3 viewDir;
        };

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            float4 texColor = tex2D(_MainTex, IN.uv_MainTex);
            float3 normalTex = UnpackNormal(tex2D(_NormalMap, IN.uv_MainTex));

            // **Fixing Fabric Normal Map**
            normalTex = normalize(normalTex * 2.0 - 1.0); 

            // **Fresnel Effect for Soft Plush Edges**
            float fresnel = saturate(dot(IN.viewDir, o.Normal) * _EdgeSoftness);
            float fuzzFactor = pow(fresnel, 4) * _FuzzIntensity;
            float3 finalColor = lerp(texColor.rgb, _FuzzColor.rgb, fuzzFactor);

            o.Albedo = finalColor;
            o.Normal = normalTex;
            o.Smoothness = 0.1; // Makes fabric look soft, not shiny
            o.Metallic = 0; // No metallic reflections
        }
        ENDCG
    }
}
