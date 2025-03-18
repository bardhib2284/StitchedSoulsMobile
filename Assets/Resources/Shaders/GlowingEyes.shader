Shader "Custom/GlowingEyes"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _GlowColor ("Glow Color", Color) = (1,1,0,1)
        _GlowStrength ("Glow Strength", Range(0,10)) = 2
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" }
        CGPROGRAM
        #pragma surface surf Lambert

        sampler2D _MainTex;
        fixed4 _GlowColor;
        float _GlowStrength;

        struct Input
        {
            float2 uv_MainTex;
            float3 worldPos;
        };

        void surf (Input IN, inout SurfaceOutput o)
        {
            fixed4 c = tex2D(_MainTex, IN.uv_MainTex);
            float glowFactor = step(0.5, c.a); // Assume the eyes have alpha > 0.5
            o.Emission = _GlowColor.rgb * _GlowStrength * glowFactor;
            o.Albedo = c.rgb * (1 - glowFactor);
        }
        ENDCG
    }
}
