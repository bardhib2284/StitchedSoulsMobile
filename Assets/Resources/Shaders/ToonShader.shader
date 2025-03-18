Shader "Custom/ToonShader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _Ramp ("Ramp Texture", 2D) = "gray" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        CGPROGRAM
        #pragma surface surf Lambert

        sampler2D _MainTex;
        sampler2D _Ramp;
        fixed4 _Color;

        struct Input
        {
            float2 uv_MainTex;
            float3 worldNormal;
            float3 worldPos;
        };

        void surf (Input IN, inout SurfaceOutput o)
        {
            fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
            fixed lightIntensity = dot(IN.worldNormal, normalize(_WorldSpaceLightPos0.xyz));
            fixed shadow = tex2D(_Ramp, float2(lightIntensity, 0.5)).r;
            o.Albedo = c.rgb * shadow;
        }
        ENDCG
    }
}
