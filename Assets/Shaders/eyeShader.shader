Shader "Hidden/eyeShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_centreH("Fixation Horizontal", float) = 0
		_centreV("Fixation Vertical", float) = 0
    }

	CGINCLUDE
		#include "UnityCG.cginc"
//		#define MVOFF 0
		#define MVOFF 69
		#define CIRCLE 3
		#define STDEV 0.01
		#define TOLDEPTH 0.1
		#define BLURSIZE 0.002
		#define SAMPLES 10
		#define PI 3.14159265359
		#define E 2.71828182846
		sampler2D _MainTex;
		sampler2D _CameraDepthTexture;
		float _centreH;
		float _centreV;
		struct v2f
		{
			float2 uv : TEXCOORD0;
			float2 uv_depth : TEXCOORD1;
		};
		v2f vert(float4 vertex : POSITION, float2 uv : TEXCOORD0, out float4 outpos : SV_POSITION)
		{
			v2f o;
			o.uv = uv;
			outpos = UnityObjectToClipPos(vertex);
			o.uv_depth = uv;
			return o;
		}
		float4 frag(v2f i, UNITY_VPOS_TYPE screenPos : VPOS) : SV_TARGET
		{
			float2 centre = float2((_centreH + (1 - 2 * unity_StereoEyeIndex) * MVOFF), _centreV);
			float2 pix = float2(screenPos.x, screenPos.y);
			float len = distance(centre, pix);
			if (len < CIRCLE)
				return half4(1.0, 0.0, 0.0, 1.0);
//			else
				return tex2D(_MainTex, i.uv);
		}
	ENDCG

    SubShader
    {
		Pass
		{
			ZTest Always
			Cull Off
			ZWrite Off
			CGPROGRAM
			// define vertex and fragment shader
			#pragma vertex vert
			#pragma fragment frag
			ENDCG
		}
    }
}
