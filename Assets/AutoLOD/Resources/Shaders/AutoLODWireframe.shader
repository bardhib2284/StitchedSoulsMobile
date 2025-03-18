CGINCLUDE
#include "UnityCG.cginc"

struct v2g
{
    float4 vertex : POSITION;
};

struct g2f
{
    float4 vertex : SV_POSITION;
    float visibility : TEXCOORD0;
};


half4 _Color;
float _Opacity;

v2g vert(v2g v) { return v; }

g2f getg2f(v2g v)
{
    g2f o;
    o.vertex = UnityObjectToClipPos(v.vertex);
    o.visibility = _Opacity*0.5;
    return o;
}

half4 frag(g2f i) : SV_Target
{
    return half4(_Color.rgb , _Color.a * i.visibility);
}
ENDCG

Shader "AutoLOD/Wireframe"
{
    Properties
    {
        [Header(RGB)]
        _Color("Color", Color) = (1,1,1,1)

        [Header(Alpha)]
        _Opacity("Opacity", Range(0.0,1.0)) = 0.15

    }

        SubShader
        {
            Tags { "RenderType" = "Opaque" "Queue" = "Geometry+5" }
            Blend SrcAlpha OneMinusSrcAlpha
            ZTest LEqual
            ZWrite Off
            Cull Off

            Pass
            {
                Name "LINES"
                CGPROGRAM
                #pragma vertex vert
                #pragma geometry geom
                #pragma fragment frag

                [maxvertexcount(32)]
                void geom(triangle v2g v[3] , uint pid : SV_PRIMITIVEID , inout LineStream<g2f> stream)
                {
                    g2f g0 = getg2f(v[0]);
                    g2f g1 = getg2f(v[1]);
                    g2f g2 = getg2f(v[2]);


                    stream.Append(g0);
                    stream.Append(g1);
                    stream.Append(g2);
                    stream.Append(g0);
                    stream.RestartStrip();


                    stream.Append(g0);
                    stream.RestartStrip();
                    stream.Append(g1);
                    stream.RestartStrip();
                    stream.Append(g2);
                    stream.RestartStrip();
                }
                ENDCG
            }
        }
}