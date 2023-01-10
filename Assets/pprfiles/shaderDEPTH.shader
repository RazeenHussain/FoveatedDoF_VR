Shader "Hidden/shaderDEPTH"
{
	// values that appear in the inspector
	Properties
	{
		[HideInInspector]_MainTex("Texture", 2D) = "white" {}
		_Switch("Blur Size", Range(0,1)) = 1
		_BlurSize("Blur Size", Range(0,0.1)) = 0
		_StDev("Standard Deviation", Range(0,0.1)) = 0.03
		_BlurSize2("Blur Size 2", Range(0,0.1)) = 0
		_Radius("Radius", float) = 0
		_StDev2("Standard Deviation 2", Range(0,0.1)) = 0.03
		_Radius2("Radius 2", float) = 0
		_ViewDepth("View Depth", float) = 0.2
		_centreH("Fixation Horizontal", float) = 0
		_centreV("Fixation Vertical", float) = 0
	}

	CGINCLUDE
		#include "UnityCG.cginc"
		#define SAMPLES 7 // mask size
		#define PI 3.14159265359
		#define E 2.71828182846
		#define mvOff 0
//		#define mvOff 69
//		#define tolDepth 0.03
		#define tolDepth 0.06
		#define circle 3
		sampler2D _MainTex;
		sampler2D _CameraDepthTexture;
		float _Switch;
		float _BlurSize;
		float _BlurSize2;
		float _StDev;
		float _StDev2;
		float _Radius;
		float _Radius2;
		float _ViewDepth;
		float _centreH;
		float _centreV;
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
			// avoid NaN condition
			if (_StDev == 0)
				return tex2D(_MainTex, i.uv);
			// get the raw Depth relative to the camera
			float rawDepth = DecodeFloatRG(tex2D(_CameraDepthTexture, i.uv_depth));
			// normalize this between 0 .. 1 where 0 is at the near clipping plane and 1 at the far clipping plane
			float linDepth = Linear01Depth(rawDepth);
			float depth = linDepth * _ProjectionParams.z * 0.1;
//			return depth;
			float2 centre = float2((_centreH + mvOff), _centreV);
			if (unity_StereoEyeIndex == 1)
				centre = float2((_centreH - mvOff), _centreV);
			float2 pix = float2(screenPos.x, screenPos.y);
			float len = distance(centre, pix);
			if (_Switch != 1)
				return tex2D(_MainTex, i.uv);
			float2 screenUV = float2((centre.x / _ScreenParams.x),(centre.y / _ScreenParams.y));
			float rawDepth0 = DecodeFloatRG(tex2D(_CameraDepthTexture, screenUV));
			float linDepth0 = Linear01Depth(rawDepth0);
			float depth0 = linDepth0 * _ProjectionParams.z * 0.1;
			if (((depth > (depth0 - tolDepth)) && (depth < (depth0 + tolDepth))))
				return tex2D(_MainTex, i.uv);
			else
			{
				float sDev = 0;
				float bSize = 0;
				sDev = _StDev;
				sDev = _StDev * abs((1/depth0)-(1/depth));
				bSize = _BlurSize;

				float4 col1 = tex2D(_MainTex, i.uv);
				float4 col2 = 0;
				float sum2 = 0;
				// iterate over samples
				for (float index = 0; index < SAMPLES; index++)
				{
					float offset = (index / (SAMPLES - 1) - 0.5) *bSize;
					float2 uv = i.uv + float2(offset, 0);
					float StDevSq = sDev * sDev;
					float gaussian = (1 / sqrt(2 * PI * StDevSq)) * pow(E, -((offset*offset) / (2 * StDevSq)));
					sum2 += gaussian;
					col2 += tex2D(_MainTex, uv) * gaussian;
				}
				col2 = col2 / sum2;
				return col2;

			}
		}
		// fragment shader horizontal
		float4 fragHor(v2f i, UNITY_VPOS_TYPE screenPos : VPOS) : SV_TARGET
		{
			// avoid NaN condition
			if (_StDev == 0)
				return tex2D(_MainTex, i.uv);
			// get the raw Depth relative to the camera
			float rawDepth = DecodeFloatRG(tex2D(_CameraDepthTexture, i.uv_depth));
			// normalize this between 0 .. 1 where 0 is at the near clipping plane and 1 at the far clipping plane
			float linDepth = Linear01Depth(rawDepth);
			float depth = linDepth * _ProjectionParams.z * 0.1;
//			return depth;
			float2 centre = float2((_centreH + mvOff), _centreV);
			if (unity_StereoEyeIndex == 1)
				centre = float2((_centreH - mvOff), _centreV);
			float2 pix = float2(screenPos.x, screenPos.y);
			float len = distance(centre, pix);
			if (_Switch != 1)
				return tex2D(_MainTex, i.uv);
			float2 screenUV = float2((centre.x / _ScreenParams.x), (centre.y / _ScreenParams.y));
			float rawDepth0 = DecodeFloatRG(tex2D(_CameraDepthTexture, screenUV));
			float linDepth0 = Linear01Depth(rawDepth0);
			float depth0 = linDepth0 * _ProjectionParams.z * 0.1;
			if (((depth > (depth0 - tolDepth)) && (depth < (depth0 + tolDepth))))
				return tex2D(_MainTex, i.uv);
			else
			{
				float sDev = 0;
				float bSize = 0;
				sDev = _StDev;
				sDev = _StDev * abs((1 / depth0) - (1 / depth));
				bSize = _BlurSize;
				float aspectRatio = _ScreenParams.y / _ScreenParams.x;

				float4 col1 = tex2D(_MainTex, i.uv);
				float4 col2 = 0;
				float sum2 = 0;
				// iterate over samples
				for (float index = 0; index < SAMPLES; index++)
				{
					float offset = (index / (SAMPLES - 1) - 0.5) *bSize * aspectRatio;
					float2 uv = i.uv + float2(offset, 0);
					float StDevSq = sDev * sDev;
					float gaussian = (1 / sqrt(2 * PI * StDevSq)) * pow(E, -((offset*offset) / (2 * StDevSq)));
					sum2 += gaussian;
					col2 += tex2D(_MainTex, uv) * gaussian;
				}
				col2 = col2 / sum2;
				return col2;
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
