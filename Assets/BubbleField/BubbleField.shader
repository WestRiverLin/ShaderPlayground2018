Shader "SoFunny/Effects/BubbleField" {
	Properties {
		_MainColor ("主颜色 Main Color" , Color) = (1,1,1,1)
		_HighlightColor("高光颜色 HighlightColor" ,Color) = (0,0,1,1)
		_EdgePow("底边缘粗细 EdgePow" , Range(0 , 5)) = 0.0
		_RimNum("边缘光粗细 RimNum" , Range(0 , 5)) = 4
		// _MainTex("Main Tex" , 2D) = "white"{}
		// _MaskTex("Mask Tex" ,  2D) = "white" {}
		_ShakeSpeed("摇晃速度 ShakeSpeed" ,Range(0 , 8)) = 3
        _ShakeStrength("摇晃强度 ShakeStrength" ,Range(0 , 3)) = 0.5
		_SpecScale("高光大小 SpecScale" ,Range(0 , 0.01)) = 0.001
		_SpecScale2("高光大小2 SpecScale2" ,Range(0 , 0.01)) = 0.01
	}

	SubShader {

	Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "DisableBatching"="True"}
	
	Pass{
		Tags { "LightMode"="ForwardBase" }	
		
		Blend One One
		//Blend SrcAlpha OneMinusSrcAlpha
		ZWrite Off
		Cull Off
		
		CGPROGRAM

		#include "UnityCG.cginc"

		#pragma vertex vert
		#pragma fragment frag

		//#define UNITY_PASS_FORWARDBASE
        #pragma multi_compile_fwdbase

		fixed4 _MainColor;
		fixed4 _HighlightColor;
		sampler2D _CameraDepthTexture;
		half _EdgePow;
		// sampler2D _MainTex;
		// float4 _MainTex_ST;
		sampler2D _MaskTex;
		half _ShakeSpeed;
        half _ShakeStrength;
		half _RimNum;

		half _SpecScale;
		half _SpecScale2;

		struct a2v{
			float4 vertex:POSITION;
			float3 normal:NORMAL;
			float2 tex:TEXCOORD0;
		};

		struct v2f{
			float4 pos:POSITION;
			float4 scrPos:TEXCOORD0;
			float3 worldPos : TEXCOORD1;
			half3 worldNormal:TEXCOORD2;
			half3 worldViewDir:TEXCOORD3;
			// float2 uv:TEXCOORD4;
		};

		v2f vert (a2v v )
		{
			v2f o;

			
			o.pos = UnityObjectToClipPos ( v.vertex );

			o.scrPos = ComputeScreenPos ( o.pos );
			o.pos.x +=sin(_Time.y*_ShakeSpeed+v.vertex.y*2.5)*0.25*_ShakeStrength;

			float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz; 
			o.worldPos = worldPos;

			o.worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
			o.worldNormal = UnityObjectToWorldNormal(v.normal); 

			// o.uv = TRANSFORM_TEX(v.tex , _MainTex);

			COMPUTE_EYEDEPTH(o.scrPos.z);
			return o;
		}
	
		fixed4 frag ( v2f i ) : SV_TARGET
		{
			fixed3 worldNormal = normalize(i.worldNormal); //法线 N
			fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos)); //光照方向 L
			fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos)); //视角方向 V
			fixed3 fakeLightDir = fixed3(1,0.5,0.5);
			fixed3 worldHalfDir = normalize(worldLightDir+0.2 + worldViewDir); //高光计算用

			//风格化高光
			fixed3 worldHalfDir2 = worldHalfDir + fixed3(0, 0.5, 0);
			worldHalfDir2 = normalize(worldHalfDir2);

			//高光
             //改为使用硬边缘
			fixed spec = dot(worldNormal, worldHalfDir);
			//fixed w = fwidth(spec)*2.5;
			//fixed4 specular = lerp(0,1,smoothstep(-w, w, spec+_SpecScale-1)) * step(0.001, _SpecScale);
            fixed4 specular = step(0.001, spec+_SpecScale-1);

			fixed spec2 = dot(worldNormal, worldHalfDir2);
			//fixed w2 = fwidth(spec2)*2.5;
			//fixed4 specular2 = lerp(0,1,smoothstep(-w2, w2, spec2+_SpecScale2-1)) * step(0.001, _SpecScale2);
            fixed4 specular2 = step(0.001, spec2+_SpecScale2-1);

			// half diff1 = abs(dot(worldViewDir,worldNormal));
			// diff1= step(diff1,0.2+sin(i.pos.y*0.025+_Time.y)*0.1);
			
			// // //获取深度图和clip space的深度值
			// float sceneZ = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.scrPos)));
			// float partZ = i.scrPos.z;

			// // //diff为比较两个深度值，rim为Phong：在边缘位置加上一层_HighlightColor的颜色
 			// float diff2 = 1-saturate((sceneZ-i.scrPos.z)*4 - _EdgePow);
			// diff2=1-step(diff2,0.5);
			// half finalValue=saturate(diff1+diff2);


			// //柔化
			// fixed diff3 = 1-abs(dot(worldViewDir,worldNormal));

			// fixed4 finalColor = _HighlightColor*saturate(finalValue+diff3);
			
			//纹理
			// fixed mainTex = 1 - tex2D(_MainTex , i.uv).a;
			// fixed mask = tex2D(_MaskTex , i.uv + float2(0 , (_Time.y)*_speed)).r;
			fixed4 finalColor = lerp(_MainColor , _HighlightColor , 0);
			// finalColor=lerp(fixed4(0,0,0,1),finalColor,mask);
		
			//获取深度图和clip space的深度值
            //float sceneZ = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.scrPos)));
			float sceneZ = LinearEyeDepth(tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.scrPos)));
			float partZ = i.scrPos.z;

			//diff为比较两个深度值，rim为Phong：在边缘位置加上一层_HighlightColor的颜色
 			float diff = 1-saturate((sceneZ-i.scrPos.z)*4 - _EdgePow);
			half rim = pow(1 - abs(dot(normalize(i.worldNormal),normalize(i.worldViewDir))) , _RimNum);

			//最后通过插值混合颜色
			finalColor = lerp(finalColor, _HighlightColor, diff);
			finalColor = lerp(finalColor, _HighlightColor, rim);
			return finalColor+specular*(_HighlightColor+0.1)+specular2*(_HighlightColor+0.1);
		}

		ENDCG
		}
	}
}
