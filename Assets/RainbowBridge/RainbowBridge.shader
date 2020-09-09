////////////////////////
/////RainbowBridge//////
///////2019.5.7/////////
////////////////////////
Shader "SoFunny/SPToon/RainbowBridge"
{
	Properties
	{
		[Header(MainToon)]
		_MainTex ("主贴图 Main Tex", 2D) = "white" {}
		_MainTexChangingFrequency("主贴图变化频率 _MainTexChangingFrequency",Range(0,5))=1
		_MainTexChangingStrength("主贴图变化强度 _MainTexChangingStrength",Range(0,1))=0.2
		_MainTexEmissionStrength("主贴图自发光强度 _MainTexEmissionStrength",Range(0,1))=0.2
		_MainTexStrength("主贴图整体强度 _MainTexStrength",Range(0,2))=1.25
		_MainTexRange("主贴图范围 _MainTexRange",Range(0,20))=5
		_SecTex ("副贴图 Sec Tex", 2D) = "black" {}
		_SecTexStrength("副贴图整体强度 _MainTexStrength",Range(0,1))=0.25
		_SecTexSpeed("副贴图速度 _SecTexSpeed",Range(-5,5))=1
		_ThirdTex ("第三贴图 Third Tex", 2D) = "black" {}
		_ThirdTexStrength("第三贴图整体强度 _ThirdTexStrength",Range(0,1))=0.5
		_ThirdTexSpeed("第三贴图速度 _ThirdTexSpeed",Range(-5,5))=-1
		[Space(10)]
		_Color ("主颜色 Color", Color) = (1, 1, 1, 1)
		_EmissionColor ("自发光色 Emission Color", Color) = (0, 0, 0, 1)
		_HighlightColor("亮部色 Highlight Color",Color)=(1.0,1.0,1.0,1)
    	_ShadowColor("暗部色 Shadow Color",Color)=(0.6,0.6,0.6,1)
    	[Space(10)]
    	_LightThreshold("亮暗部阈值 Light Threshold",Range(-1,1))=0.65
    	_ShadowIntensity("阴影强度 Shadow Intensity",Range(0,3))=1.0
    	_TransitionIntensity("过渡强度 Transition Intensity",Range(0,3))=0.2

    	[Header(Ambient)]
		[Toggle(USE_AMBIENTLIGHT)] _UseAmbientLight("计算环境光 Use Ambient Light",Float)=1
    	_MainAmbientSensitivity("主环境光敏感度 Main Ambient Sensitivity", Range(0,1)) = 0.4
		[Toggle(USE_FOG)] _UseFog("使用雾效 Use Fog",Float)=0

    	// [Header(AlphaClip)]
		// [Toggle(ALPHACLIP)] _AlphaClip("开启透明度裁剪 AlphaClip",Float)=0
    	// _AlphaClipThreshold("透明度裁剪阈值 AlphaClip Threshold",Range(0,1))=0.5

    	[Header(Rim)]
    	[Toggle(DRAW_RIM)] _Rim("开启边缘光 Draw Rim",Float)=0
    	_RimColor ("边缘光颜色 Rim Color", Color) = (0.5,0.5,0.5,0.5)
		_FPower("幂 FPower Fresnel", Range(0,10)) = 4.0
    	_F0("反射系数 F0 Fresnel", Float) = 0.05

    	// [Header(LightMap)]
    	// _LightmapIntensity("光照贴图强度 Lightmap Intensity",Range(-2,2))=0.5
		// _LightmapAdd("光照贴图增益 Lightmap Add",Range(-2,2))=0.5

	}
	SubShader
	{
		Tags{"RenderType"="Transparent" "Queue"="Transparent"}
		Pass
		{
			Blend SrcAlpha OneMinusSrcAlpha
			NAME "SPToonExpression"
			Tags {"LightMode"="ForwardBase"}
			LOD 100
			CGPROGRAM
			#pragma multi_compile_fog
            #pragma multi_compile __ USE_FOG
			// #pragma multi_compile __ LIGHTMAP_ON
			#pragma multi_compile __ DRAW_RIM
			// #pragma multi_compile __ ALPHACLIP
			#pragma multi_compile __ USE_AMBIENTLIGHT
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			#include "UnityCG.cginc"
			#include "Lighting.cginc"

			sampler2D _MainTex;
			half4 _MainTex_ST;
			half4 _MainTex_TexelSize;
			sampler2D _SecTex;
			half4 _SecTex_ST;
			half4 _SecTex_TexelSize;
			sampler2D _ThirdTex;
			half4 _ThirdTex_ST;
			half4 _ThirdTex_TexelSize;

			half _MainTexChangingFrequency;
			half _MainTexChangingStrength;
			half _MainTexEmissionStrength;
			half _MainTexStrength;
			half _MainTexRange;
			half _SecTexStrength;
			half _SecTexSpeed;
			half _ThirdTexStrength;
			half _ThirdTexSpeed;

			half _OutlineThreshold;
			half _LightThreshold;
			half _SampleDistance;
    		fixed4 _EdgeColor;
    		fixed4 _BackgroundColor;
    		half _NThreshold;
    		half _ZThreshold;
    		fixed4 _Color;
    		// half _LightmapIntensity;
    		// half _LightmapAdd;

    		fixed4 _HighlightColor;
    		fixed4 _ShadowColor;
    		half _HighlightIntensity;
    		half _ShadowIntensity;
    		half _TransitionIntensity;

    		// fixed _AlphaClipThreshold;

    		fixed4 _EmissionColor;

    		fixed4 _RimColor;
			half _FPower;
			half _F0;

			fixed _MainAmbientSensitivity;

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				half3 normal:NORMAL;
				float2 uv_MainTex : TEXCOORD1;
				float4 screenPos : TEXCOORD2;
				fixed4 color : COLOR;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				float2 uv_MainTex : TEXCOORD1;
				float2 uv_SecTex : TEXCOORD2;
				float2 uv_ThirdTex : TEXCOORD3;
				float4 screenPos:TEXCOORD4;
				float3 worldNormal:TEXCOORD5;
				float3 worldPos:TEXCOORD6;
				fixed4 color : COLOR;
				// float2 lightMap:TEXCOORD7;
				#if USE_FOG
                UNITY_FOG_COORDS(7)
                #endif
			};

			v2f vert (appdata v)
			{
				
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f,o);
				o.vertex = UnityObjectToClipPos(v.vertex);

				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.uv_SecTex = TRANSFORM_TEX(v.uv, _SecTex);
				o.uv_ThirdTex = TRANSFORM_TEX(v.uv, _ThirdTex);

				//雾
				#if USE_FOG
                UNITY_TRANSFER_FOG(o,o.vertex);
                #endif

				// //光照贴图
				// //光照贴图使用uv2，因此这里用uv_MainTex
				// #if LIGHTMAP_ON
				// o.lightMap = v.uv_MainTex.xy*unity_LightmapST.xy+unity_LightmapST.zw;
				// #endif

				// 用逆矩阵转换法线至世界空间
				o.worldNormal = mul(v.normal, (half3x3)unity_WorldToObject);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.color = v.color;

				#if DRAW_RIM
				half3 viewDir = normalize(ObjSpaceViewDir(v.vertex));
                half fresnel = saturate(1.0 - dot(v.normal, viewDir));
                fresnel = pow(fresnel, _FPower);
				
				fresnel = _F0 + (1.0 - _F0) * fresnel;
				o.color *= fresnel;
				#endif

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				half timeValue = abs(sin(_Time.y*_MainTexChangingFrequency))*_MainTexChangingStrength;
		       	fixed4 originColor = tex2D(_MainTex, i.uv+float2(0,timeValue));

				fixed4 secColor = tex2D(_SecTex,i.uv_SecTex+float2(0,_Time.y*_SecTexSpeed))*_SecTexStrength;
				
				fixed4 thirdColor = tex2D(_ThirdTex,i.uv_ThirdTex+float2(0,_Time.x*_ThirdTexSpeed));

				//贴图流动效果
				originColor.rgb += secColor.rgb;
				
		       	// //透明度裁剪
				// #if ALPHACLIP
		       	// clip(originColor.a-_AlphaClipThreshold);
				// #endif

		       	// //光照贴图
		       	// #if LIGHTMAP_ON
		       	// half3 lm=DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap,i.lightMap.xy));
		       	// originColor.rgb*=lm*_LightmapIntensity+_LightmapAdd;
		       	// #endif

				//发光效果
				half emissionValue = abs(sin(_Time.y))*_MainTexEmissionStrength;
				_EmissionColor=fixed4(emissionValue,emissionValue,emissionValue,1);

		       	//亮部强度根据阴影强度来计算
		       	_HighlightIntensity=_ShadowIntensity;
		       	_ShadowIntensity=_ShadowIntensity*0.6;

		       	fixed3 N=normalize(i.worldNormal);
		       	fixed3 L=normalize(UnityWorldSpaceLightDir(i.worldPos));

		       	half dotResult=(1-dot(N,L));
		       	half dotLightStep=step((1-_LightThreshold),dotResult)+dotResult*_TransitionIntensity;
		       	//前有叠加，防止值超出1造成阴影颜色过深
		       	dotLightStep=saturate(dotLightStep);

		       	_ShadowColor = lerp(_HighlightColor, _ShadowColor, _LightColor0*_ShadowIntensity*0.5);
		       	_HighlightColor = lerp(_HighlightColor, _ShadowColor , -_LightColor0*_HighlightIntensity*0.5);

				#if USE_AMBIENTLIGHT
				fixed4 ambientEquator=unity_AmbientEquator*0.2+0.8;
		       	fixed4 ambientGround=unity_AmbientGround*0.2+0.8;

				fixed4 outputColor=originColor*(_HighlightColor*(1-dotLightStep)*ambientEquator+_ShadowColor*dotLightStep*ambientGround)*0.7;
				#else
				fixed4 outputColor=originColor*(_HighlightColor*(1-dotLightStep)+_ShadowColor*dotLightStep)*0.7;
				#endif

		       	fixed4 result=outputColor*_Color*(_EmissionColor+2);

		       	

		       	
				
				
		       	
				//透明度变化
				result.a = (1-_MainTexChangingStrength)+timeValue;
				result.a *= _MainTexStrength;
				//两边淡出
				result.a *= saturate((1-abs(i.uv.x-0.5)*2)*_MainTexRange);
				//第三贴图透明度叠加变化
				result.a *=(1-_ThirdTexStrength)+thirdColor.r*_ThirdTexStrength;
				//贴图透明度加强
				result.a += secColor.r;

				//环境光拟合
		       	result=result*(UNITY_LIGHTMODEL_AMBIENT*_MainAmbientSensitivity+(1-_MainAmbientSensitivity));

		       	result=result*(_LightColor0*0.2+0.8);

				#if DRAW_RIM
		       	result=saturate(2.0f * i.color * _RimColor) + result;
		       	#endif

				#if USE_FOG
		       	// //雾（在最后添加比较美观）
		       	UNITY_APPLY_FOG(i.fogCoord, result);
				#endif
				
				
				return result;
			}
			ENDCG
		}
	}
}
