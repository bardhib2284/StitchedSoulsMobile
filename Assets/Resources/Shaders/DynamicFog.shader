Shader "Custom/DynamicFog"
{
    Properties
    {
        _FogColor ("Fog Color", Color) = (0.1, 0.1, 0.1, 1)  // Dark eerie fog
        _FogDensity ("Fog Density", Range(0,1)) = 0.2        // Controls thickness
        _NoiseSpeed ("Noise Speed", Range(0, 5)) = 0.5       // Controls swirl speed
        _NoiseScale ("Noise Scale", Range(0,10)) = 2         // Controls fog pattern
        _NoiseTex ("Noise Texture", 2D) = "white" {}         // NEW: Noise texture property
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha
        CGPROGRAM
        #pragma surface surf Lambert alpha

        fixed4 _FogColor;
        float _FogDensity;
        float _NoiseSpeed;
        float _NoiseScale;
        sampler2D _NoiseTex;  // NEW: Noise texture sampler

        struct Input
        {
            float3 worldPos;
            float2 uv_Noise;
        };

        void surf (Input IN, inout SurfaceOutput o)
        {
            // Compute fog intensity based on distance (farther = more fog)
            float distanceFactor = saturate(distance(IN.worldPos, _WorldSpaceCameraPos) * _FogDensity);

            // Swirling fog animation using noise texture
            float2 noiseUV = IN.uv_Noise * _NoiseScale + _Time.y * _NoiseSpeed; // NEW: Apply movement
            float noise = tex2D(_NoiseTex, noiseUV).r; // Get noise value from texture
            noise = smoothstep(0.3, 0.7, noise); // Soft transition

            // Blend fog color based on depth & noise
            float fogFactor = distanceFactor * noise;
            o.Emission = lerp(o.Albedo, _FogColor.rgb, fogFactor);
            o.Alpha = fogFactor; // Makes fog fade out
        }
        ENDCG
    }
}
