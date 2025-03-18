Shader "Custom/FabricShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _StitchMap ("Stitch Pattern", 2D) = "black" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        CGPROGRAM
        #pragma surface surf Lambert

        sampler2D _MainTex;
        sampler2D _StitchMap;

        struct Input
        {
            float2 uv_MainTex;
        };

        void surf (Input IN, inout SurfaceOutput o)
        {
            fixed4 c = tex2D(_MainTex, IN.uv_MainTex);
            float stitches = tex2D(_StitchMap, IN.uv_MainTex).r;
            o.Albedo = c.rgb * (1 - stitches * 0.5); // Darkens fabric where stitches appear
        }
        ENDCG
    }
}
