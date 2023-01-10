Shader "Hidden/shaderLeft"
{
	// values that appear in the inspector
	Properties
	{
		[HideInInspector]_MainTex("Texture", 2D) = "white" {}
		_BlurSize("Blur Size", Range(0,0.1)) = 0
		_StDev("Standard Deviation", Range(0,0.1)) = 0.03
		_StDev2("Standard Deviation 2", Range(0,0.1)) = 0.03
		_Gauss("Gaussian Blur", float) = 0
		_Radius("Radius", float) = 0
		_Radius2("Radius 2", float) = 0
		_ViewDepth("View Depth", float) = 0
	}

	CGINCLUDE
// Upgrade NOTE: excluded shader from DX11, OpenGL ES 2.0 because it uses unsized arrays
//#pragma exclude_renderers d3d11 gles
		#include "UnityCG.cginc"
		#define SAMPLES 10 // mask size
		#define PI 3.14159265359
		#define E 2.71828182846
		#define mvOff 69
		#define tolDepth 0.05
		sampler2D _MainTex;
		sampler2D _CameraDepthTexture;
		float _BlurSize;
		float _StDev;
		float _StDev2;
		float _Gauss;
		float _Radius;
		float _Radius2;
		float _ViewDepth;
		// data structure for the fragment shader
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
		// fragment shader vertical
		float4 fragVert(v2f i, UNITY_VPOS_TYPE screenPos : VPOS) : SV_TARGET
		{
			// get the raw Depth relative to the camera
			float rawDepth = DecodeFloatRG(tex2D(_CameraDepthTexture, i.uv_depth));
			// normalize this between 0 .. 1 where 0 is at the near clipping plane and 1 at the far clipping plane
			float linDepth = Linear01Depth(rawDepth);
			float depth = linDepth * _ProjectionParams.z * 0.1;
//			return depth;
			if ((depth > (_ViewDepth-tolDepth)) && (depth < (_ViewDepth + tolDepth)))
				return tex2D(_MainTex, i.uv);
			else
			{
				float sDev = 0;
				sDev = _StDev;
//				float2 centre = float2(((_ScreenParams.x / 2) + mvOff), ((_ScreenParams.y / 2)));
//				float2 pix = float2(screenPos.x, screenPos.y);
//				float len = distance(centre, pix);
//				if (len <= _Radius)
//					return tex2D(_MainTex, i.uv);
//				else if ((len > _Radius) && (len <= _Radius2))
//					sDev = _StDev;
//				else
//					sDev = _StDev2;
				// avoid NaN condition
				if (_Gauss == 1)
					if (_StDev == 0)
						return tex2D(_MainTex, i.uv);
				float4 col = 0;
				float sum = 0;
				// selection between box blur and gaussian blur
				if (_Gauss == 1)
					sum = 0;
				else
					sum = SAMPLES;
				// iterate over samples
				for (float index = 0; index < SAMPLES; index++)
				{
					float offset = (index / (SAMPLES - 1) - 0.5) * _BlurSize;
					float2 uv = i.uv + float2(0, offset);
					// box blur
					if (_Gauss == 0)
						col += tex2D(_MainTex, uv);
					// gaussian blur
					else
					{
						float StDevSq = sDev * sDev;
						float gaussian = (1 / sqrt(2 * PI * StDevSq)) * pow(E, -((offset*offset) / (2 * StDevSq)));
						sum += gaussian;
						col += tex2D(_MainTex, uv) * gaussian;
					}
				}
				col = col / sum;
				return col;
			}
		}
			// fragment shader horizontal
		float4 fragHor(v2f i, UNITY_VPOS_TYPE screenPos : VPOS) : SV_TARGET
		{
			// get the raw Depth relative to the camera
			float rawDepth = DecodeFloatRG(tex2D(_CameraDepthTexture, i.uv_depth));
			// normalize this between 0 .. 1 where 0 is at the near clipping plane and 1 at the far clipping plane
			float linDepth = Linear01Depth(rawDepth);
			float depth = linDepth * _ProjectionParams.z * 0.1;
//			return depth;

			if ((depth > (_ViewDepth - tolDepth)) && (depth < (_ViewDepth + tolDepth)))
				return tex2D(_MainTex, i.uv);
			else
//				return depth;
			{

			float sDev = 0;
			sDev = _StDev;
//			float2 centre = float2(((_ScreenParams.x / 2) + mvOff), ((_ScreenParams.y / 2)));
//			float2 pix = float2(screenPos.x, screenPos.y);
//			float len = distance(centre, pix);
//			if (len < _Radius)
//				return tex2D(_MainTex, i.uv);
//			else if ((len > _Radius) && (len <= _Radius2))
//				sDev = _StDev;
//			else
//				sDev = _StDev2;
			// avoid NaN condition
			if (_Gauss == 1)
				if (_StDev == 0)
					return tex2D(_MainTex, i.uv);
			float aspectRatio = _ScreenParams.y / _ScreenParams.x;
			float4 col = 0;
			float sum = 0;
			// selection between box blur and gaussian blur
			if (_Gauss == 1)
				sum = 0;
			else
				sum = SAMPLES;
			// iterate over samples
			for (float index = 0; index < SAMPLES; index++)
			{
				float offset = (index / (SAMPLES - 1) - 0.5) * _BlurSize * aspectRatio;
				float2 uv = i.uv + float2(offset, 0);
				// box blur
				if (_Gauss == 0)
					col += tex2D(_MainTex, uv);
				// gaussian blur
				else
				{
					float StDevSq = sDev * sDev;
					float gaussian = (1 / sqrt(2 * PI * StDevSq)) * pow(E, -((offset*offset) / (2 * StDevSq)));
					sum += gaussian;
					col += tex2D(_MainTex, uv) * gaussian;
				}
			}
			col = col / sum;
			return col;
			}
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
			CGPROGRAM
			// define vertex and fragment shader
			#pragma vertex vert
			#pragma fragment fragHor
			ENDCG
		}
	}
}
