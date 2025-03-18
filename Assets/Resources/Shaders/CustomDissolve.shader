Shader "Custom/Dissolve"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _DissolveTex ("Dissolve Texture", 2D) = "white" {}
        _DissolveAmount ("Dissolve Amount", Range(0,1)) = 0.5
        _EdgeColor ("Edge Color", Color) = (1,0,0,1)
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" }
        CGPROGRAM
        #pragma surface surf Lambert alpha

        sampler2D _MainTex;
        sampler2D _DissolveTex;
        fixed4 _EdgeColor;
        float _DissolveAmount;

        struct Input
        {
            float2 uv_MainTex;
        };

        void surf (Input IN, inout SurfaceOutput o)
        {
            fixed4 c = tex2D(_MainTex, IN.uv_MainTex);
            float dissolveValue = tex2D(_DissolveTex, IN.uv_MainTex).r;
            clip(dissolveValue - _DissolveAmount); // Clips pixels based on dissolve map
            if (dissolveValue < _DissolveAmount + 0.1)
                o.Emission = _EdgeColor.rgb; // Adds glowing edges before disappearing
            o.Albedo = c.rgb;
        }
        ENDCG
    }
}
