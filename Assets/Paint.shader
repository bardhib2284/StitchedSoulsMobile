Shader "Custom/PainterlyLighting"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        [HDR]_SpecularColor("Specular color", Color) = (1, 1, 1, 1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        [Normal]_Normal("Normal", 2D) = "bump" {}
        _NormalStrength("Normal strength", Range(-2, 2)) = 1
        
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        
        _ShadingGradient("Shading gradient", 2D) = "white" {}
        _PainterlyGuide("Painterly guide", 2D) = "white" {}
        _PainterlySmoothness("Painterly smoothness", Range(0, 1)) = 0.1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Painterly fullforwardshadows
        #include "UnityPBSLighting.cginc"

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        sampler2D _PainterlyGuide;
        sampler2D _Normal;
        float _PainterlySmoothness;
        sampler2D _ShadingGradient;
        float4 _SpecularColor;
        float _NormalStrength;
 
        struct SurfaceOutputPainterly
        {
            fixed3 Albedo;
            fixed3 Normal;
            half3 Emission;
            half Metallic;
            half Smoothness;
            half Occlusion;
            half PainterlyGuide;
            fixed Alpha;
        };
 
        fixed4 LightingPainterly(SurfaceOutputPainterly s, half3 lightDir, half3 viewDir, half atten) {
            half nDotL = saturate(dot(s.Normal, normalize(lightDir)) + 0.2);
            half diff = smoothstep(s.PainterlyGuide - _PainterlySmoothness, s.PainterlyGuide + _PainterlySmoothness, nDotL);

            float3 refl = reflect(normalize(lightDir), s.Normal);
            float vDotRefl = dot(viewDir, -refl);
            float specularThreshold = s.PainterlyGuide + s.Smoothness;
            float3 specular = _SpecularColor * _LightColor0 * smoothstep(specularThreshold - _PainterlySmoothness, specularThreshold + _PainterlySmoothness, vDotRefl) * s.Smoothness;

            atten = smoothstep(s.PainterlyGuide - _PainterlySmoothness, s.PainterlyGuide + _PainterlySmoothness, atten);
            float3 col = (s.Albedo * tex2D(_ShadingGradient, diff).xyz * _LightColor0 + specular) * atten;
            return float4(col, 1);
        }
        
        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputPainterly o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            o.Normal = UnpackNormalWithScale(tex2D(_Normal, IN.uv_MainTex), _NormalStrength);
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.PainterlyGuide = tex2D(_PainterlyGuide, IN.uv_MainTex);
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}