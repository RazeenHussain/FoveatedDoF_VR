Shader "Hidden/blurShader"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_centreH("Fixation Horizontal", float) = 0
		_centreV("Fixation Vertical", float) = 0
		_clip("Clipping", float) = 0
	}

	CGINCLUDE
		#include "UnityCG.cginc"
		#define MVOFF 69
		#define CIRCLE 5
		#define STDEV 0.015
		#define TOLDEPTH 0.1
		#define BLURSIZE 0.006
		#define SAMPLES 15
		#define PI 3.14159265359
		#define E 2.71828182846
		#define RADIUS1 65
		#define RADIUS2 120
		sampler2D _MainTex;
		sampler2D _CameraDepthTexture;
		float _centreH;
		float _centreV;
		float _clip;
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
		float4 fragVert(v2f i, UNITY_VPOS_TYPE screenPos : VPOS) : SV_TARGET
		{
			float2 centre = float2((_centreH + (1 - 2 * unity_StereoEyeIndex) * MVOFF), _centreV);
			float2 pix = float2(screenPos.x, screenPos.y);
			float len = distance(centre, pix);
//			if (len < CIRCLE)
//				return half4(1.0, 0.0, 0.0, 1.0);
			float rawDepth = DecodeFloatRG(tex2D(_CameraDepthTexture, i.uv_depth));
			float linDepth = Linear01Depth(rawDepth);
			float depth = linDepth * _ProjectionParams.z * 0.1;

			float2 screenUV = float2((centre.x / _ScreenParams.x), (centre.y / _ScreenParams.y));
			float viewRawDepth = DecodeFloatRG(tex2D(_CameraDepthTexture, screenUV));
			float viewLinDepth = Linear01Depth(viewRawDepth);
			float viewDepth = viewLinDepth * _ProjectionParams.z * 0.1;
//			float foveal = (((depth > (viewDepth - TOLDEPTH)) && (depth < (viewDepth + TOLDEPTH))) || (len <= RADIUS1));
			if (((depth > (viewDepth - TOLDEPTH)) && (depth < (viewDepth + TOLDEPTH))) || (len <= RADIUS1))
				return tex2D(_MainTex, i.uv);
			clip(0.5f - (((((screenPos.x % 2) <= 0.9f) && ((screenPos.y % 2) > 0.9f)) || (((screenPos.x % 2) > 0.9f) && ((screenPos.y % 2) <= 0.9f))) && (_clip == 1.0f)));
			float4 colOrig = tex2D(_MainTex, i.uv);
			float4 col = 0;
			float sum = 0;
			float sDev = STDEV * abs((1 / viewDepth) - (1 / depth));
			float StDevSq = sDev * sDev;
			for (float index = 0; index < SAMPLES; index++)
			{
				float offset = (index / (SAMPLES - 1) - 0.5) * BLURSIZE;
				float2 uv = i.uv + float2(0, offset);
				float gaussian = (1 / sqrt(2 * PI * StDevSq)) * pow(E, -((offset*offset) / (2 * StDevSq)));
				sum += gaussian;
				col += tex2D(_MainTex, uv) * gaussian;
			}
			col = col / sum;
			float Blend = max(min((len - RADIUS1) / (RADIUS2 - RADIUS1), 1), 0);
//			float4 blurred = Blend * col + (1 - Blend)*colOrig;
//			return (colOrig*foveal + (1 - foveal)*blurred);
			return (Blend*col + (1 - Blend)*colOrig);
		}
		// fragment shader horizontal
		float4 fragHor(v2f i, UNITY_VPOS_TYPE screenPos : VPOS) : SV_TARGET
		{
			float2 centre = float2((_centreH + (1 - 2 * unity_StereoEyeIndex) * MVOFF), _centreV);
			float2 pix = float2(screenPos.x, screenPos.y);
			float len = distance(centre, pix);
//			if (len < CIRCLE)
//				return half4(1.0, 0.0, 0.0, 1.0);
			float rawDepth = DecodeFloatRG(tex2D(_CameraDepthTexture, i.uv_depth));
			float linDepth = Linear01Depth(rawDepth);
			float depth = linDepth * _ProjectionParams.z * 0.1;

			float2 screenUV = float2((centre.x / _ScreenParams.x), (centre.y / _ScreenParams.y));
			float viewRawDepth = DecodeFloatRG(tex2D(_CameraDepthTexture, screenUV));
			float viewLinDepth = Linear01Depth(viewRawDepth);
			float viewDepth = viewLinDepth * _ProjectionParams.z * 0.1;

//			float foveal = (((depth > (viewDepth - TOLDEPTH)) && (depth < (viewDepth + TOLDEPTH))) || (len <= RADIUS1));
			if (((depth > (viewDepth - TOLDEPTH)) && (depth < (viewDepth + TOLDEPTH))) || (len <= RADIUS1))
				return tex2D(_MainTex, i.uv);
			clip(0.5f-(((((screenPos.x % 2) <= 0.9f) && ((screenPos.y % 2) > 0.9f)) || (((screenPos.x % 2) > 0.9f) && ((screenPos.y % 2) <= 0.9f))) && (_clip == 1.0f)));
			float4 colOrig = tex2D(_MainTex, i.uv);
			float4 col = 0;
			float sum = 0;
			float sDev = STDEV * abs((1 / viewDepth) - (1 / depth));
			float StDevSq = sDev * sDev;
			float aspectRatio = _ScreenParams.y / _ScreenParams.x;
			for (float index = 0; index < SAMPLES; index++)
			{
				float offset = (index / (SAMPLES - 1) - 0.5) * BLURSIZE * aspectRatio;
				float2 uv = i.uv + float2(0, offset);
				float gaussian = (1 / sqrt(2 * PI * StDevSq)) * pow(E, -((offset*offset) / (2 * StDevSq)));
				sum += gaussian;
				col += tex2D(_MainTex, uv) * gaussian;
			}
			col = col / sum;
			float Blend = max(min((len - RADIUS1) / (RADIUS2 - RADIUS1), 1), 0);
//			float4 blurred = Blend * col + (1 - Blend)*colOrig;
//			return (saturate(colOrig*foveal + (1 - foveal)*blurred));
			return (Blend*col + (1 - Blend)*colOrig);
		}
	ENDCG

	SubShader
	{
		// VERTICAL PASS
		Pass
		{
			ZTest Always
			Cull Off
			ZWrite Off
			Fog { Mode off }
			Blend Off
			CGPROGRAM
				// define vertex and fragment shader
				#pragma vertex vert
				#pragma fragment fragVert
			ENDCG
		}
		// HORIZONTAL PASS
		Pass
		{
			ZTest Always
			Cull Off
			ZWrite Off
			Fog { Mode off }
			Blend Off
			CGPROGRAM
				// define vertex and fragment shader
				#pragma vertex vert
				#pragma fragment fragHor
			ENDCG
		}
	}
}
