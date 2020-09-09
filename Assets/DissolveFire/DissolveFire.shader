Shader "SoFunny/Effects/DissolveFire"
{
	Properties
	{
		[Header(Texture)]
		_MainTex ("火焰流光贴图 MainTex", 2D) = "white" {}
		_DissolveTex ("火焰边缘溶解贴图 DissolveTex", 2D) = "white" {}
		
		[Header(Fire)]
		_NdVThreshold ("整体剔除阈值 NdVThreshold", Range(0,2))=1.1
		_FireRootThreshold ("火焰根部剔除值 FireRootThreshold", Range(0,2))=0.4
		_FlowSpeed ("流动速度 FlowSpeed", Range(-3,3)) = 1 

		[Header(OuterFire)]
		_OuterColor ("外焰色 OuterColor", Color) = (1,1,1,1)
		_OuterBrightness("外焰亮度 OuterBrightness",Range(1,3)) = 1
		_UVYPower("UV Y轴幂 UVYPower",Range(0,6)) = 4.5
		_TailFade("尾部剔除强度 TailFade",Range(0,2)) = 1.5

		[Header(InnerFire)]
		_InnerColor ("内焰色 InnerColor", Color) = (1,1,1,1)
		_InnerBrightness("内焰亮度 InnerBrightness",Range(1,3)) = 1.2
		_InnerPower("内焰强度(范围) InnerPower",Range(0,6)) = 1
		
	}
	SubShader
	{
		Tags {"RenderType"="TransparentCutout" "Queue"="AlphaTest"}
		LOD 100

		Pass
		{
			

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			//#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float2 uv2 : TEXCOORD1;
				half3 normal:NORMAL;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float2 uv2 : TEXCOORD1;
				float3 worldNormal:TEXCOORD2;
				float3 normal:TEXCOORD3;
				float3 worldPos:TEXCOORD4;
				float3 viewDir:TEXCOORD5;
				//UNITY_FOG_COORDS(6)
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			sampler2D _DissolveTex;
			float4 _DissolveTex_ST;

			half _NdVThreshold;
			half _FireRootThreshold;
			half _UVYPower;
			half _TailFade;

			fixed4 _OuterColor;
			half _OuterBrightness;
			fixed4 _InnerColor;
			half _InnerBrightness;
			half _FlowSpeed;
			half _InnerPower;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);

				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.uv2 = TRANSFORM_TEX(v.uv, _DissolveTex);
				//不进行转换，使用物体空间法线
				o.worldNormal = mul(v.normal, (half3x3)unity_WorldToObject);
				o.normal = v.normal;
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.viewDir = normalize(ObjSpaceViewDir(v.vertex));
				
				//UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv+float2(0,-_Time.y/2*_FlowSpeed));
				fixed4 dissolveCol = tex2D(_DissolveTex, i.uv2+float2(0,-_Time.y/2*_FlowSpeed));
				float3 N=normalize(i.normal);
				//float3 WN=normalize(i.worldNormal);
				float3 V=normalize(i.viewDir);
				
				float NdV=abs(dot(N,V));

				clip(dissolveCol.r+NdV-_NdVThreshold+abs(0.5-i.uv2.y)*0.5*_FireRootThreshold-pow(i.uv2.y,_UVYPower)*_TailFade);
				
				//return fixed4(1-i.uv.y,1-i.uv.y,1-i.uv.y,1);
				half fireThreshold=saturate(NdV*pow((1-i.uv2.y),(6-_InnerPower))*15);
				fixed4 outerCol=_OuterColor*(1-fireThreshold);
				fixed4 innerCol=saturate(_InnerColor*col.r+_OuterColor*(1-col.r))*fireThreshold;
				fixed4 finalCol=outerCol*_OuterBrightness+innerCol*_InnerBrightness;

				// apply fog
				//UNITY_APPLY_FOG(i.fogCoord, finalCol);
				return finalCol;
			}
			ENDCG
		}

	}
}
