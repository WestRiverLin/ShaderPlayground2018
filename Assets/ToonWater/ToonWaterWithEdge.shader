Shader "SoFunny/Water/ToonWaterWithEdge"
{
	Properties
	{
		[Header(Wave)]
		_Color("水体颜色 Main Color", Color) = (1, 1, 1, .5)
       _IntersectionColor("边缘颜色 Intersection Color", Color) = (1, 1, 1, .5)
       _IntersectionThresholdMax("边缘阈值 Intersection Threshold Max", float) = 1
       _DisplGuide("边缘纹理 Displacement guide", 2D) = "white" {}
       _DisplAmount("纹理总量 Displacement amount", float) = 0.5
       _WaveSpeed("波浪速度 WaveSpeed",Range(-3,3))=3
       _WaveEdgeHardness("波浪边缘硬度 WaveEdgeHardness",Range(0,10))=2

       [Header(Surface)]
		_SurfaceTex ("水面纹理 SurfaceTex", 2D) = "white" {}
		_SurNoiseTex ("水面噪波纹理 SurNoiseTex", 2D) = "white" {}
		_SurfaceEdgeHardness("水纹边缘硬度 SurfaceEdgeHardness",Range(0,10))=0.5
		_SurfaceColor("水面颜色 SurfaceColor", Color) = (1,1,1,1)
        _SurTexSize ("水纹噪波大小 SurTexSize", Float ) = 0.05
        _SurTexGLOW ("水纹自发光 SurTexGLOW", Range(0,2)) = 0.3
        _SurTexT ("水纹变化周期 SurTexT", Range(0.1,2) ) = 1
        _SurTexP ("水纹变化相位 SurTexP", Range(-2,2) ) = 0
        _SurTexU ("水纹U轴振幅 SurTexU", Float ) = 0.05
        _SurTexV ("水纹V轴振幅 SurTexV", Float ) = -0.05
        _SurTexU_2 ("水纹U轴噪波强度 SurTexU_2", Float ) = 0.05
        _SurTexV_2 ("水纹V轴噪波强度 SurTexV_2", Float ) = -0.15
	}
	SubShader
	{
		Tags { "Queue" = "Transparent" "RenderType"="Transparent"  }
		LOD 100

		Pass
        {
           Blend SrcAlpha OneMinusSrcAlpha

           ZWrite Off

           CGPROGRAM
           #pragma vertex vert
           #pragma fragment frag
           #pragma multi_compile_fog
           #include "UnityCG.cginc"
 
           struct appdata
           {
               float4 vertex : POSITION;
               float2 uv : TEXCOORD0;
           };
 
           struct v2f
           {
               float2 uv : TEXCOORD0;

               float4 vertex : SV_POSITION;
               float2 displUV : TEXCOORD1;
               float4 scrPos : TEXCOORD2;
               float3 viewDir : TEXCOORD3;
               float4 proj : TEXCOORD4;
               UNITY_FOG_COORDS(5)
           };
 
           sampler2D _CameraDepthTexture;
           float4 _Color;
           float4 _IntersectionColor;
           float _IntersectionThresholdMax;
           sampler2D _DisplGuide;
           float4 _DisplGuide_ST;

           float _WaveSpeed;

           float _WaveACompensate;
		   float _WaveDCompensate;

		   float _WaveEdgeHardness;
           v2f vert(appdata v)
           {
               v2f o;
               o.vertex = UnityObjectToClipPos(v.vertex);
               o.scrPos = ComputeScreenPos(o.vertex);
               o.displUV = TRANSFORM_TEX(v.uv, _DisplGuide);
               o.uv = v.uv;

               UNITY_TRANSFER_FOG(o,o.vertex);
               return o;   
           }
 
           half _DisplAmount;
 
            half4 frag(v2f i) : SV_TARGET
            {


               float depth = LinearEyeDepth (tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.scrPos)));
 
               float2 displ = tex2D(_DisplGuide, i.displUV - _Time.x *_WaveSpeed).xy;
               displ = ((displ * 2) - 1) * _DisplAmount;
 
               float diff = (saturate(_IntersectionThresholdMax * (depth - i.scrPos.w) + displ));
 
               fixed4 col = lerp(_IntersectionColor, _Color, step(0.5, diff));
 
               UNITY_APPLY_FOG(i.fogCoord, col);
               float realDepth=saturate(depth - i.scrPos.w);
               fixed stepResult=step(_WaveEdgeHardness,9.99);
               //col.a*=stepResult*realDepth*_WaveEdgeHardness+(1-stepResult);
               col.a=1;
               return col;
            }
 
            ENDCG
        }


		Pass {
            Name "FORWARD"
            Tags {
                "LightMode"="ForwardBase"
            }
            Blend SrcAlpha One
            Cull Back
            ZWrite Off
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
			#include "AutoLight.cginc"
            #pragma multi_compile_fwdbase
            #pragma exclude_renderers d3d11_9x xbox360 xboxone ps3 ps4 psp2 
            #pragma target 2.0
            uniform float4 _TimeEditor;
            sampler2D _CameraDepthTexture;
            uniform sampler2D _SurfaceTex; uniform fixed4 _SurfaceTex_ST;
            uniform sampler2D _SurNoiseTex; uniform fixed4 _SurNoiseTex_ST;
            uniform fixed _SurTexSize;


            float _SurTexGLOW;
            float _SurTexT;
            float _SurTexP;
            uniform fixed _SurTexV_2;
            uniform fixed _SurTexU_2;
            uniform fixed _SurTexV;
            uniform fixed _SurTexU;
            float _WaveBeltPivot;
            float _WaveBeltThreshold;
            fixed4 _SurfaceColor;
            float _SurfaceEdgeHardness;

            struct VertexInput {
                float4 vertex : POSITION;
                float2 texcoord2 : TEXCOORD2;
                float2 uv_SurNoiseTex : TEXCOORD3;
                fixed4 vertexColor : COLOR;
                //SHADOW_COORDS(4)
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD2;
            	float2 uv_SurNoiseTex : TEXCOORD3;
                fixed4 vertexColor : COLOR;
                float4 proj:TEXCOORD4;

            };
            VertexOutput vert (VertexInput v) {

                VertexOutput o;
                UNITY_INITIALIZE_OUTPUT(VertexOutput, o);

                o.uv0 = TRANSFORM_TEX(v.texcoord2, _SurfaceTex);
		    	float4 SurTexCol = _Time + _TimeEditor;
    		    o.uv_SurNoiseTex = TRANSFORM_TEX((float2((_SurTexU_2*SurTexCol.g),(_SurTexV_2*SurTexCol.g))+o.uv0), _SurNoiseTex);
                o.vertexColor = v.vertexColor;
                o.pos = UnityObjectToClipPos(v.vertex );

                o.proj = ComputeScreenPos(UnityObjectToClipPos(v.vertex));
				COMPUTE_EYEDEPTH(o.proj.z);
				//TRANSFER_SHADOW(o);

                return o;

            }
            fixed4 frag(VertexOutput i) : Color {
////// Lighting:
////// Emissive:
				half m_depth = LinearEyeDepth(tex2Dproj (_CameraDepthTexture, i.proj).r);
				half deltaDepth = (m_depth - i.proj.z);

                float4 SurTexCol = _Time + _TimeEditor;                
                fixed4 _SurNoiseTex_var = tex2D(_SurNoiseTex,i.uv_SurNoiseTex);
                //float2 NoiTexCol = ((_SurNoiseTex_var.r*_SurTexSize)+i.uv0+float2((_SurTexU*SurTexCol.g),(_SurTexV*SurTexCol.g)));
                float2 NoiTexCol = ((_SurNoiseTex_var.r*_SurTexSize)+i.uv0+float2((_SurTexU*sin(_Time.y/_SurTexT+_SurTexP)),(_SurTexV*sin(_Time.y/_SurTexT+_SurTexP))));
                fixed4 _SurfaceTex_var = tex2D(_SurfaceTex,NoiTexCol);
                fixed3 emissive = (_SurfaceTex_var.rgb*i.vertexColor.rgb*_SurTexGLOW*i.vertexColor.a*_SurfaceTex_var.a*_SurfaceColor.a)*_SurfaceColor.rgb;
                fixed4 col=fixed4(emissive,_SurfaceColor.a);
                //col.a=saturate(deltaDepth/(_WaveBeltPivot+_WaveBeltThreshold)*_EdgeHardness);

                col.a*=saturate(deltaDepth*_SurfaceEdgeHardness);

                return col;

            }
            ENDCG
        }








	}
}
