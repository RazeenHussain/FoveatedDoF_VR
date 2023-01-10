Shader "Hidden/depthShader"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_eyeX("Eye Coordinate X", float) = 0
		_eyeY("Eye Coordinate Y", float) = 0
	}

	HLSLINCLUDE
		#include "UnityCG.cginc"

		sampler2D _MainTex, _CameraDepthTexture, _CoCTex, _DoFTex;
		float4 _MainTex_TexelSize;

		float _FocusDistance, _FocusRange, _BokehRadius;

		struct VertexData 
		{
			float4 vertex : POSITION;
			float2 uv : TEXCOORD0;
//			float2 uvD : TEXCOORD1;
		};

		struct Interpolators 
		{
			float4 pos : SV_POSITION;
			float2 uv : TEXCOORD0;
//			float2 uvD : TEXCOORD1;
		};

		Interpolators VertexProgram(VertexData v) 
		{
			Interpolators i;
			i.pos = UnityObjectToClipPos(v.vertex);
			i.uv = v.uv;
//			i.uvD = v.uv;
			return i;
		}

	ENDHLSL

	SubShader
	{
		Cull Off
		ZTest Always
		ZWrite Off

		Pass // 0 circleOfConfusionPass
		{
			HLSLPROGRAM
				#pragma vertex VertexProgram
				#pragma fragment FragmentProgram

				half FragmentProgram(Interpolators i) : SV_Target 
				{
					half depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
					depth = LinearEyeDepth(depth);
//					return depth;
					half coc = (depth - _FocusDistance) / _FocusRange;
					coc = clamp(coc, -1, 1) * _BokehRadius;
					return coc; 
				}
			ENDHLSL
		}

		Pass // 1 preFilterPass
		{ 
			HLSLPROGRAM
				#pragma vertex VertexProgram
				#pragma fragment FragmentProgram
				
				half Weigh(half3 c) 
				{
					return 1 / (1 + max(max(c.r, c.g), c.b));
				}

				half4 FragmentProgram(Interpolators i) : SV_Target 
				{
					float4 o = _MainTex_TexelSize.xyxy * float2(-0.5, 0.5).xxyy;
					
					half3 s0 = tex2D(_MainTex, i.uv + o.xy).rgb;
					half3 s1 = tex2D(_MainTex, i.uv + o.zy).rgb;
					half3 s2 = tex2D(_MainTex, i.uv + o.xw).rgb;
					half3 s3 = tex2D(_MainTex, i.uv + o.zw).rgb;

					half w0 = Weigh(s0);
					half w1 = Weigh(s1);
					half w2 = Weigh(s2);
					half w3 = Weigh(s3);

					half3 color = s0 * w0 + s1 * w1 + s2 * w2 + s3 * w3;
					color /= max(w0 + w1 + w2 + s3, 0.00001);
					
					half coc0 = tex2D(_CoCTex, i.uv + o.xy).r;
					half coc1 = tex2D(_CoCTex, i.uv + o.zy).r;
					half coc2 = tex2D(_CoCTex, i.uv + o.xw).r;
					half coc3 = tex2D(_CoCTex, i.uv + o.zw).r;

					half cocMin = min(min(min(coc0, coc1), coc2), coc3);
					half cocMax = max(max(max(coc0, coc1), coc2), coc3);
					half coc = cocMax >= -cocMin ? cocMax : cocMin;

					return half4(color, coc); 
				}
			ENDHLSL
		}

		Pass // 2 bokehPass 
		{ 
			HLSLPROGRAM
				#pragma vertex VertexProgram
				#pragma fragment FragmentProgram

				static const int kernelSampleCount = 16;
				static const float2 kernel[kernelSampleCount] = {
					float2(0, 0),
					float2(0.54545456, 0),
					float2(0.16855472, 0.5187581),
					float2(-0.44128203, 0.3206101),
					float2(-0.44128197, -0.3206102),
					float2(0.1685548, -0.5187581),
					float2(1, 0),
					float2(0.809017, 0.58778524),
					float2(0.30901697, 0.95105654),
					float2(-0.30901703, 0.9510565),
					float2(-0.80901706, 0.5877852),
					float2(-1, 0),
					float2(-0.80901694, -0.58778536),
					float2(-0.30901664, -0.9510566),
					float2(0.30901712, -0.9510565),
					float2(0.80901694, -0.5877853),
				};

				half Weigh(half coc, half radius) 
				{
					return saturate((coc - radius + 2) / 2);
				}

				half4 FragmentProgram(Interpolators i) : SV_Target 
				{
					half coc = tex2D(_MainTex, i.uv).a;

					half3 bgColor = 0, fgColor = 0;
					half bgWeight = 0, fgWeight = 0;
					for (int k = 0; k < kernelSampleCount; k++) 
					{
						float2 o = kernel[k] * _BokehRadius;
						half radius = length(o);
						o *= _MainTex_TexelSize.xy;
						half4 s = tex2D(_MainTex, i.uv + o);
						half bgw = Weigh(max(0, min(s.a, coc)), radius);
						bgColor += s.rgb * bgw;
						bgWeight += bgw;
						half fgw = Weigh(-s.a, radius);
						fgColor += s.rgb * fgw;
						fgWeight += fgw;
					}
					bgColor *= 1 / (bgWeight + (bgWeight == 0));
					fgColor *= 1 / (fgWeight + (fgWeight == 0));
					half bgfg = min(1, fgWeight * 3.14159265359 / kernelSampleCount);
					half3 color = lerp(bgColor, fgColor, bgfg);
					return half4(color, bgfg);
				}
			ENDHLSL
		}

		Pass // 3 postFilterPass 
		{ 
			HLSLPROGRAM
				#pragma vertex VertexProgram
				#pragma fragment FragmentProgram

				half4 FragmentProgram(Interpolators i) : SV_Target 
				{
					float4 o = _MainTex_TexelSize.xyxy * float2(-0.5, 0.5).xxyy;
					half4 s = tex2D(_MainTex, i.uv + o.xy) + tex2D(_MainTex, i.uv + o.zy) + tex2D(_MainTex, i.uv + o.xw) + tex2D(_MainTex, i.uv + o.zw);
					return s * 0.25;
				}
			ENDHLSL
		}

		Pass // 4 combinePass
		{ 
			HLSLPROGRAM
				#pragma vertex VertexProgram
				#pragma fragment FragmentProgram

				half4 FragmentProgram(Interpolators i) : SV_Target 
				{
					half4 source = tex2D(_MainTex, i.uv);
					half coc = tex2D(_CoCTex, i.uv).r;
					half4 dof = tex2D(_DoFTex, i.uv);
					half dofStrength = smoothstep(0.1, 1, abs(coc));
					half3 color = lerp(source.rgb, dof.rgb, dofStrength + dof.a - dofStrength * dof.a);
					return half4(color, source.a);
				}
			ENDHLSL
		}
	}
}
