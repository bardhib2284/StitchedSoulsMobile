// Made with Amplify Shader Editor v1.9.7.1
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "TriForge/Fantasy Forest/SimpleWater"
{
	Properties
	{
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		[Normal]_NormalMap("Normal Map", 2D) = "bump" {}
		_NormalMapScale("Normal Map Scale", Range( 0 , 10)) = 1
		_NormalIntensity("Normal Intensity", Range( 0 , 5)) = 0
		_WaterSmoothness("Water Smoothness", Range( 0 , 1)) = 0.95
		_WaterSpecularity("Water Specularity", Range( 0 , 1)) = 1
		_FoamAmount("Foam Amount", Range( 0 , 2)) = 0
		_FoamContrast("Foam Contrast", Range( 0 , 5)) = 1.5
		_FoamTexture("Foam Texture", 2D) = "white" {}
		_FoamScale("Foam Scale", Float) = 3
		_RefractionIntensity("Refraction Intensity", Range( 0 , 5)) = 5
		_Float3("Float 3", Float) = 0
		_Float6("Float 6", Range( 0 , 2)) = 0
		_DeepColor("Deep Color", Color) = (0.08940016,0.2804352,0.3867925,0)
		_ShallowColor("Shallow Color", Color) = (0.2282841,0.4686714,0.509434,0)
		_FresnelOpacityStrength("Fresnel Opacity Strength", Range( 0 , 1)) = 0.1
		_FoamOpacity("Foam Opacity", Range( 0 , 1)) = 1
		_FresnelScale("Fresnel Scale", Range( 0 , 10)) = 0
		_FresnelPower("Fresnel Power", Range( 0 , 25)) = 0
		_WaterNormalSpeed("Water Normal Speed", Float) = 1
		_NormalDetailIntensity("Normal Detail Intensity", Range( 0 , 5)) = 1
		_NormalDetailScale("Normal Detail Scale", Range( 0 , 10)) = 1


		//_TransmissionShadow( "Transmission Shadow", Range( 0, 1 ) ) = 0.5
		//_TransStrength( "Trans Strength", Range( 0, 50 ) ) = 1
		//_TransNormal( "Trans Normal Distortion", Range( 0, 1 ) ) = 0.5
		//_TransScattering( "Trans Scattering", Range( 1, 50 ) ) = 2
		//_TransDirect( "Trans Direct", Range( 0, 1 ) ) = 0.9
		//_TransAmbient( "Trans Ambient", Range( 0, 1 ) ) = 0.1
		//_TransShadow( "Trans Shadow", Range( 0, 1 ) ) = 0.5
		//_TessPhongStrength( "Tess Phong Strength", Range( 0, 1 ) ) = 0.5
		//_TessValue( "Tess Max Tessellation", Range( 1, 32 ) ) = 16
		//_TessMin( "Tess Min Distance", Float ) = 10
		//_TessMax( "Tess Max Distance", Float ) = 25
		//_TessEdgeLength ( "Tess Edge length", Range( 2, 50 ) ) = 16
		//_TessMaxDisp( "Tess Max Displacement", Float ) = 25

		[HideInInspector][ToggleOff] _SpecularHighlights("Specular Highlights", Float) = 1
		[HideInInspector][ToggleOff] _EnvironmentReflections("Environment Reflections", Float) = 1
		[HideInInspector][ToggleOff] _ReceiveShadows("Receive Shadows", Float) = 1.0

		[HideInInspector] _QueueOffset("_QueueOffset", Float) = 0
        [HideInInspector] _QueueControl("_QueueControl", Float) = -1

        [HideInInspector][NoScaleOffset] unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset] unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset] unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}

		//[HideInInspector][ToggleUI] _AddPrecomputedVelocity("Add Precomputed Velocity", Float) = 1
	}

	SubShader
	{
		LOD 0

		

		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent" "Queue"="Transparent" "UniversalMaterialType"="Lit" }

		Cull Off
		ZWrite On
		ZTest LEqual
		Offset 0 , 0
		AlphaToMask Off

		

		HLSLINCLUDE
		#pragma target 4.5
		#pragma prefer_hlslcc gles
		// ensure rendering platforms toggle list is visible

		#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
		#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Filtering.hlsl"

		#ifndef ASE_TESS_FUNCS
		#define ASE_TESS_FUNCS
		float4 FixedTess( float tessValue )
		{
			return tessValue;
		}

		float CalcDistanceTessFactor (float4 vertex, float minDist, float maxDist, float tess, float4x4 o2w, float3 cameraPos )
		{
			float3 wpos = mul(o2w,vertex).xyz;
			float dist = distance (wpos, cameraPos);
			float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0) * tess;
			return f;
		}

		float4 CalcTriEdgeTessFactors (float3 triVertexFactors)
		{
			float4 tess;
			tess.x = 0.5 * (triVertexFactors.y + triVertexFactors.z);
			tess.y = 0.5 * (triVertexFactors.x + triVertexFactors.z);
			tess.z = 0.5 * (triVertexFactors.x + triVertexFactors.y);
			tess.w = (triVertexFactors.x + triVertexFactors.y + triVertexFactors.z) / 3.0f;
			return tess;
		}

		float CalcEdgeTessFactor (float3 wpos0, float3 wpos1, float edgeLen, float3 cameraPos, float4 scParams )
		{
			float dist = distance (0.5 * (wpos0+wpos1), cameraPos);
			float len = distance(wpos0, wpos1);
			float f = max(len * scParams.y / (edgeLen * dist), 1.0);
			return f;
		}

		float DistanceFromPlane (float3 pos, float4 plane)
		{
			float d = dot (float4(pos,1.0f), plane);
			return d;
		}

		bool WorldViewFrustumCull (float3 wpos0, float3 wpos1, float3 wpos2, float cullEps, float4 planes[6] )
		{
			float4 planeTest;
			planeTest.x = (( DistanceFromPlane(wpos0, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos1, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos2, planes[0]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.y = (( DistanceFromPlane(wpos0, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos1, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos2, planes[1]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.z = (( DistanceFromPlane(wpos0, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos1, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos2, planes[2]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.w = (( DistanceFromPlane(wpos0, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos1, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos2, planes[3]) > -cullEps) ? 1.0f : 0.0f );
			return !all (planeTest);
		}

		float4 DistanceBasedTess( float4 v0, float4 v1, float4 v2, float tess, float minDist, float maxDist, float4x4 o2w, float3 cameraPos )
		{
			float3 f;
			f.x = CalcDistanceTessFactor (v0,minDist,maxDist,tess,o2w,cameraPos);
			f.y = CalcDistanceTessFactor (v1,minDist,maxDist,tess,o2w,cameraPos);
			f.z = CalcDistanceTessFactor (v2,minDist,maxDist,tess,o2w,cameraPos);

			return CalcTriEdgeTessFactors (f);
		}

		float4 EdgeLengthBasedTess( float4 v0, float4 v1, float4 v2, float edgeLength, float4x4 o2w, float3 cameraPos, float4 scParams )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;
			tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
			tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
			tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
			tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			return tess;
		}

		float4 EdgeLengthBasedTessCull( float4 v0, float4 v1, float4 v2, float edgeLength, float maxDisplacement, float4x4 o2w, float3 cameraPos, float4 scParams, float4 planes[6] )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;

			if (WorldViewFrustumCull(pos0, pos1, pos2, maxDisplacement, planes))
			{
				tess = 0.0f;
			}
			else
			{
				tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
				tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
				tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
				tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			}
			return tess;
		}
		#endif //ASE_TESS_FUNCS
		ENDHLSL

		
		Pass
		{
			
			Name "Forward"
			Tags { "LightMode"="UniversalForward" }

			Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
			ZWrite Off
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA

			

			HLSLPROGRAM

			#pragma multi_compile_local_fragment _ALPHATEST_ON
			#define _NORMAL_DROPOFF_TS 1
			#pragma shader_feature_local _RECEIVE_SHADOWS_OFF
			#pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define _SPECULAR_SETUP 1
			#pragma shader_feature_local_fragment _SPECULARHIGHLIGHTS_OFF
			#pragma shader_feature_local_fragment _ENVIRONMENTREFLECTIONS_OFF
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define _NORMALMAP 1
			#define ASE_VERSION 19701
			#define ASE_SRP_VERSION 170003
			#define REQUIRE_OPAQUE_TEXTURE 1
			#define REQUIRE_DEPTH_TEXTURE 1


			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
			#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ EVALUATE_SH_MIXED EVALUATE_SH_VERTEX
			#pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
			#pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
			#pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
			#pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
			#pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
			#pragma multi_compile _ _LIGHT_LAYERS
			#pragma multi_compile_fragment _ _LIGHT_COOKIES
			#pragma multi_compile _ _FORWARD_PLUS

			#pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
			#pragma multi_compile _ SHADOWS_SHADOWMASK
			#pragma multi_compile _ DIRLIGHTMAP_COMBINED
			#pragma multi_compile _ LIGHTMAP_ON
			#pragma multi_compile _ DYNAMICLIGHTMAP_ON
			#pragma multi_compile _ USE_LEGACY_LIGHTMAPS
			#pragma multi_compile_fragment _ DEBUG_DISPLAY

			#pragma vertex vert
			#pragma fragment frag

			#if defined(_SPECULAR_SETUP) && defined(_ASE_LIGHTING_SIMPLE)
				#define _SPECULAR_COLOR 1
			#endif

			#define SHADERPASS SHADERPASS_FORWARD

			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ProbeVolumeVariants.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
            #include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRendering.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/DebugMipmapStreamingMacros.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#if defined(LOD_FADE_CROSSFADE)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

			#if defined(UNITY_INSTANCING_ENABLED) && defined(_TERRAIN_INSTANCED_PERPIXEL_NORMAL)
				#define ENABLE_TERRAIN_PERPIXEL_NORMAL
			#endif

			#define ASE_NEEDS_FRAG_SCREEN_POSITION
			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#define ASE_NEEDS_VERT_POSITION
			#define ASE_NEEDS_FRAG_WORLD_TANGENT
			#define ASE_NEEDS_FRAG_WORLD_NORMAL
			#define ASE_NEEDS_FRAG_WORLD_BITANGENT


			#if defined(ASE_EARLY_Z_DEPTH_OPTIMIZE) && (SHADER_TARGET >= 45)
				#define ASE_SV_DEPTH SV_DepthLessEqual
				#define ASE_SV_POSITION_QUALIFIERS linear noperspective centroid
			#else
				#define ASE_SV_DEPTH SV_Depth
				#define ASE_SV_POSITION_QUALIFIERS
			#endif

			struct Attributes
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float4 tangentOS : TANGENT;
				float4 texcoord : TEXCOORD0;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct PackedVaryings
			{
				ASE_SV_POSITION_QUALIFIERS float4 positionCS : SV_POSITION;
				float4 clipPosV : TEXCOORD0;
				float4 lightmapUVOrVertexSH : TEXCOORD1;
				half4 fogFactorAndVertexLight : TEXCOORD2;
				float4 tSpace0 : TEXCOORD3;
				float4 tSpace1 : TEXCOORD4;
				float4 tSpace2 : TEXCOORD5;
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					float4 shadowCoord : TEXCOORD6;
				#endif
				#if defined(DYNAMICLIGHTMAP_ON)
					float2 dynamicLightmapUV : TEXCOORD7;
				#endif	
				#if defined(USE_APV_PROBE_OCCLUSION)
					float4 probeOcclusion : TEXCOORD8;
				#endif
				float4 ase_texcoord9 : TEXCOORD9;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _ShallowColor;
			float4 _DeepColor;
			float _WaterNormalSpeed;
			float _FresnelOpacityStrength;
			float _FresnelPower;
			float _FresnelScale;
			float _FoamOpacity;
			float _FoamScale;
			float _FoamContrast;
			float _FoamAmount;
			float _Float6;
			float _Float3;
			float _RefractionIntensity;
			float _NormalDetailIntensity;
			float _NormalDetailScale;
			float _NormalIntensity;
			float _NormalMapScale;
			float _WaterSpecularity;
			float _WaterSmoothness;
			#ifdef ASE_TRANSMISSION
				float _TransmissionShadow;
			#endif
			#ifdef ASE_TRANSLUCENCY
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			#ifdef SCENEPICKINGPASS
				float4 _SelectionID;
			#endif

			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif

			sampler2D _NormalMap;
			sampler2D _FoamTexture;


			
			PackedVaryings VertexFunction( Attributes input  )
			{
				PackedVaryings output = (PackedVaryings)0;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

				float3 objectToViewPos = TransformWorldToView(TransformObjectToWorld(input.positionOS.xyz));
				float eyeDepth = -objectToViewPos.z;
				output.ase_texcoord9.x = eyeDepth;
				
				
				//setting value to unused interpolator channels and avoid initialization warnings
				output.ase_texcoord9.yzw = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = input.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					input.positionOS.xyz = vertexValue;
				#else
					input.positionOS.xyz += vertexValue;
				#endif
				input.normalOS = input.normalOS;
				input.tangentOS = input.tangentOS;

				VertexPositionInputs vertexInput = GetVertexPositionInputs( input.positionOS.xyz );
				VertexNormalInputs normalInput = GetVertexNormalInputs( input.normalOS, input.tangentOS );

				output.tSpace0 = float4( normalInput.normalWS, vertexInput.positionWS.x );
				output.tSpace1 = float4( normalInput.tangentWS, vertexInput.positionWS.y );
				output.tSpace2 = float4( normalInput.bitangentWS, vertexInput.positionWS.z );

				#if defined(LIGHTMAP_ON)
					OUTPUT_LIGHTMAP_UV( input.texcoord1, unity_LightmapST, output.lightmapUVOrVertexSH.xy );
				#endif

				#if defined(DYNAMICLIGHTMAP_ON)
					output.dynamicLightmapUV.xy = input.texcoord2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
				#endif

				OUTPUT_SH4( vertexInput.positionWS, normalInput.normalWS.xyz, GetWorldSpaceNormalizeViewDir( vertexInput.positionWS ), output.lightmapUVOrVertexSH.xyz, output.probeOcclusion );

				#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
					output.lightmapUVOrVertexSH.zw = input.texcoord.xy;
					output.lightmapUVOrVertexSH.xy = input.texcoord.xy * unity_LightmapST.xy + unity_LightmapST.zw;
				#endif

				half3 vertexLight = VertexLighting( vertexInput.positionWS, normalInput.normalWS );

				#ifdef ASE_FOG
					half fogFactor = ComputeFogFactor( vertexInput.positionCS.z );
				#else
					half fogFactor = 0;
				#endif

				output.fogFactorAndVertexLight = half4(fogFactor, vertexLight);

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					output.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				output.positionCS = vertexInput.positionCS;
				output.clipPosV = vertexInput.positionCS;
				return output;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 normalOS : NORMAL;
				float4 tangentOS : TANGENT;
				float4 texcoord : TEXCOORD0;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( Attributes input )
			{
				VertexControl output;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				output.vertex = input.positionOS;
				output.normalOS = input.normalOS;
				output.tangentOS = input.tangentOS;
				output.texcoord = input.texcoord;
				output.texcoord1 = input.texcoord1;
				output.texcoord2 = input.texcoord2;
				
				return output;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> input)
			{
				TessellationFactors output;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(input[0].vertex, input[1].vertex, input[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(input[0].vertex, input[1].vertex, input[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(input[0].vertex, input[1].vertex, input[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				output.edge[0] = tf.x; output.edge[1] = tf.y; output.edge[2] = tf.z; output.inside = tf.w;
				return output;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			PackedVaryings DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				Attributes output = (Attributes) 0;
				output.positionOS = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				output.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				output.tangentOS = patch[0].tangentOS * bary.x + patch[1].tangentOS * bary.y + patch[2].tangentOS * bary.z;
				output.texcoord = patch[0].texcoord * bary.x + patch[1].texcoord * bary.y + patch[2].texcoord * bary.z;
				output.texcoord1 = patch[0].texcoord1 * bary.x + patch[1].texcoord1 * bary.y + patch[2].texcoord1 * bary.z;
				output.texcoord2 = patch[0].texcoord2 * bary.x + patch[1].texcoord2 * bary.y + patch[2].texcoord2 * bary.z;
				
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = output.positionOS.xyz - patch[i].normalOS * (dot(output.positionOS.xyz, patch[i].normalOS) - dot(patch[i].vertex.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				output.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * output.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], output);
				return VertexFunction(output);
			}
			#else
			PackedVaryings vert ( Attributes input )
			{
				return VertexFunction( input );
			}
			#endif

			half4 frag ( PackedVaryings input
						#ifdef ASE_DEPTH_WRITE_ON
						,out float outputDepth : ASE_SV_DEPTH
						#endif
						#ifdef _WRITE_RENDERING_LAYERS
						, out float4 outRenderingLayers : SV_Target1
						#endif
						 ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

				#if defined(LOD_FADE_CROSSFADE)
					LODFadeCrossFade( input.positionCS );
				#endif

				#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
					float2 sampleCoords = (input.lightmapUVOrVertexSH.zw / _TerrainHeightmapRecipSize.zw + 0.5f) * _TerrainHeightmapRecipSize.xy;
					float3 WorldNormal = TransformObjectToWorldNormal(normalize(SAMPLE_TEXTURE2D(_TerrainNormalmapTexture, sampler_TerrainNormalmapTexture, sampleCoords).rgb * 2 - 1));
					float3 WorldTangent = -cross(GetObjectToWorldMatrix()._13_23_33, WorldNormal);
					float3 WorldBiTangent = cross(WorldNormal, -WorldTangent);
				#else
					float3 WorldNormal = normalize( input.tSpace0.xyz );
					float3 WorldTangent = input.tSpace1.xyz;
					float3 WorldBiTangent = input.tSpace2.xyz;
				#endif

				float3 WorldPosition = float3(input.tSpace0.w,input.tSpace1.w,input.tSpace2.w);
				float3 WorldViewDirection = _WorldSpaceCameraPos.xyz  - WorldPosition;
				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				float4 ClipPos = input.clipPosV;
				float4 ScreenPos = ComputeScreenPos( input.clipPosV );

				float2 NormalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					ShadowCoords = input.shadowCoord;
				#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
					ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
				#endif

				WorldViewDirection = SafeNormalize( WorldViewDirection );

				float4 ase_screenPosNorm = ScreenPos / ScreenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float4 fetchOpaqueVal419 = float4( SHADERGRAPH_SAMPLE_SCENE_COLOR( ase_screenPosNorm.xy ), 1.0 );
				float temp_output_443_0 = ( 1.0 * 0.6 * _WaterNormalSpeed );
				float temp_output_11_0_g12 = ( temp_output_443_0 * _TimeParameters.x );
				float2 panner44 = ( 1.0 * _Time.y * float2( 0.02,0.1 ) + (( WorldPosition / ( 3.0 * _NormalMapScale ) )).xz);
				float2 temp_output_32_0_g12 = panner44;
				float2 panner5_g12 = ( temp_output_11_0_g12 * float2( 0.1,0.1 ) + temp_output_32_0_g12);
				float temp_output_33_0_g12 = _NormalIntensity;
				float3 unpack3_g12 = UnpackNormalScale( tex2D( _NormalMap, panner5_g12 ), temp_output_33_0_g12 );
				unpack3_g12.z = lerp( 1, unpack3_g12.z, saturate(temp_output_33_0_g12) );
				float2 panner16_g12 = ( temp_output_11_0_g12 * float2( -0.1,-0.1 ) + ( temp_output_32_0_g12 + float2( 0.418,0.355 ) ));
				float3 unpack13_g12 = UnpackNormalScale( tex2D( _NormalMap, panner16_g12 ), temp_output_33_0_g12 );
				unpack13_g12.z = lerp( 1, unpack13_g12.z, saturate(temp_output_33_0_g12) );
				float2 panner19_g12 = ( temp_output_11_0_g12 * float2( -0.1,0.1 ) + ( temp_output_32_0_g12 + float2( 0.865,0.148 ) ));
				float3 unpack20_g12 = UnpackNormalScale( tex2D( _NormalMap, panner19_g12 ), temp_output_33_0_g12 );
				unpack20_g12.z = lerp( 1, unpack20_g12.z, saturate(temp_output_33_0_g12) );
				float2 panner23_g12 = ( temp_output_11_0_g12 * float2( 0.1,-0.1 ) + ( temp_output_32_0_g12 + float2( 0.651,0.752 ) ));
				float3 unpack24_g12 = UnpackNormalScale( tex2D( _NormalMap, panner23_g12 ), temp_output_33_0_g12 );
				unpack24_g12.z = lerp( 1, unpack24_g12.z, saturate(temp_output_33_0_g12) );
				float temp_output_11_0_g13 = ( temp_output_443_0 * _TimeParameters.x );
				float2 panner50 = ( 1.0 * _Time.y * float2( 0.1,0.06 ) + (( WorldPosition / ( 9.0 * _NormalMapScale ) )).xz);
				float2 temp_output_32_0_g13 = panner50;
				float2 panner5_g13 = ( temp_output_11_0_g13 * float2( 0.1,0.1 ) + temp_output_32_0_g13);
				float temp_output_33_0_g13 = _NormalIntensity;
				float3 unpack3_g13 = UnpackNormalScale( tex2D( _NormalMap, panner5_g13 ), temp_output_33_0_g13 );
				unpack3_g13.z = lerp( 1, unpack3_g13.z, saturate(temp_output_33_0_g13) );
				float2 panner16_g13 = ( temp_output_11_0_g13 * float2( -0.1,-0.1 ) + ( temp_output_32_0_g13 + float2( 0.418,0.355 ) ));
				float3 unpack13_g13 = UnpackNormalScale( tex2D( _NormalMap, panner16_g13 ), temp_output_33_0_g13 );
				unpack13_g13.z = lerp( 1, unpack13_g13.z, saturate(temp_output_33_0_g13) );
				float2 panner19_g13 = ( temp_output_11_0_g13 * float2( -0.1,0.1 ) + ( temp_output_32_0_g13 + float2( 0.865,0.148 ) ));
				float3 unpack20_g13 = UnpackNormalScale( tex2D( _NormalMap, panner19_g13 ), temp_output_33_0_g13 );
				unpack20_g13.z = lerp( 1, unpack20_g13.z, saturate(temp_output_33_0_g13) );
				float2 panner23_g13 = ( temp_output_11_0_g13 * float2( 0.1,-0.1 ) + ( temp_output_32_0_g13 + float2( 0.651,0.752 ) ));
				float3 unpack24_g13 = UnpackNormalScale( tex2D( _NormalMap, panner23_g13 ), temp_output_33_0_g13 );
				unpack24_g13.z = lerp( 1, unpack24_g13.z, saturate(temp_output_33_0_g13) );
				float temp_output_11_0_g14 = ( 2.1 * _TimeParameters.x );
				float2 panner453 = ( 1.0 * _Time.y * float2( 0.02,0.1 ) + (( WorldPosition / ( ( 0.5 * _NormalDetailScale ) * _NormalMapScale ) )).xz);
				float2 temp_output_32_0_g14 = panner453;
				float2 panner5_g14 = ( temp_output_11_0_g14 * float2( 0.1,0.1 ) + temp_output_32_0_g14);
				float temp_output_33_0_g14 = _NormalDetailIntensity;
				float3 unpack3_g14 = UnpackNormalScale( tex2D( _NormalMap, panner5_g14 ), temp_output_33_0_g14 );
				unpack3_g14.z = lerp( 1, unpack3_g14.z, saturate(temp_output_33_0_g14) );
				float2 panner16_g14 = ( temp_output_11_0_g14 * float2( -0.1,-0.1 ) + ( temp_output_32_0_g14 + float2( 0.418,0.355 ) ));
				float3 unpack13_g14 = UnpackNormalScale( tex2D( _NormalMap, panner16_g14 ), temp_output_33_0_g14 );
				unpack13_g14.z = lerp( 1, unpack13_g14.z, saturate(temp_output_33_0_g14) );
				float2 panner19_g14 = ( temp_output_11_0_g14 * float2( -0.1,0.1 ) + ( temp_output_32_0_g14 + float2( 0.865,0.148 ) ));
				float3 unpack20_g14 = UnpackNormalScale( tex2D( _NormalMap, panner19_g14 ), temp_output_33_0_g14 );
				unpack20_g14.z = lerp( 1, unpack20_g14.z, saturate(temp_output_33_0_g14) );
				float2 panner23_g14 = ( temp_output_11_0_g14 * float2( 0.1,-0.1 ) + ( temp_output_32_0_g14 + float2( 0.651,0.752 ) ));
				float3 unpack24_g14 = UnpackNormalScale( tex2D( _NormalMap, panner23_g14 ), temp_output_33_0_g14 );
				unpack24_g14.z = lerp( 1, unpack24_g14.z, saturate(temp_output_33_0_g14) );
				float3 WaterNormal274 = BlendNormal( BlendNormal( ( ( ( unpack3_g12 + unpack13_g12 ) + ( unpack20_g12 + unpack24_g12 ) ) * 1.0 ) , ( ( ( unpack3_g13 + unpack13_g13 ) + ( unpack20_g13 + unpack24_g13 ) ) * 1.0 ) ) , ( ( ( unpack3_g14 + unpack13_g14 ) + ( unpack20_g14 + unpack24_g14 ) ) * 0.2 ) );
				float4 temp_output_270_0 = ( ase_screenPosNorm + float4( ( WaterNormal274 * _RefractionIntensity ) , 0.0 ) );
				float4 fetchOpaqueVal271 = float4( SHADERGRAPH_SAMPLE_SCENE_COLOR( temp_output_270_0.xy ), 1.0 );
				float eyeDepth413 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( temp_output_270_0.xy ),_ZBufferParams);
				float eyeDepth = input.ase_texcoord9.x;
				float ifLocalVar414 = 0;
				if( eyeDepth413 > eyeDepth )
				ifLocalVar414 = 1.0;
				else if( eyeDepth413 < eyeDepth )
				ifLocalVar414 = 0.0;
				float4 lerpResult418 = lerp( ( fetchOpaqueVal419 * 0.7 ) , ( fetchOpaqueVal271 * 0.7 ) , ifLocalVar414);
				float4 Refraction281 = lerpResult418;
				float screenDepth316 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy ),_ZBufferParams);
				float distanceDepth316 = ( screenDepth316 - LinearEyeDepth( ase_screenPosNorm.z,_ZBufferParams ) ) / ( _Float3 );
				float clampResult325 = clamp( ( distanceDepth316 * _Float6 ) , 0.0 , 1.0 );
				float4 lerpResult329 = lerp( _ShallowColor , _DeepColor , saturate( clampResult325 ));
				float4 Color362 = lerpResult329;
				float4 color422 = IsGammaSpace() ? float4(0.8679245,0.8679245,0.8679245,0) : float4(0.7254258,0.7254258,0.7254258,0);
				float screenDepth182 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy ),_ZBufferParams);
				float distanceDepth182 = saturate( abs( ( screenDepth182 - LinearEyeDepth( ase_screenPosNorm.z,_ZBufferParams ) ) / ( _FoamAmount ) ) );
				float saferPower188 = abs( ( 1.0 - distanceDepth182 ) );
				float2 panner197 = ( 1.0 * _Time.y * float2( 0.1,0 ) + (( WorldPosition / _FoamScale )).xz);
				float2 panner194 = ( 1.0 * _Time.y * float2( 0.2,0 ) + (( WorldPosition / _FoamScale )).xz);
				float saferPower252 = abs( ( tex2D( _FoamTexture, panner194 ).g * 0.88 ) );
				float2 panner466 = ( 1.0 * _Time.y * float2( 0.15,0.08 ) + (( WorldPosition / 1.0 )).xz);
				float2 panner470 = ( 1.0 * _Time.y * float2( 0.012,0.04 ) + (( WorldPosition / 5.0 )).xz);
				float4 tex2DNode475 = tex2D( _FoamTexture, panner470 );
				float saferPower476 = abs( tex2DNode475.g );
				float FoamFinal420 = saturate( ( ( ( ( ( saturate( pow( saferPower188 , _FoamContrast ) ) - tex2D( _FoamTexture, panner197 ).r ) - saturate( pow( saferPower252 , 0.65 ) ) ) - ( tex2D( _FoamTexture, panner466 ).r * 0.35 ) ) - pow( saferPower476 , 0.5 ) ) * 2.0 ) );
				float4 lerpResult424 = lerp( Color362 , ( color422 + float4( 0,0,0,0 ) ) , ( FoamFinal420 * _FoamOpacity ));
				float3 ase_viewVectorWS = ( _WorldSpaceCameraPos.xyz - WorldPosition );
				float3 ase_viewDirWS = normalize( ase_viewVectorWS );
				float3 tanToWorld0 = float3( WorldTangent.x, WorldBiTangent.x, WorldNormal.x );
				float3 tanToWorld1 = float3( WorldTangent.y, WorldBiTangent.y, WorldNormal.y );
				float3 tanToWorld2 = float3( WorldTangent.z, WorldBiTangent.z, WorldNormal.z );
				float3 tanNormal384 = WaterNormal274;
				float fresnelNdotV384 = dot( float3(dot(tanToWorld0,tanNormal384), dot(tanToWorld1,tanNormal384), dot(tanToWorld2,tanNormal384)), ase_viewDirWS );
				float fresnelNode384 = ( 0.0 + _FresnelScale * pow( max( 1.0 - fresnelNdotV384 , 0.0001 ), _FresnelPower ) );
				float lerpResult441 = lerp( 1.0 , fresnelNode384 , _FresnelOpacityStrength);
				float ColorOpacity365 = lerpResult329.a;
				float FresnelOpacity402 = ( saturate( lerpResult441 ) * ColorOpacity365 );
				float screenDepth256 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy ),_ZBufferParams);
				float distanceDepth256 = saturate( abs( ( screenDepth256 - LinearEyeDepth( ase_screenPosNorm.z,_ZBufferParams ) ) / ( 0.5 ) ) );
				float saferPower258 = abs( distanceDepth256 );
				float WaterEdge428 = saturate( pow( saferPower258 , 1.5 ) );
				float4 lerpResult493 = lerp( Refraction281 , lerpResult424 , ( FresnelOpacity402 * WaterEdge428 ));
				
				float3 temp_cast_5 = (_WaterSpecularity).xxx;
				

				float3 BaseColor = lerpResult493.rgb;
				float3 Normal = WaterNormal274;
				float3 Emission = 0;
				float3 Specular = temp_cast_5;
				float Metallic = 0;
				float Smoothness = _WaterSmoothness;
				float Occlusion = 1;
				float Alpha = WaterEdge428;
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;
				float3 BakedGI = 0;
				float3 RefractionColor = 1;
				float RefractionIndex = 1;
				float3 Transmission = 1;
				float3 Translucency = 1;

				#ifdef ASE_DEPTH_WRITE_ON
					float DepthValue = input.positionCS.z;
				#endif

				#ifdef _CLEARCOAT
					float CoatMask = 0;
					float CoatSmoothness = 0;
				#endif

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				InputData inputData = (InputData)0;
				inputData.positionWS = WorldPosition;
				inputData.positionCS = input.positionCS;
				inputData.viewDirectionWS = WorldViewDirection;

				#ifdef _NORMALMAP
						#if _NORMAL_DROPOFF_TS
							inputData.normalWS = TransformTangentToWorld(Normal, half3x3(WorldTangent, WorldBiTangent, WorldNormal));
						#elif _NORMAL_DROPOFF_OS
							inputData.normalWS = TransformObjectToWorldNormal(Normal);
						#elif _NORMAL_DROPOFF_WS
							inputData.normalWS = Normal;
						#endif
					inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
				#else
					inputData.normalWS = WorldNormal;
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					inputData.shadowCoord = ShadowCoords;
				#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
					inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
				#else
					inputData.shadowCoord = float4(0, 0, 0, 0);
				#endif

				#ifdef ASE_FOG
					inputData.fogCoord = input.fogFactorAndVertexLight.x;
				#endif
					inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;

				#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
					float3 SH = SampleSH(inputData.normalWS.xyz);
				#else
					float3 SH = input.lightmapUVOrVertexSH.xyz;
				#endif

				#if defined(DYNAMICLIGHTMAP_ON)
					inputData.bakedGI = SAMPLE_GI(input.lightmapUVOrVertexSH.xy, input.dynamicLightmapUV.xy, SH, inputData.normalWS);
					inputData.shadowMask = SAMPLE_SHADOWMASK(input.lightmapUVOrVertexSH.xy);
				#elif !defined(LIGHTMAP_ON) && (defined(PROBE_VOLUMES_L1) || defined(PROBE_VOLUMES_L2))
					inputData.bakedGI = SAMPLE_GI( SH, GetAbsolutePositionWS(inputData.positionWS),
						inputData.normalWS,
						inputData.viewDirectionWS,
						input.positionCS.xy,
						input.probeOcclusion,
						inputData.shadowMask );
				#else
					inputData.bakedGI = SAMPLE_GI(input.lightmapUVOrVertexSH.xy, SH, inputData.normalWS);
					inputData.shadowMask = SAMPLE_SHADOWMASK(input.lightmapUVOrVertexSH.xy);
				#endif

				#ifdef ASE_BAKEDGI
					inputData.bakedGI = BakedGI;
				#endif

				inputData.normalizedScreenSpaceUV = NormalizedScreenSpaceUV;

				#if defined(DEBUG_DISPLAY)
					#if defined(DYNAMICLIGHTMAP_ON)
						inputData.dynamicLightmapUV = input.dynamicLightmapUV.xy;
						#endif
					#if defined(LIGHTMAP_ON)
						inputData.staticLightmapUV = input.lightmapUVOrVertexSH.xy;
					#else
						inputData.vertexSH = SH;
					#endif
					#if defined(USE_APV_PROBE_OCCLUSION)
						inputData.probeOcclusion = input.probeOcclusion;
					#endif
				#endif

				SurfaceData surfaceData;
				surfaceData.albedo              = BaseColor;
				surfaceData.metallic            = saturate(Metallic);
				surfaceData.specular            = Specular;
				surfaceData.smoothness          = saturate(Smoothness),
				surfaceData.occlusion           = Occlusion,
				surfaceData.emission            = Emission,
				surfaceData.alpha               = saturate(Alpha);
				surfaceData.normalTS            = Normal;
				surfaceData.clearCoatMask       = 0;
				surfaceData.clearCoatSmoothness = 1;

				#ifdef _CLEARCOAT
					surfaceData.clearCoatMask       = saturate(CoatMask);
					surfaceData.clearCoatSmoothness = saturate(CoatSmoothness);
				#endif

				#ifdef _DBUFFER
					ApplyDecalToSurfaceData(input.positionCS, surfaceData, inputData);
				#endif

				#ifdef _ASE_LIGHTING_SIMPLE
					half4 color = UniversalFragmentBlinnPhong( inputData, surfaceData);
				#else
					half4 color = UniversalFragmentPBR( inputData, surfaceData);
				#endif

				#ifdef ASE_TRANSMISSION
				{
					float shadow = _TransmissionShadow;

					#define SUM_LIGHT_TRANSMISSION(Light)\
						float3 atten = Light.color * Light.distanceAttenuation;\
						atten = lerp( atten, atten * Light.shadowAttenuation, shadow );\
						half3 transmission = max( 0, -dot( inputData.normalWS, Light.direction ) ) * atten * Transmission;\
						color.rgb += BaseColor * transmission;

					SUM_LIGHT_TRANSMISSION( GetMainLight( inputData.shadowCoord ) );

					#if defined(_ADDITIONAL_LIGHTS)
						uint meshRenderingLayers = GetMeshRenderingLayer();
						uint pixelLightCount = GetAdditionalLightsCount();
						#if USE_FORWARD_PLUS
							[loop] for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++)
							{
								FORWARD_PLUS_SUBTRACTIVE_LIGHT_CHECK

								Light light = GetAdditionalLight(lightIndex, inputData.positionWS, inputData.shadowMask);
								#ifdef _LIGHT_LAYERS
								if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
								#endif
								{
									SUM_LIGHT_TRANSMISSION( light );
								}
							}
						#endif
						LIGHT_LOOP_BEGIN( pixelLightCount )
							Light light = GetAdditionalLight(lightIndex, inputData.positionWS, inputData.shadowMask);
							#ifdef _LIGHT_LAYERS
							if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
							#endif
							{
								SUM_LIGHT_TRANSMISSION( light );
							}
						LIGHT_LOOP_END
					#endif
				}
				#endif

				#ifdef ASE_TRANSLUCENCY
				{
					float shadow = _TransShadow;
					float normal = _TransNormal;
					float scattering = _TransScattering;
					float direct = _TransDirect;
					float ambient = _TransAmbient;
					float strength = _TransStrength;

					#define SUM_LIGHT_TRANSLUCENCY(Light)\
						float3 atten = Light.color * Light.distanceAttenuation;\
						atten = lerp( atten, atten * Light.shadowAttenuation, shadow );\
						half3 lightDir = Light.direction + inputData.normalWS * normal;\
						half VdotL = pow( saturate( dot( inputData.viewDirectionWS, -lightDir ) ), scattering );\
						half3 translucency = atten * ( VdotL * direct + inputData.bakedGI * ambient ) * Translucency;\
						color.rgb += BaseColor * translucency * strength;

					SUM_LIGHT_TRANSLUCENCY( GetMainLight( inputData.shadowCoord ) );

					#if defined(_ADDITIONAL_LIGHTS)
						uint meshRenderingLayers = GetMeshRenderingLayer();
						uint pixelLightCount = GetAdditionalLightsCount();
						#if USE_FORWARD_PLUS
							[loop] for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++)
							{
								FORWARD_PLUS_SUBTRACTIVE_LIGHT_CHECK

								Light light = GetAdditionalLight(lightIndex, inputData.positionWS, inputData.shadowMask);
								#ifdef _LIGHT_LAYERS
								if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
								#endif
								{
									SUM_LIGHT_TRANSLUCENCY( light );
								}
							}
						#endif
						LIGHT_LOOP_BEGIN( pixelLightCount )
							Light light = GetAdditionalLight(lightIndex, inputData.positionWS, inputData.shadowMask);
							#ifdef _LIGHT_LAYERS
							if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
							#endif
							{
								SUM_LIGHT_TRANSLUCENCY( light );
							}
						LIGHT_LOOP_END
					#endif
				}
				#endif

				#ifdef ASE_REFRACTION
					float4 projScreenPos = ScreenPos / ScreenPos.w;
					float3 refractionOffset = ( RefractionIndex - 1.0 ) * mul( UNITY_MATRIX_V, float4( WorldNormal,0 ) ).xyz * ( 1.0 - dot( WorldNormal, WorldViewDirection ) );
					projScreenPos.xy += refractionOffset.xy;
					float3 refraction = SHADERGRAPH_SAMPLE_SCENE_COLOR( projScreenPos.xy ) * RefractionColor;
					color.rgb = lerp( refraction, color.rgb, color.a );
					color.a = 1;
				#endif

				#ifdef ASE_FINAL_COLOR_ALPHA_MULTIPLY
					color.rgb *= color.a;
				#endif

				#ifdef ASE_FOG
					#ifdef TERRAIN_SPLAT_ADDPASS
						color.rgb = MixFogColor(color.rgb, half3( 0, 0, 0 ), input.fogFactorAndVertexLight.x );
					#else
						color.rgb = MixFog(color.rgb, input.fogFactorAndVertexLight.x);
					#endif
				#endif

				#ifdef ASE_DEPTH_WRITE_ON
					outputDepth = DepthValue;
				#endif

				#ifdef _WRITE_RENDERING_LAYERS
					uint renderingLayers = GetMeshRenderingLayer();
					outRenderingLayers = float4( EncodeMeshRenderingLayer( renderingLayers ), 0, 0, 0 );
				#endif

				return color;
			}

			ENDHLSL
		}

		
		Pass
		{
			
			Name "DepthOnly"
			Tags { "LightMode"="DepthOnly" }

			ZWrite On
			ColorMask 0
			AlphaToMask Off

			HLSLPROGRAM

			#pragma multi_compile_local_fragment _ALPHATEST_ON
			#define _NORMAL_DROPOFF_TS 1
			#define ASE_FOG 1
			#define _SPECULAR_SETUP 1
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define _NORMALMAP 1
			#define ASE_VERSION 19701
			#define ASE_SRP_VERSION 170003
			#define REQUIRE_DEPTH_TEXTURE 1


			#pragma vertex vert
			#pragma fragment frag

			#if defined(_SPECULAR_SETUP) && defined(_ASE_LIGHTING_SIMPLE)
				#define _SPECULAR_COLOR 1
			#endif

			#define SHADERPASS SHADERPASS_DEPTHONLY

			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
            #include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRendering.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#if defined(LOD_FADE_CROSSFADE)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

			#define ASE_NEEDS_FRAG_SCREEN_POSITION


			#if defined(ASE_EARLY_Z_DEPTH_OPTIMIZE) && (SHADER_TARGET >= 45)
				#define ASE_SV_DEPTH SV_DepthLessEqual
				#define ASE_SV_POSITION_QUALIFIERS linear noperspective centroid
			#else
				#define ASE_SV_DEPTH SV_Depth
				#define ASE_SV_POSITION_QUALIFIERS
			#endif

			struct Attributes
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct PackedVaryings
			{
				ASE_SV_POSITION_QUALIFIERS float4 positionCS : SV_POSITION;
				float4 clipPosV : TEXCOORD0;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 positionWS : TEXCOORD1;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				float4 shadowCoord : TEXCOORD2;
				#endif
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _ShallowColor;
			float4 _DeepColor;
			float _WaterNormalSpeed;
			float _FresnelOpacityStrength;
			float _FresnelPower;
			float _FresnelScale;
			float _FoamOpacity;
			float _FoamScale;
			float _FoamContrast;
			float _FoamAmount;
			float _Float6;
			float _Float3;
			float _RefractionIntensity;
			float _NormalDetailIntensity;
			float _NormalDetailScale;
			float _NormalIntensity;
			float _NormalMapScale;
			float _WaterSpecularity;
			float _WaterSmoothness;
			#ifdef ASE_TRANSMISSION
				float _TransmissionShadow;
			#endif
			#ifdef ASE_TRANSLUCENCY
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			#ifdef SCENEPICKINGPASS
				float4 _SelectionID;
			#endif

			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif

			

			
			PackedVaryings VertexFunction( Attributes input  )
			{
				PackedVaryings output = (PackedVaryings)0;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

				

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = input.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					input.positionOS.xyz = vertexValue;
				#else
					input.positionOS.xyz += vertexValue;
				#endif

				input.normalOS = input.normalOS;

				VertexPositionInputs vertexInput = GetVertexPositionInputs( input.positionOS.xyz );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					output.positionWS = vertexInput.positionWS;
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					output.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				output.positionCS = vertexInput.positionCS;
				output.clipPosV = vertexInput.positionCS;
				return output;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 normalOS : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( Attributes input )
			{
				VertexControl output;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				output.vertex = input.positionOS;
				output.normalOS = input.normalOS;
				
				return output;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> input)
			{
				TessellationFactors output;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(input[0].vertex, input[1].vertex, input[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(input[0].vertex, input[1].vertex, input[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(input[0].vertex, input[1].vertex, input[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				output.edge[0] = tf.x; output.edge[1] = tf.y; output.edge[2] = tf.z; output.inside = tf.w;
				return output;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			PackedVaryings DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				Attributes output = (Attributes) 0;
				output.positionOS = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				output.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = output.positionOS.xyz - patch[i].normalOS * (dot(output.positionOS.xyz, patch[i].normalOS) - dot(patch[i].vertex.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				output.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * output.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], output);
				return VertexFunction(output);
			}
			#else
			PackedVaryings vert ( Attributes input )
			{
				return VertexFunction( input );
			}
			#endif

			half4 frag(	PackedVaryings input
						#ifdef ASE_DEPTH_WRITE_ON
						,out float outputDepth : ASE_SV_DEPTH
						#endif
						 ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( input );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 WorldPosition = input.positionWS;
				#endif

				float4 ShadowCoords = float4( 0, 0, 0, 0 );
				float4 ClipPos = input.clipPosV;
				float4 ScreenPos = ComputeScreenPos( input.clipPosV );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = input.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				float4 ase_screenPosNorm = ScreenPos / ScreenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float screenDepth256 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy ),_ZBufferParams);
				float distanceDepth256 = saturate( abs( ( screenDepth256 - LinearEyeDepth( ase_screenPosNorm.z,_ZBufferParams ) ) / ( 0.5 ) ) );
				float saferPower258 = abs( distanceDepth256 );
				float WaterEdge428 = saturate( pow( saferPower258 , 1.5 ) );
				

				float Alpha = WaterEdge428;
				float AlphaClipThreshold = 0.5;

				#ifdef ASE_DEPTH_WRITE_ON
					float DepthValue = input.positionCS.z;
				#endif

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				#if defined(LOD_FADE_CROSSFADE)
					LODFadeCrossFade( input.positionCS );
				#endif

				#ifdef ASE_DEPTH_WRITE_ON
					outputDepth = DepthValue;
				#endif

				return 0;
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "Meta"
			Tags { "LightMode"="Meta" }

			Cull Off

			HLSLPROGRAM
			#pragma multi_compile_local_fragment _ALPHATEST_ON
			#define _NORMAL_DROPOFF_TS 1
			#define ASE_FOG 1
			#define _SPECULAR_SETUP 1
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define _NORMALMAP 1
			#define ASE_VERSION 19701
			#define ASE_SRP_VERSION 170003
			#define REQUIRE_OPAQUE_TEXTURE 1
			#define REQUIRE_DEPTH_TEXTURE 1

			#pragma shader_feature EDITOR_VISUALIZATION

			#pragma vertex vert
			#pragma fragment frag

			#if defined(_SPECULAR_SETUP) && defined(_ASE_LIGHTING_SIMPLE)
				#define _SPECULAR_COLOR 1
			#endif

			#define SHADERPASS SHADERPASS_META

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
            #include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRendering.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/DebugMipmapStreamingMacros.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#define ASE_NEEDS_VERT_POSITION
			#define ASE_NEEDS_VERT_NORMAL


			struct Attributes
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float4 texcoord0 : TEXCOORD0;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 ase_tangent : TANGENT;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct PackedVaryings
			{
				float4 positionCS : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 positionWS : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					float4 shadowCoord : TEXCOORD1;
				#endif
				#ifdef EDITOR_VISUALIZATION
					float4 VizUV : TEXCOORD2;
					float4 LightCoord : TEXCOORD3;
				#endif
				float4 ase_texcoord4 : TEXCOORD4;
				float4 ase_texcoord5 : TEXCOORD5;
				float4 ase_texcoord6 : TEXCOORD6;
				float4 ase_texcoord7 : TEXCOORD7;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _ShallowColor;
			float4 _DeepColor;
			float _WaterNormalSpeed;
			float _FresnelOpacityStrength;
			float _FresnelPower;
			float _FresnelScale;
			float _FoamOpacity;
			float _FoamScale;
			float _FoamContrast;
			float _FoamAmount;
			float _Float6;
			float _Float3;
			float _RefractionIntensity;
			float _NormalDetailIntensity;
			float _NormalDetailScale;
			float _NormalIntensity;
			float _NormalMapScale;
			float _WaterSpecularity;
			float _WaterSmoothness;
			#ifdef ASE_TRANSMISSION
				float _TransmissionShadow;
			#endif
			#ifdef ASE_TRANSLUCENCY
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			#ifdef SCENEPICKINGPASS
				float4 _SelectionID;
			#endif

			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif

			sampler2D _NormalMap;
			sampler2D _FoamTexture;


			
			PackedVaryings VertexFunction( Attributes input  )
			{
				PackedVaryings output = (PackedVaryings)0;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

				float4 ase_clipPos = TransformObjectToHClip((input.positionOS).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				output.ase_texcoord4 = screenPos;
				float3 objectToViewPos = TransformWorldToView(TransformObjectToWorld(input.positionOS.xyz));
				float eyeDepth = -objectToViewPos.z;
				output.ase_texcoord5.x = eyeDepth;
				float3 ase_worldTangent = TransformObjectToWorldDir(input.ase_tangent.xyz);
				output.ase_texcoord5.yzw = ase_worldTangent;
				float3 ase_worldNormal = TransformObjectToWorldNormal(input.normalOS);
				output.ase_texcoord6.xyz = ase_worldNormal;
				float ase_vertexTangentSign = input.ase_tangent.w * ( unity_WorldTransformParams.w >= 0.0 ? 1.0 : -1.0 );
				float3 ase_worldBitangent = cross( ase_worldNormal, ase_worldTangent ) * ase_vertexTangentSign;
				output.ase_texcoord7.xyz = ase_worldBitangent;
				
				
				//setting value to unused interpolator channels and avoid initialization warnings
				output.ase_texcoord6.w = 0;
				output.ase_texcoord7.w = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = input.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					input.positionOS.xyz = vertexValue;
				#else
					input.positionOS.xyz += vertexValue;
				#endif

				input.normalOS = input.normalOS;

				float3 positionWS = TransformObjectToWorld( input.positionOS.xyz );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					output.positionWS = positionWS;
				#endif

				output.positionCS = MetaVertexPosition( input.positionOS, input.texcoord1.xy, input.texcoord1.xy, unity_LightmapST, unity_DynamicLightmapST );

				#ifdef EDITOR_VISUALIZATION
					float2 VizUV = 0;
					float4 LightCoord = 0;
					UnityEditorVizData(input.positionOS.xyz, input.texcoord0.xy, input.texcoord1.xy, input.texcoord2.xy, VizUV, LightCoord);
					output.VizUV = float4(VizUV, 0, 0);
					output.LightCoord = LightCoord;
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = output.positionCS;
					output.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				return output;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 normalOS : NORMAL;
				float4 texcoord0 : TEXCOORD0;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 ase_tangent : TANGENT;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( Attributes input )
			{
				VertexControl output;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				output.vertex = input.positionOS;
				output.normalOS = input.normalOS;
				output.texcoord0 = input.texcoord0;
				output.texcoord1 = input.texcoord1;
				output.texcoord2 = input.texcoord2;
				output.ase_tangent = input.ase_tangent;
				return output;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> input)
			{
				TessellationFactors output;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(input[0].vertex, input[1].vertex, input[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(input[0].vertex, input[1].vertex, input[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(input[0].vertex, input[1].vertex, input[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				output.edge[0] = tf.x; output.edge[1] = tf.y; output.edge[2] = tf.z; output.inside = tf.w;
				return output;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			PackedVaryings DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				Attributes output = (Attributes) 0;
				output.positionOS = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				output.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				output.texcoord0 = patch[0].texcoord0 * bary.x + patch[1].texcoord0 * bary.y + patch[2].texcoord0 * bary.z;
				output.texcoord1 = patch[0].texcoord1 * bary.x + patch[1].texcoord1 * bary.y + patch[2].texcoord1 * bary.z;
				output.texcoord2 = patch[0].texcoord2 * bary.x + patch[1].texcoord2 * bary.y + patch[2].texcoord2 * bary.z;
				output.ase_tangent = patch[0].ase_tangent * bary.x + patch[1].ase_tangent * bary.y + patch[2].ase_tangent * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = output.positionOS.xyz - patch[i].normalOS * (dot(output.positionOS.xyz, patch[i].normalOS) - dot(patch[i].vertex.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				output.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * output.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], output);
				return VertexFunction(output);
			}
			#else
			PackedVaryings vert ( Attributes input )
			{
				return VertexFunction( input );
			}
			#endif

			half4 frag(PackedVaryings input  ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( input );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 WorldPosition = input.positionWS;
				#endif

				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = input.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				float4 screenPos = input.ase_texcoord4;
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float4 fetchOpaqueVal419 = float4( SHADERGRAPH_SAMPLE_SCENE_COLOR( ase_screenPosNorm.xy ), 1.0 );
				float temp_output_443_0 = ( 1.0 * 0.6 * _WaterNormalSpeed );
				float temp_output_11_0_g12 = ( temp_output_443_0 * _TimeParameters.x );
				float2 panner44 = ( 1.0 * _Time.y * float2( 0.02,0.1 ) + (( WorldPosition / ( 3.0 * _NormalMapScale ) )).xz);
				float2 temp_output_32_0_g12 = panner44;
				float2 panner5_g12 = ( temp_output_11_0_g12 * float2( 0.1,0.1 ) + temp_output_32_0_g12);
				float temp_output_33_0_g12 = _NormalIntensity;
				float3 unpack3_g12 = UnpackNormalScale( tex2D( _NormalMap, panner5_g12 ), temp_output_33_0_g12 );
				unpack3_g12.z = lerp( 1, unpack3_g12.z, saturate(temp_output_33_0_g12) );
				float2 panner16_g12 = ( temp_output_11_0_g12 * float2( -0.1,-0.1 ) + ( temp_output_32_0_g12 + float2( 0.418,0.355 ) ));
				float3 unpack13_g12 = UnpackNormalScale( tex2D( _NormalMap, panner16_g12 ), temp_output_33_0_g12 );
				unpack13_g12.z = lerp( 1, unpack13_g12.z, saturate(temp_output_33_0_g12) );
				float2 panner19_g12 = ( temp_output_11_0_g12 * float2( -0.1,0.1 ) + ( temp_output_32_0_g12 + float2( 0.865,0.148 ) ));
				float3 unpack20_g12 = UnpackNormalScale( tex2D( _NormalMap, panner19_g12 ), temp_output_33_0_g12 );
				unpack20_g12.z = lerp( 1, unpack20_g12.z, saturate(temp_output_33_0_g12) );
				float2 panner23_g12 = ( temp_output_11_0_g12 * float2( 0.1,-0.1 ) + ( temp_output_32_0_g12 + float2( 0.651,0.752 ) ));
				float3 unpack24_g12 = UnpackNormalScale( tex2D( _NormalMap, panner23_g12 ), temp_output_33_0_g12 );
				unpack24_g12.z = lerp( 1, unpack24_g12.z, saturate(temp_output_33_0_g12) );
				float temp_output_11_0_g13 = ( temp_output_443_0 * _TimeParameters.x );
				float2 panner50 = ( 1.0 * _Time.y * float2( 0.1,0.06 ) + (( WorldPosition / ( 9.0 * _NormalMapScale ) )).xz);
				float2 temp_output_32_0_g13 = panner50;
				float2 panner5_g13 = ( temp_output_11_0_g13 * float2( 0.1,0.1 ) + temp_output_32_0_g13);
				float temp_output_33_0_g13 = _NormalIntensity;
				float3 unpack3_g13 = UnpackNormalScale( tex2D( _NormalMap, panner5_g13 ), temp_output_33_0_g13 );
				unpack3_g13.z = lerp( 1, unpack3_g13.z, saturate(temp_output_33_0_g13) );
				float2 panner16_g13 = ( temp_output_11_0_g13 * float2( -0.1,-0.1 ) + ( temp_output_32_0_g13 + float2( 0.418,0.355 ) ));
				float3 unpack13_g13 = UnpackNormalScale( tex2D( _NormalMap, panner16_g13 ), temp_output_33_0_g13 );
				unpack13_g13.z = lerp( 1, unpack13_g13.z, saturate(temp_output_33_0_g13) );
				float2 panner19_g13 = ( temp_output_11_0_g13 * float2( -0.1,0.1 ) + ( temp_output_32_0_g13 + float2( 0.865,0.148 ) ));
				float3 unpack20_g13 = UnpackNormalScale( tex2D( _NormalMap, panner19_g13 ), temp_output_33_0_g13 );
				unpack20_g13.z = lerp( 1, unpack20_g13.z, saturate(temp_output_33_0_g13) );
				float2 panner23_g13 = ( temp_output_11_0_g13 * float2( 0.1,-0.1 ) + ( temp_output_32_0_g13 + float2( 0.651,0.752 ) ));
				float3 unpack24_g13 = UnpackNormalScale( tex2D( _NormalMap, panner23_g13 ), temp_output_33_0_g13 );
				unpack24_g13.z = lerp( 1, unpack24_g13.z, saturate(temp_output_33_0_g13) );
				float temp_output_11_0_g14 = ( 2.1 * _TimeParameters.x );
				float2 panner453 = ( 1.0 * _Time.y * float2( 0.02,0.1 ) + (( WorldPosition / ( ( 0.5 * _NormalDetailScale ) * _NormalMapScale ) )).xz);
				float2 temp_output_32_0_g14 = panner453;
				float2 panner5_g14 = ( temp_output_11_0_g14 * float2( 0.1,0.1 ) + temp_output_32_0_g14);
				float temp_output_33_0_g14 = _NormalDetailIntensity;
				float3 unpack3_g14 = UnpackNormalScale( tex2D( _NormalMap, panner5_g14 ), temp_output_33_0_g14 );
				unpack3_g14.z = lerp( 1, unpack3_g14.z, saturate(temp_output_33_0_g14) );
				float2 panner16_g14 = ( temp_output_11_0_g14 * float2( -0.1,-0.1 ) + ( temp_output_32_0_g14 + float2( 0.418,0.355 ) ));
				float3 unpack13_g14 = UnpackNormalScale( tex2D( _NormalMap, panner16_g14 ), temp_output_33_0_g14 );
				unpack13_g14.z = lerp( 1, unpack13_g14.z, saturate(temp_output_33_0_g14) );
				float2 panner19_g14 = ( temp_output_11_0_g14 * float2( -0.1,0.1 ) + ( temp_output_32_0_g14 + float2( 0.865,0.148 ) ));
				float3 unpack20_g14 = UnpackNormalScale( tex2D( _NormalMap, panner19_g14 ), temp_output_33_0_g14 );
				unpack20_g14.z = lerp( 1, unpack20_g14.z, saturate(temp_output_33_0_g14) );
				float2 panner23_g14 = ( temp_output_11_0_g14 * float2( 0.1,-0.1 ) + ( temp_output_32_0_g14 + float2( 0.651,0.752 ) ));
				float3 unpack24_g14 = UnpackNormalScale( tex2D( _NormalMap, panner23_g14 ), temp_output_33_0_g14 );
				unpack24_g14.z = lerp( 1, unpack24_g14.z, saturate(temp_output_33_0_g14) );
				float3 WaterNormal274 = BlendNormal( BlendNormal( ( ( ( unpack3_g12 + unpack13_g12 ) + ( unpack20_g12 + unpack24_g12 ) ) * 1.0 ) , ( ( ( unpack3_g13 + unpack13_g13 ) + ( unpack20_g13 + unpack24_g13 ) ) * 1.0 ) ) , ( ( ( unpack3_g14 + unpack13_g14 ) + ( unpack20_g14 + unpack24_g14 ) ) * 0.2 ) );
				float4 temp_output_270_0 = ( ase_screenPosNorm + float4( ( WaterNormal274 * _RefractionIntensity ) , 0.0 ) );
				float4 fetchOpaqueVal271 = float4( SHADERGRAPH_SAMPLE_SCENE_COLOR( temp_output_270_0.xy ), 1.0 );
				float eyeDepth413 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( temp_output_270_0.xy ),_ZBufferParams);
				float eyeDepth = input.ase_texcoord5.x;
				float ifLocalVar414 = 0;
				if( eyeDepth413 > eyeDepth )
				ifLocalVar414 = 1.0;
				else if( eyeDepth413 < eyeDepth )
				ifLocalVar414 = 0.0;
				float4 lerpResult418 = lerp( ( fetchOpaqueVal419 * 0.7 ) , ( fetchOpaqueVal271 * 0.7 ) , ifLocalVar414);
				float4 Refraction281 = lerpResult418;
				float screenDepth316 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy ),_ZBufferParams);
				float distanceDepth316 = ( screenDepth316 - LinearEyeDepth( ase_screenPosNorm.z,_ZBufferParams ) ) / ( _Float3 );
				float clampResult325 = clamp( ( distanceDepth316 * _Float6 ) , 0.0 , 1.0 );
				float4 lerpResult329 = lerp( _ShallowColor , _DeepColor , saturate( clampResult325 ));
				float4 Color362 = lerpResult329;
				float4 color422 = IsGammaSpace() ? float4(0.8679245,0.8679245,0.8679245,0) : float4(0.7254258,0.7254258,0.7254258,0);
				float screenDepth182 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy ),_ZBufferParams);
				float distanceDepth182 = saturate( abs( ( screenDepth182 - LinearEyeDepth( ase_screenPosNorm.z,_ZBufferParams ) ) / ( _FoamAmount ) ) );
				float saferPower188 = abs( ( 1.0 - distanceDepth182 ) );
				float2 panner197 = ( 1.0 * _Time.y * float2( 0.1,0 ) + (( WorldPosition / _FoamScale )).xz);
				float2 panner194 = ( 1.0 * _Time.y * float2( 0.2,0 ) + (( WorldPosition / _FoamScale )).xz);
				float saferPower252 = abs( ( tex2D( _FoamTexture, panner194 ).g * 0.88 ) );
				float2 panner466 = ( 1.0 * _Time.y * float2( 0.15,0.08 ) + (( WorldPosition / 1.0 )).xz);
				float2 panner470 = ( 1.0 * _Time.y * float2( 0.012,0.04 ) + (( WorldPosition / 5.0 )).xz);
				float4 tex2DNode475 = tex2D( _FoamTexture, panner470 );
				float saferPower476 = abs( tex2DNode475.g );
				float FoamFinal420 = saturate( ( ( ( ( ( saturate( pow( saferPower188 , _FoamContrast ) ) - tex2D( _FoamTexture, panner197 ).r ) - saturate( pow( saferPower252 , 0.65 ) ) ) - ( tex2D( _FoamTexture, panner466 ).r * 0.35 ) ) - pow( saferPower476 , 0.5 ) ) * 2.0 ) );
				float4 lerpResult424 = lerp( Color362 , ( color422 + float4( 0,0,0,0 ) ) , ( FoamFinal420 * _FoamOpacity ));
				float3 ase_viewVectorWS = ( _WorldSpaceCameraPos.xyz - WorldPosition );
				float3 ase_viewDirWS = normalize( ase_viewVectorWS );
				float3 ase_worldTangent = input.ase_texcoord5.yzw;
				float3 ase_worldNormal = input.ase_texcoord6.xyz;
				float3 ase_worldBitangent = input.ase_texcoord7.xyz;
				float3 tanToWorld0 = float3( ase_worldTangent.x, ase_worldBitangent.x, ase_worldNormal.x );
				float3 tanToWorld1 = float3( ase_worldTangent.y, ase_worldBitangent.y, ase_worldNormal.y );
				float3 tanToWorld2 = float3( ase_worldTangent.z, ase_worldBitangent.z, ase_worldNormal.z );
				float3 tanNormal384 = WaterNormal274;
				float fresnelNdotV384 = dot( float3(dot(tanToWorld0,tanNormal384), dot(tanToWorld1,tanNormal384), dot(tanToWorld2,tanNormal384)), ase_viewDirWS );
				float fresnelNode384 = ( 0.0 + _FresnelScale * pow( max( 1.0 - fresnelNdotV384 , 0.0001 ), _FresnelPower ) );
				float lerpResult441 = lerp( 1.0 , fresnelNode384 , _FresnelOpacityStrength);
				float ColorOpacity365 = lerpResult329.a;
				float FresnelOpacity402 = ( saturate( lerpResult441 ) * ColorOpacity365 );
				float screenDepth256 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy ),_ZBufferParams);
				float distanceDepth256 = saturate( abs( ( screenDepth256 - LinearEyeDepth( ase_screenPosNorm.z,_ZBufferParams ) ) / ( 0.5 ) ) );
				float saferPower258 = abs( distanceDepth256 );
				float WaterEdge428 = saturate( pow( saferPower258 , 1.5 ) );
				float4 lerpResult493 = lerp( Refraction281 , lerpResult424 , ( FresnelOpacity402 * WaterEdge428 ));
				

				float3 BaseColor = lerpResult493.rgb;
				float3 Emission = 0;
				float Alpha = WaterEdge428;
				float AlphaClipThreshold = 0.5;

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				MetaInput metaInput = (MetaInput)0;
				metaInput.Albedo = BaseColor;
				metaInput.Emission = Emission;
				#ifdef EDITOR_VISUALIZATION
					metaInput.VizUV = input.VizUV.xy;
					metaInput.LightCoord = input.LightCoord;
				#endif

				return UnityMetaFragment(metaInput);
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "Universal2D"
			Tags { "LightMode"="Universal2D" }

			Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
			ZWrite Off
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA

			HLSLPROGRAM

			#pragma multi_compile_local_fragment _ALPHATEST_ON
			#define _NORMAL_DROPOFF_TS 1
			#define ASE_FOG 1
			#define _SPECULAR_SETUP 1
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define _NORMALMAP 1
			#define ASE_VERSION 19701
			#define ASE_SRP_VERSION 170003
			#define REQUIRE_OPAQUE_TEXTURE 1
			#define REQUIRE_DEPTH_TEXTURE 1


			#pragma vertex vert
			#pragma fragment frag

			#if defined(_SPECULAR_SETUP) && defined(_ASE_LIGHTING_SIMPLE)
				#define _SPECULAR_COLOR 1
			#endif

			#define SHADERPASS SHADERPASS_2D

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
            #include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRendering.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/DebugMipmapStreamingMacros.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#define ASE_NEEDS_VERT_POSITION
			#define ASE_NEEDS_VERT_NORMAL


			struct Attributes
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float4 ase_tangent : TANGENT;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct PackedVaryings
			{
				float4 positionCS : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 positionWS : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					float4 shadowCoord : TEXCOORD1;
				#endif
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_texcoord4 : TEXCOORD4;
				float4 ase_texcoord5 : TEXCOORD5;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _ShallowColor;
			float4 _DeepColor;
			float _WaterNormalSpeed;
			float _FresnelOpacityStrength;
			float _FresnelPower;
			float _FresnelScale;
			float _FoamOpacity;
			float _FoamScale;
			float _FoamContrast;
			float _FoamAmount;
			float _Float6;
			float _Float3;
			float _RefractionIntensity;
			float _NormalDetailIntensity;
			float _NormalDetailScale;
			float _NormalIntensity;
			float _NormalMapScale;
			float _WaterSpecularity;
			float _WaterSmoothness;
			#ifdef ASE_TRANSMISSION
				float _TransmissionShadow;
			#endif
			#ifdef ASE_TRANSLUCENCY
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			#ifdef SCENEPICKINGPASS
				float4 _SelectionID;
			#endif

			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif

			sampler2D _NormalMap;
			sampler2D _FoamTexture;


			
			PackedVaryings VertexFunction( Attributes input  )
			{
				PackedVaryings output = (PackedVaryings)0;
				UNITY_SETUP_INSTANCE_ID( input );
				UNITY_TRANSFER_INSTANCE_ID( input, output );
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( output );

				float4 ase_clipPos = TransformObjectToHClip((input.positionOS).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				output.ase_texcoord2 = screenPos;
				float3 objectToViewPos = TransformWorldToView(TransformObjectToWorld(input.positionOS.xyz));
				float eyeDepth = -objectToViewPos.z;
				output.ase_texcoord3.x = eyeDepth;
				float3 ase_worldTangent = TransformObjectToWorldDir(input.ase_tangent.xyz);
				output.ase_texcoord3.yzw = ase_worldTangent;
				float3 ase_worldNormal = TransformObjectToWorldNormal(input.normalOS);
				output.ase_texcoord4.xyz = ase_worldNormal;
				float ase_vertexTangentSign = input.ase_tangent.w * ( unity_WorldTransformParams.w >= 0.0 ? 1.0 : -1.0 );
				float3 ase_worldBitangent = cross( ase_worldNormal, ase_worldTangent ) * ase_vertexTangentSign;
				output.ase_texcoord5.xyz = ase_worldBitangent;
				
				
				//setting value to unused interpolator channels and avoid initialization warnings
				output.ase_texcoord4.w = 0;
				output.ase_texcoord5.w = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = input.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					input.positionOS.xyz = vertexValue;
				#else
					input.positionOS.xyz += vertexValue;
				#endif

				input.normalOS = input.normalOS;

				VertexPositionInputs vertexInput = GetVertexPositionInputs( input.positionOS.xyz );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					output.positionWS = vertexInput.positionWS;
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					output.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				output.positionCS = vertexInput.positionCS;

				return output;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 normalOS : NORMAL;
				float4 ase_tangent : TANGENT;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( Attributes input )
			{
				VertexControl output;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				output.vertex = input.positionOS;
				output.normalOS = input.normalOS;
				output.ase_tangent = input.ase_tangent;
				return output;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> input)
			{
				TessellationFactors output;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(input[0].vertex, input[1].vertex, input[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(input[0].vertex, input[1].vertex, input[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(input[0].vertex, input[1].vertex, input[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				output.edge[0] = tf.x; output.edge[1] = tf.y; output.edge[2] = tf.z; output.inside = tf.w;
				return output;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			PackedVaryings DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				Attributes output = (Attributes) 0;
				output.positionOS = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				output.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				output.ase_tangent = patch[0].ase_tangent * bary.x + patch[1].ase_tangent * bary.y + patch[2].ase_tangent * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = output.positionOS.xyz - patch[i].normalOS * (dot(output.positionOS.xyz, patch[i].normalOS) - dot(patch[i].vertex.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				output.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * output.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], output);
				return VertexFunction(output);
			}
			#else
			PackedVaryings vert ( Attributes input )
			{
				return VertexFunction( input );
			}
			#endif

			half4 frag(PackedVaryings input  ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID( input );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( input );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 WorldPosition = input.positionWS;
				#endif

				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = input.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				float4 screenPos = input.ase_texcoord2;
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float4 fetchOpaqueVal419 = float4( SHADERGRAPH_SAMPLE_SCENE_COLOR( ase_screenPosNorm.xy ), 1.0 );
				float temp_output_443_0 = ( 1.0 * 0.6 * _WaterNormalSpeed );
				float temp_output_11_0_g12 = ( temp_output_443_0 * _TimeParameters.x );
				float2 panner44 = ( 1.0 * _Time.y * float2( 0.02,0.1 ) + (( WorldPosition / ( 3.0 * _NormalMapScale ) )).xz);
				float2 temp_output_32_0_g12 = panner44;
				float2 panner5_g12 = ( temp_output_11_0_g12 * float2( 0.1,0.1 ) + temp_output_32_0_g12);
				float temp_output_33_0_g12 = _NormalIntensity;
				float3 unpack3_g12 = UnpackNormalScale( tex2D( _NormalMap, panner5_g12 ), temp_output_33_0_g12 );
				unpack3_g12.z = lerp( 1, unpack3_g12.z, saturate(temp_output_33_0_g12) );
				float2 panner16_g12 = ( temp_output_11_0_g12 * float2( -0.1,-0.1 ) + ( temp_output_32_0_g12 + float2( 0.418,0.355 ) ));
				float3 unpack13_g12 = UnpackNormalScale( tex2D( _NormalMap, panner16_g12 ), temp_output_33_0_g12 );
				unpack13_g12.z = lerp( 1, unpack13_g12.z, saturate(temp_output_33_0_g12) );
				float2 panner19_g12 = ( temp_output_11_0_g12 * float2( -0.1,0.1 ) + ( temp_output_32_0_g12 + float2( 0.865,0.148 ) ));
				float3 unpack20_g12 = UnpackNormalScale( tex2D( _NormalMap, panner19_g12 ), temp_output_33_0_g12 );
				unpack20_g12.z = lerp( 1, unpack20_g12.z, saturate(temp_output_33_0_g12) );
				float2 panner23_g12 = ( temp_output_11_0_g12 * float2( 0.1,-0.1 ) + ( temp_output_32_0_g12 + float2( 0.651,0.752 ) ));
				float3 unpack24_g12 = UnpackNormalScale( tex2D( _NormalMap, panner23_g12 ), temp_output_33_0_g12 );
				unpack24_g12.z = lerp( 1, unpack24_g12.z, saturate(temp_output_33_0_g12) );
				float temp_output_11_0_g13 = ( temp_output_443_0 * _TimeParameters.x );
				float2 panner50 = ( 1.0 * _Time.y * float2( 0.1,0.06 ) + (( WorldPosition / ( 9.0 * _NormalMapScale ) )).xz);
				float2 temp_output_32_0_g13 = panner50;
				float2 panner5_g13 = ( temp_output_11_0_g13 * float2( 0.1,0.1 ) + temp_output_32_0_g13);
				float temp_output_33_0_g13 = _NormalIntensity;
				float3 unpack3_g13 = UnpackNormalScale( tex2D( _NormalMap, panner5_g13 ), temp_output_33_0_g13 );
				unpack3_g13.z = lerp( 1, unpack3_g13.z, saturate(temp_output_33_0_g13) );
				float2 panner16_g13 = ( temp_output_11_0_g13 * float2( -0.1,-0.1 ) + ( temp_output_32_0_g13 + float2( 0.418,0.355 ) ));
				float3 unpack13_g13 = UnpackNormalScale( tex2D( _NormalMap, panner16_g13 ), temp_output_33_0_g13 );
				unpack13_g13.z = lerp( 1, unpack13_g13.z, saturate(temp_output_33_0_g13) );
				float2 panner19_g13 = ( temp_output_11_0_g13 * float2( -0.1,0.1 ) + ( temp_output_32_0_g13 + float2( 0.865,0.148 ) ));
				float3 unpack20_g13 = UnpackNormalScale( tex2D( _NormalMap, panner19_g13 ), temp_output_33_0_g13 );
				unpack20_g13.z = lerp( 1, unpack20_g13.z, saturate(temp_output_33_0_g13) );
				float2 panner23_g13 = ( temp_output_11_0_g13 * float2( 0.1,-0.1 ) + ( temp_output_32_0_g13 + float2( 0.651,0.752 ) ));
				float3 unpack24_g13 = UnpackNormalScale( tex2D( _NormalMap, panner23_g13 ), temp_output_33_0_g13 );
				unpack24_g13.z = lerp( 1, unpack24_g13.z, saturate(temp_output_33_0_g13) );
				float temp_output_11_0_g14 = ( 2.1 * _TimeParameters.x );
				float2 panner453 = ( 1.0 * _Time.y * float2( 0.02,0.1 ) + (( WorldPosition / ( ( 0.5 * _NormalDetailScale ) * _NormalMapScale ) )).xz);
				float2 temp_output_32_0_g14 = panner453;
				float2 panner5_g14 = ( temp_output_11_0_g14 * float2( 0.1,0.1 ) + temp_output_32_0_g14);
				float temp_output_33_0_g14 = _NormalDetailIntensity;
				float3 unpack3_g14 = UnpackNormalScale( tex2D( _NormalMap, panner5_g14 ), temp_output_33_0_g14 );
				unpack3_g14.z = lerp( 1, unpack3_g14.z, saturate(temp_output_33_0_g14) );
				float2 panner16_g14 = ( temp_output_11_0_g14 * float2( -0.1,-0.1 ) + ( temp_output_32_0_g14 + float2( 0.418,0.355 ) ));
				float3 unpack13_g14 = UnpackNormalScale( tex2D( _NormalMap, panner16_g14 ), temp_output_33_0_g14 );
				unpack13_g14.z = lerp( 1, unpack13_g14.z, saturate(temp_output_33_0_g14) );
				float2 panner19_g14 = ( temp_output_11_0_g14 * float2( -0.1,0.1 ) + ( temp_output_32_0_g14 + float2( 0.865,0.148 ) ));
				float3 unpack20_g14 = UnpackNormalScale( tex2D( _NormalMap, panner19_g14 ), temp_output_33_0_g14 );
				unpack20_g14.z = lerp( 1, unpack20_g14.z, saturate(temp_output_33_0_g14) );
				float2 panner23_g14 = ( temp_output_11_0_g14 * float2( 0.1,-0.1 ) + ( temp_output_32_0_g14 + float2( 0.651,0.752 ) ));
				float3 unpack24_g14 = UnpackNormalScale( tex2D( _NormalMap, panner23_g14 ), temp_output_33_0_g14 );
				unpack24_g14.z = lerp( 1, unpack24_g14.z, saturate(temp_output_33_0_g14) );
				float3 WaterNormal274 = BlendNormal( BlendNormal( ( ( ( unpack3_g12 + unpack13_g12 ) + ( unpack20_g12 + unpack24_g12 ) ) * 1.0 ) , ( ( ( unpack3_g13 + unpack13_g13 ) + ( unpack20_g13 + unpack24_g13 ) ) * 1.0 ) ) , ( ( ( unpack3_g14 + unpack13_g14 ) + ( unpack20_g14 + unpack24_g14 ) ) * 0.2 ) );
				float4 temp_output_270_0 = ( ase_screenPosNorm + float4( ( WaterNormal274 * _RefractionIntensity ) , 0.0 ) );
				float4 fetchOpaqueVal271 = float4( SHADERGRAPH_SAMPLE_SCENE_COLOR( temp_output_270_0.xy ), 1.0 );
				float eyeDepth413 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( temp_output_270_0.xy ),_ZBufferParams);
				float eyeDepth = input.ase_texcoord3.x;
				float ifLocalVar414 = 0;
				if( eyeDepth413 > eyeDepth )
				ifLocalVar414 = 1.0;
				else if( eyeDepth413 < eyeDepth )
				ifLocalVar414 = 0.0;
				float4 lerpResult418 = lerp( ( fetchOpaqueVal419 * 0.7 ) , ( fetchOpaqueVal271 * 0.7 ) , ifLocalVar414);
				float4 Refraction281 = lerpResult418;
				float screenDepth316 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy ),_ZBufferParams);
				float distanceDepth316 = ( screenDepth316 - LinearEyeDepth( ase_screenPosNorm.z,_ZBufferParams ) ) / ( _Float3 );
				float clampResult325 = clamp( ( distanceDepth316 * _Float6 ) , 0.0 , 1.0 );
				float4 lerpResult329 = lerp( _ShallowColor , _DeepColor , saturate( clampResult325 ));
				float4 Color362 = lerpResult329;
				float4 color422 = IsGammaSpace() ? float4(0.8679245,0.8679245,0.8679245,0) : float4(0.7254258,0.7254258,0.7254258,0);
				float screenDepth182 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy ),_ZBufferParams);
				float distanceDepth182 = saturate( abs( ( screenDepth182 - LinearEyeDepth( ase_screenPosNorm.z,_ZBufferParams ) ) / ( _FoamAmount ) ) );
				float saferPower188 = abs( ( 1.0 - distanceDepth182 ) );
				float2 panner197 = ( 1.0 * _Time.y * float2( 0.1,0 ) + (( WorldPosition / _FoamScale )).xz);
				float2 panner194 = ( 1.0 * _Time.y * float2( 0.2,0 ) + (( WorldPosition / _FoamScale )).xz);
				float saferPower252 = abs( ( tex2D( _FoamTexture, panner194 ).g * 0.88 ) );
				float2 panner466 = ( 1.0 * _Time.y * float2( 0.15,0.08 ) + (( WorldPosition / 1.0 )).xz);
				float2 panner470 = ( 1.0 * _Time.y * float2( 0.012,0.04 ) + (( WorldPosition / 5.0 )).xz);
				float4 tex2DNode475 = tex2D( _FoamTexture, panner470 );
				float saferPower476 = abs( tex2DNode475.g );
				float FoamFinal420 = saturate( ( ( ( ( ( saturate( pow( saferPower188 , _FoamContrast ) ) - tex2D( _FoamTexture, panner197 ).r ) - saturate( pow( saferPower252 , 0.65 ) ) ) - ( tex2D( _FoamTexture, panner466 ).r * 0.35 ) ) - pow( saferPower476 , 0.5 ) ) * 2.0 ) );
				float4 lerpResult424 = lerp( Color362 , ( color422 + float4( 0,0,0,0 ) ) , ( FoamFinal420 * _FoamOpacity ));
				float3 ase_viewVectorWS = ( _WorldSpaceCameraPos.xyz - WorldPosition );
				float3 ase_viewDirWS = normalize( ase_viewVectorWS );
				float3 ase_worldTangent = input.ase_texcoord3.yzw;
				float3 ase_worldNormal = input.ase_texcoord4.xyz;
				float3 ase_worldBitangent = input.ase_texcoord5.xyz;
				float3 tanToWorld0 = float3( ase_worldTangent.x, ase_worldBitangent.x, ase_worldNormal.x );
				float3 tanToWorld1 = float3( ase_worldTangent.y, ase_worldBitangent.y, ase_worldNormal.y );
				float3 tanToWorld2 = float3( ase_worldTangent.z, ase_worldBitangent.z, ase_worldNormal.z );
				float3 tanNormal384 = WaterNormal274;
				float fresnelNdotV384 = dot( float3(dot(tanToWorld0,tanNormal384), dot(tanToWorld1,tanNormal384), dot(tanToWorld2,tanNormal384)), ase_viewDirWS );
				float fresnelNode384 = ( 0.0 + _FresnelScale * pow( max( 1.0 - fresnelNdotV384 , 0.0001 ), _FresnelPower ) );
				float lerpResult441 = lerp( 1.0 , fresnelNode384 , _FresnelOpacityStrength);
				float ColorOpacity365 = lerpResult329.a;
				float FresnelOpacity402 = ( saturate( lerpResult441 ) * ColorOpacity365 );
				float screenDepth256 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy ),_ZBufferParams);
				float distanceDepth256 = saturate( abs( ( screenDepth256 - LinearEyeDepth( ase_screenPosNorm.z,_ZBufferParams ) ) / ( 0.5 ) ) );
				float saferPower258 = abs( distanceDepth256 );
				float WaterEdge428 = saturate( pow( saferPower258 , 1.5 ) );
				float4 lerpResult493 = lerp( Refraction281 , lerpResult424 , ( FresnelOpacity402 * WaterEdge428 ));
				

				float3 BaseColor = lerpResult493.rgb;
				float Alpha = WaterEdge428;
				float AlphaClipThreshold = 0.5;

				half4 color = half4(BaseColor, Alpha );

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				return color;
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "DepthNormals"
			Tags { "LightMode"="DepthNormals" }

			ZWrite On
			Blend One Zero
			ZTest LEqual
			ZWrite On

			HLSLPROGRAM

			#pragma multi_compile_local_fragment _ALPHATEST_ON
			#define _NORMAL_DROPOFF_TS 1
			#define ASE_FOG 1
			#define _SPECULAR_SETUP 1
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define _NORMALMAP 1
			#define ASE_VERSION 19701
			#define ASE_SRP_VERSION 170003
			#define REQUIRE_DEPTH_TEXTURE 1


			#pragma vertex vert
			#pragma fragment frag

			#if defined(_SPECULAR_SETUP) && defined(_ASE_LIGHTING_SIMPLE)
				#define _SPECULAR_COLOR 1
			#endif

			#define SHADERPASS SHADERPASS_DEPTHNORMALSONLY
			//#define SHADERPASS SHADERPASS_DEPTHNORMALS

			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
            #include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRendering.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/DebugMipmapStreamingMacros.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#if defined(LOD_FADE_CROSSFADE)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#define ASE_NEEDS_FRAG_SCREEN_POSITION


			#if defined(ASE_EARLY_Z_DEPTH_OPTIMIZE) && (SHADER_TARGET >= 45)
				#define ASE_SV_DEPTH SV_DepthLessEqual
				#define ASE_SV_POSITION_QUALIFIERS linear noperspective centroid
			#else
				#define ASE_SV_DEPTH SV_Depth
				#define ASE_SV_POSITION_QUALIFIERS
			#endif

			struct Attributes
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float4 tangentOS : TANGENT;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct PackedVaryings
			{
				ASE_SV_POSITION_QUALIFIERS float4 positionCS : SV_POSITION;
				float4 clipPosV : TEXCOORD0;
				float3 worldNormal : TEXCOORD1;
				float4 worldTangent : TEXCOORD2;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 positionWS : TEXCOORD3;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					float4 shadowCoord : TEXCOORD4;
				#endif
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _ShallowColor;
			float4 _DeepColor;
			float _WaterNormalSpeed;
			float _FresnelOpacityStrength;
			float _FresnelPower;
			float _FresnelScale;
			float _FoamOpacity;
			float _FoamScale;
			float _FoamContrast;
			float _FoamAmount;
			float _Float6;
			float _Float3;
			float _RefractionIntensity;
			float _NormalDetailIntensity;
			float _NormalDetailScale;
			float _NormalIntensity;
			float _NormalMapScale;
			float _WaterSpecularity;
			float _WaterSmoothness;
			#ifdef ASE_TRANSMISSION
				float _TransmissionShadow;
			#endif
			#ifdef ASE_TRANSLUCENCY
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			#ifdef SCENEPICKINGPASS
				float4 _SelectionID;
			#endif

			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif

			sampler2D _NormalMap;


			
			PackedVaryings VertexFunction( Attributes input  )
			{
				PackedVaryings output = (PackedVaryings)0;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

				
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = input.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					input.positionOS.xyz = vertexValue;
				#else
					input.positionOS.xyz += vertexValue;
				#endif

				input.normalOS = input.normalOS;
				input.tangentOS = input.tangentOS;

				VertexPositionInputs vertexInput = GetVertexPositionInputs( input.positionOS.xyz );

				float3 normalWS = TransformObjectToWorldNormal( input.normalOS );
				float4 tangentWS = float4( TransformObjectToWorldDir( input.tangentOS.xyz ), input.tangentOS.w );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					output.positionWS = vertexInput.positionWS;
				#endif

				output.worldNormal = normalWS;
				output.worldTangent = tangentWS;

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					output.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				output.positionCS = vertexInput.positionCS;
				output.clipPosV = vertexInput.positionCS;
				return output;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 normalOS : NORMAL;
				float4 tangentOS : TANGENT;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( Attributes input )
			{
				VertexControl output;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				output.vertex = input.positionOS;
				output.normalOS = input.normalOS;
				output.tangentOS = input.tangentOS;
				
				return output;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> input)
			{
				TessellationFactors output;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(input[0].vertex, input[1].vertex, input[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(input[0].vertex, input[1].vertex, input[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(input[0].vertex, input[1].vertex, input[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				output.edge[0] = tf.x; output.edge[1] = tf.y; output.edge[2] = tf.z; output.inside = tf.w;
				return output;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			PackedVaryings DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				Attributes output = (Attributes) 0;
				output.positionOS = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				output.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				output.tangentOS = patch[0].tangentOS * bary.x + patch[1].tangentOS * bary.y + patch[2].tangentOS * bary.z;
				
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = output.positionOS.xyz - patch[i].normalOS * (dot(output.positionOS.xyz, patch[i].normalOS) - dot(patch[i].vertex.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				output.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * output.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], output);
				return VertexFunction(output);
			}
			#else
			PackedVaryings vert ( Attributes input )
			{
				return VertexFunction( input );
			}
			#endif

			void frag(	PackedVaryings input
						, out half4 outNormalWS : SV_Target0
						#ifdef ASE_DEPTH_WRITE_ON
						,out float outputDepth : ASE_SV_DEPTH
						#endif
						#ifdef _WRITE_RENDERING_LAYERS
						, out float4 outRenderingLayers : SV_Target1
						#endif
						 )
			{
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( input );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 WorldPosition = input.positionWS;
				#endif

				float4 ShadowCoords = float4( 0, 0, 0, 0 );
				float3 WorldNormal = input.worldNormal;
				float4 WorldTangent = input.worldTangent;

				float4 ClipPos = input.clipPosV;
				float4 ScreenPos = ComputeScreenPos( input.clipPosV );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = input.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				float temp_output_443_0 = ( 1.0 * 0.6 * _WaterNormalSpeed );
				float temp_output_11_0_g12 = ( temp_output_443_0 * _TimeParameters.x );
				float2 panner44 = ( 1.0 * _Time.y * float2( 0.02,0.1 ) + (( WorldPosition / ( 3.0 * _NormalMapScale ) )).xz);
				float2 temp_output_32_0_g12 = panner44;
				float2 panner5_g12 = ( temp_output_11_0_g12 * float2( 0.1,0.1 ) + temp_output_32_0_g12);
				float temp_output_33_0_g12 = _NormalIntensity;
				float3 unpack3_g12 = UnpackNormalScale( tex2D( _NormalMap, panner5_g12 ), temp_output_33_0_g12 );
				unpack3_g12.z = lerp( 1, unpack3_g12.z, saturate(temp_output_33_0_g12) );
				float2 panner16_g12 = ( temp_output_11_0_g12 * float2( -0.1,-0.1 ) + ( temp_output_32_0_g12 + float2( 0.418,0.355 ) ));
				float3 unpack13_g12 = UnpackNormalScale( tex2D( _NormalMap, panner16_g12 ), temp_output_33_0_g12 );
				unpack13_g12.z = lerp( 1, unpack13_g12.z, saturate(temp_output_33_0_g12) );
				float2 panner19_g12 = ( temp_output_11_0_g12 * float2( -0.1,0.1 ) + ( temp_output_32_0_g12 + float2( 0.865,0.148 ) ));
				float3 unpack20_g12 = UnpackNormalScale( tex2D( _NormalMap, panner19_g12 ), temp_output_33_0_g12 );
				unpack20_g12.z = lerp( 1, unpack20_g12.z, saturate(temp_output_33_0_g12) );
				float2 panner23_g12 = ( temp_output_11_0_g12 * float2( 0.1,-0.1 ) + ( temp_output_32_0_g12 + float2( 0.651,0.752 ) ));
				float3 unpack24_g12 = UnpackNormalScale( tex2D( _NormalMap, panner23_g12 ), temp_output_33_0_g12 );
				unpack24_g12.z = lerp( 1, unpack24_g12.z, saturate(temp_output_33_0_g12) );
				float temp_output_11_0_g13 = ( temp_output_443_0 * _TimeParameters.x );
				float2 panner50 = ( 1.0 * _Time.y * float2( 0.1,0.06 ) + (( WorldPosition / ( 9.0 * _NormalMapScale ) )).xz);
				float2 temp_output_32_0_g13 = panner50;
				float2 panner5_g13 = ( temp_output_11_0_g13 * float2( 0.1,0.1 ) + temp_output_32_0_g13);
				float temp_output_33_0_g13 = _NormalIntensity;
				float3 unpack3_g13 = UnpackNormalScale( tex2D( _NormalMap, panner5_g13 ), temp_output_33_0_g13 );
				unpack3_g13.z = lerp( 1, unpack3_g13.z, saturate(temp_output_33_0_g13) );
				float2 panner16_g13 = ( temp_output_11_0_g13 * float2( -0.1,-0.1 ) + ( temp_output_32_0_g13 + float2( 0.418,0.355 ) ));
				float3 unpack13_g13 = UnpackNormalScale( tex2D( _NormalMap, panner16_g13 ), temp_output_33_0_g13 );
				unpack13_g13.z = lerp( 1, unpack13_g13.z, saturate(temp_output_33_0_g13) );
				float2 panner19_g13 = ( temp_output_11_0_g13 * float2( -0.1,0.1 ) + ( temp_output_32_0_g13 + float2( 0.865,0.148 ) ));
				float3 unpack20_g13 = UnpackNormalScale( tex2D( _NormalMap, panner19_g13 ), temp_output_33_0_g13 );
				unpack20_g13.z = lerp( 1, unpack20_g13.z, saturate(temp_output_33_0_g13) );
				float2 panner23_g13 = ( temp_output_11_0_g13 * float2( 0.1,-0.1 ) + ( temp_output_32_0_g13 + float2( 0.651,0.752 ) ));
				float3 unpack24_g13 = UnpackNormalScale( tex2D( _NormalMap, panner23_g13 ), temp_output_33_0_g13 );
				unpack24_g13.z = lerp( 1, unpack24_g13.z, saturate(temp_output_33_0_g13) );
				float temp_output_11_0_g14 = ( 2.1 * _TimeParameters.x );
				float2 panner453 = ( 1.0 * _Time.y * float2( 0.02,0.1 ) + (( WorldPosition / ( ( 0.5 * _NormalDetailScale ) * _NormalMapScale ) )).xz);
				float2 temp_output_32_0_g14 = panner453;
				float2 panner5_g14 = ( temp_output_11_0_g14 * float2( 0.1,0.1 ) + temp_output_32_0_g14);
				float temp_output_33_0_g14 = _NormalDetailIntensity;
				float3 unpack3_g14 = UnpackNormalScale( tex2D( _NormalMap, panner5_g14 ), temp_output_33_0_g14 );
				unpack3_g14.z = lerp( 1, unpack3_g14.z, saturate(temp_output_33_0_g14) );
				float2 panner16_g14 = ( temp_output_11_0_g14 * float2( -0.1,-0.1 ) + ( temp_output_32_0_g14 + float2( 0.418,0.355 ) ));
				float3 unpack13_g14 = UnpackNormalScale( tex2D( _NormalMap, panner16_g14 ), temp_output_33_0_g14 );
				unpack13_g14.z = lerp( 1, unpack13_g14.z, saturate(temp_output_33_0_g14) );
				float2 panner19_g14 = ( temp_output_11_0_g14 * float2( -0.1,0.1 ) + ( temp_output_32_0_g14 + float2( 0.865,0.148 ) ));
				float3 unpack20_g14 = UnpackNormalScale( tex2D( _NormalMap, panner19_g14 ), temp_output_33_0_g14 );
				unpack20_g14.z = lerp( 1, unpack20_g14.z, saturate(temp_output_33_0_g14) );
				float2 panner23_g14 = ( temp_output_11_0_g14 * float2( 0.1,-0.1 ) + ( temp_output_32_0_g14 + float2( 0.651,0.752 ) ));
				float3 unpack24_g14 = UnpackNormalScale( tex2D( _NormalMap, panner23_g14 ), temp_output_33_0_g14 );
				unpack24_g14.z = lerp( 1, unpack24_g14.z, saturate(temp_output_33_0_g14) );
				float3 WaterNormal274 = BlendNormal( BlendNormal( ( ( ( unpack3_g12 + unpack13_g12 ) + ( unpack20_g12 + unpack24_g12 ) ) * 1.0 ) , ( ( ( unpack3_g13 + unpack13_g13 ) + ( unpack20_g13 + unpack24_g13 ) ) * 1.0 ) ) , ( ( ( unpack3_g14 + unpack13_g14 ) + ( unpack20_g14 + unpack24_g14 ) ) * 0.2 ) );
				
				float4 ase_screenPosNorm = ScreenPos / ScreenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float screenDepth256 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy ),_ZBufferParams);
				float distanceDepth256 = saturate( abs( ( screenDepth256 - LinearEyeDepth( ase_screenPosNorm.z,_ZBufferParams ) ) / ( 0.5 ) ) );
				float saferPower258 = abs( distanceDepth256 );
				float WaterEdge428 = saturate( pow( saferPower258 , 1.5 ) );
				

				float3 Normal = WaterNormal274;
				float Alpha = WaterEdge428;
				float AlphaClipThreshold = 0.5;

				#ifdef ASE_DEPTH_WRITE_ON
					float DepthValue = input.positionCS.z;
				#endif

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				#if defined(LOD_FADE_CROSSFADE)
					LODFadeCrossFade( input.positionCS );
				#endif

				#ifdef ASE_DEPTH_WRITE_ON
					outputDepth = DepthValue;
				#endif

				#if defined(_GBUFFER_NORMALS_OCT)
					float2 octNormalWS = PackNormalOctQuadEncode(WorldNormal);
					float2 remappedOctNormalWS = saturate(octNormalWS * 0.5 + 0.5);
					half3 packedNormalWS = PackFloat2To888(remappedOctNormalWS);
					outNormalWS = half4(packedNormalWS, 0.0);
				#else
					#if defined(_NORMALMAP)
						#if _NORMAL_DROPOFF_TS
							float crossSign = (WorldTangent.w > 0.0 ? 1.0 : -1.0) * GetOddNegativeScale();
							float3 bitangent = crossSign * cross(WorldNormal.xyz, WorldTangent.xyz);
							float3 normalWS = TransformTangentToWorld(Normal, half3x3(WorldTangent.xyz, bitangent, WorldNormal.xyz));
						#elif _NORMAL_DROPOFF_OS
							float3 normalWS = TransformObjectToWorldNormal(Normal);
						#elif _NORMAL_DROPOFF_WS
							float3 normalWS = Normal;
						#endif
					#else
						float3 normalWS = WorldNormal;
					#endif
					outNormalWS = half4(NormalizeNormalPerPixel(normalWS), 0.0);
				#endif

				#ifdef _WRITE_RENDERING_LAYERS
					uint renderingLayers = GetMeshRenderingLayer();
					outRenderingLayers = float4( EncodeMeshRenderingLayer( renderingLayers ), 0, 0, 0 );
				#endif
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "GBuffer"
			Tags { "LightMode"="UniversalGBuffer" }

			Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
			ZWrite Off
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA
			

			HLSLPROGRAM

			#pragma multi_compile_local_fragment _ALPHATEST_ON
			#define _NORMAL_DROPOFF_TS 1
			#pragma shader_feature_local _RECEIVE_SHADOWS_OFF
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define _SPECULAR_SETUP 1
			#pragma shader_feature_local_fragment _SPECULARHIGHLIGHTS_OFF
			#pragma shader_feature_local_fragment _ENVIRONMENTREFLECTIONS_OFF
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define _NORMALMAP 1
			#define ASE_VERSION 19701
			#define ASE_SRP_VERSION 170003
			#define REQUIRE_OPAQUE_TEXTURE 1
			#define REQUIRE_DEPTH_TEXTURE 1


			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
			#pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
			#pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
			#pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
			#pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
			#pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT
			#pragma multi_compile_fragment _ _RENDER_PASS_ENABLED

			#pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
			#pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
			#pragma multi_compile _ SHADOWS_SHADOWMASK
			#pragma multi_compile _ DIRLIGHTMAP_COMBINED
			#pragma multi_compile _ USE_LEGACY_LIGHTMAPS
			#pragma multi_compile _ LIGHTMAP_ON
			#pragma multi_compile _ DYNAMICLIGHTMAP_ON
			#pragma multi_compile_fragment _ DEBUG_DISPLAY

			#pragma vertex vert
			#pragma fragment frag

			#if defined(_SPECULAR_SETUP) && defined(_ASE_LIGHTING_SIMPLE)
				#define _SPECULAR_COLOR 1
			#endif

			#define SHADERPASS SHADERPASS_GBUFFER

			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ProbeVolumeVariants.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
            #include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRendering.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/DebugMipmapStreamingMacros.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#if defined(LOD_FADE_CROSSFADE)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif
			
			#if defined(UNITY_INSTANCING_ENABLED) && defined(_TERRAIN_INSTANCED_PERPIXEL_NORMAL)
				#define ENABLE_TERRAIN_PERPIXEL_NORMAL
			#endif

			#define ASE_NEEDS_FRAG_SCREEN_POSITION
			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#define ASE_NEEDS_VERT_POSITION
			#define ASE_NEEDS_FRAG_WORLD_TANGENT
			#define ASE_NEEDS_FRAG_WORLD_NORMAL
			#define ASE_NEEDS_FRAG_WORLD_BITANGENT


			#if defined(ASE_EARLY_Z_DEPTH_OPTIMIZE) && (SHADER_TARGET >= 45)
				#define ASE_SV_DEPTH SV_DepthLessEqual
				#define ASE_SV_POSITION_QUALIFIERS linear noperspective centroid
			#else
				#define ASE_SV_DEPTH SV_Depth
				#define ASE_SV_POSITION_QUALIFIERS
			#endif

			struct Attributes
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float4 tangentOS : TANGENT;
				float4 texcoord : TEXCOORD0;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct PackedVaryings
			{
				ASE_SV_POSITION_QUALIFIERS float4 positionCS : SV_POSITION;
				float4 clipPosV : TEXCOORD0;
				float4 lightmapUVOrVertexSH : TEXCOORD1;
				half4 fogFactorAndVertexLight : TEXCOORD2;
				float4 tSpace0 : TEXCOORD3;
				float4 tSpace1 : TEXCOORD4;
				float4 tSpace2 : TEXCOORD5;
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
				float4 shadowCoord : TEXCOORD6;
				#endif
				#if defined(DYNAMICLIGHTMAP_ON)
				float2 dynamicLightmapUV : TEXCOORD7;
				#endif
				#if defined(USE_APV_PROBE_OCCLUSION)
					float4 probeOcclusion : TEXCOORD8;
				#endif
				float4 ase_texcoord9 : TEXCOORD9;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _ShallowColor;
			float4 _DeepColor;
			float _WaterNormalSpeed;
			float _FresnelOpacityStrength;
			float _FresnelPower;
			float _FresnelScale;
			float _FoamOpacity;
			float _FoamScale;
			float _FoamContrast;
			float _FoamAmount;
			float _Float6;
			float _Float3;
			float _RefractionIntensity;
			float _NormalDetailIntensity;
			float _NormalDetailScale;
			float _NormalIntensity;
			float _NormalMapScale;
			float _WaterSpecularity;
			float _WaterSmoothness;
			#ifdef ASE_TRANSMISSION
				float _TransmissionShadow;
			#endif
			#ifdef ASE_TRANSLUCENCY
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			#ifdef SCENEPICKINGPASS
				float4 _SelectionID;
			#endif

			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif

			sampler2D _NormalMap;
			sampler2D _FoamTexture;


			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityGBuffer.hlsl"

			
			PackedVaryings VertexFunction( Attributes input  )
			{
				PackedVaryings output = (PackedVaryings)0;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

				float3 objectToViewPos = TransformWorldToView(TransformObjectToWorld(input.positionOS.xyz));
				float eyeDepth = -objectToViewPos.z;
				output.ase_texcoord9.x = eyeDepth;
				
				
				//setting value to unused interpolator channels and avoid initialization warnings
				output.ase_texcoord9.yzw = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = input.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					input.positionOS.xyz = vertexValue;
				#else
					input.positionOS.xyz += vertexValue;
				#endif

				input.normalOS = input.normalOS;
				input.tangentOS = input.tangentOS;

				VertexPositionInputs vertexInput = GetVertexPositionInputs( input.positionOS.xyz );
				VertexNormalInputs normalInput = GetVertexNormalInputs( input.normalOS, input.tangentOS );

				output.tSpace0 = float4( normalInput.normalWS, vertexInput.positionWS.x);
				output.tSpace1 = float4( normalInput.tangentWS, vertexInput.positionWS.y);
				output.tSpace2 = float4( normalInput.bitangentWS, vertexInput.positionWS.z);

				#if defined(LIGHTMAP_ON)
					OUTPUT_LIGHTMAP_UV(input.texcoord1, unity_LightmapST, output.lightmapUVOrVertexSH.xy);
				#endif

				#if defined(DYNAMICLIGHTMAP_ON)
					output.dynamicLightmapUV.xy = input.texcoord2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
				#endif

				OUTPUT_SH4( vertexInput.positionWS, normalInput.normalWS.xyz, GetWorldSpaceNormalizeViewDir( vertexInput.positionWS ), output.lightmapUVOrVertexSH.xyz, output.probeOcclusion );

				#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
					output.lightmapUVOrVertexSH.zw = input.texcoord.xy;
					output.lightmapUVOrVertexSH.xy = input.texcoord.xy * unity_LightmapST.xy + unity_LightmapST.zw;
				#endif

				half3 vertexLight = VertexLighting( vertexInput.positionWS, normalInput.normalWS );

				output.fogFactorAndVertexLight = half4(0, vertexLight);

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					output.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				output.positionCS = vertexInput.positionCS;
				output.clipPosV = vertexInput.positionCS;
				return output;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 normalOS : NORMAL;
				float4 tangentOS : TANGENT;
				float4 texcoord : TEXCOORD0;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( Attributes input )
			{
				VertexControl output;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				output.vertex = input.positionOS;
				output.normalOS = input.normalOS;
				output.tangentOS = input.tangentOS;
				output.texcoord = input.texcoord;
				output.texcoord1 = input.texcoord1;
				output.texcoord2 = input.texcoord2;
				
				return output;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> input)
			{
				TessellationFactors output;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(input[0].vertex, input[1].vertex, input[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(input[0].vertex, input[1].vertex, input[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(input[0].vertex, input[1].vertex, input[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				output.edge[0] = tf.x; output.edge[1] = tf.y; output.edge[2] = tf.z; output.inside = tf.w;
				return output;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			PackedVaryings DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				Attributes output = (Attributes) 0;
				output.positionOS = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				output.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				output.tangentOS = patch[0].tangentOS * bary.x + patch[1].tangentOS * bary.y + patch[2].tangentOS * bary.z;
				output.texcoord = patch[0].texcoord * bary.x + patch[1].texcoord * bary.y + patch[2].texcoord * bary.z;
				output.texcoord1 = patch[0].texcoord1 * bary.x + patch[1].texcoord1 * bary.y + patch[2].texcoord1 * bary.z;
				output.texcoord2 = patch[0].texcoord2 * bary.x + patch[1].texcoord2 * bary.y + patch[2].texcoord2 * bary.z;
				
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = output.positionOS.xyz - patch[i].normalOS * (dot(output.positionOS.xyz, patch[i].normalOS) - dot(patch[i].vertex.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				output.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * output.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], output);
				return VertexFunction(output);
			}
			#else
			PackedVaryings vert ( Attributes input )
			{
				return VertexFunction( input );
			}
			#endif

			FragmentOutput frag ( PackedVaryings input
								#ifdef ASE_DEPTH_WRITE_ON
								,out float outputDepth : ASE_SV_DEPTH
								#endif
								 )
			{
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

				#if defined(LOD_FADE_CROSSFADE)
					LODFadeCrossFade( input.positionCS );
				#endif

				#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
					float2 sampleCoords = (input.lightmapUVOrVertexSH.zw / _TerrainHeightmapRecipSize.zw + 0.5f) * _TerrainHeightmapRecipSize.xy;
					float3 WorldNormal = TransformObjectToWorldNormal(normalize(SAMPLE_TEXTURE2D(_TerrainNormalmapTexture, sampler_TerrainNormalmapTexture, sampleCoords).rgb * 2 - 1));
					float3 WorldTangent = -cross(GetObjectToWorldMatrix()._13_23_33, WorldNormal);
					float3 WorldBiTangent = cross(WorldNormal, -WorldTangent);
				#else
					float3 WorldNormal = normalize( input.tSpace0.xyz );
					float3 WorldTangent = input.tSpace1.xyz;
					float3 WorldBiTangent = input.tSpace2.xyz;
				#endif

				float3 WorldPosition = float3(input.tSpace0.w,input.tSpace1.w,input.tSpace2.w);
				float3 WorldViewDirection = _WorldSpaceCameraPos.xyz  - WorldPosition;
				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				float4 ClipPos = input.clipPosV;
				float4 ScreenPos = ComputeScreenPos( input.clipPosV );

				float2 NormalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					ShadowCoords = input.shadowCoord;
				#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
					ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
				#else
					ShadowCoords = float4(0, 0, 0, 0);
				#endif

				WorldViewDirection = SafeNormalize( WorldViewDirection );

				float4 ase_screenPosNorm = ScreenPos / ScreenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float4 fetchOpaqueVal419 = float4( SHADERGRAPH_SAMPLE_SCENE_COLOR( ase_screenPosNorm.xy ), 1.0 );
				float temp_output_443_0 = ( 1.0 * 0.6 * _WaterNormalSpeed );
				float temp_output_11_0_g12 = ( temp_output_443_0 * _TimeParameters.x );
				float2 panner44 = ( 1.0 * _Time.y * float2( 0.02,0.1 ) + (( WorldPosition / ( 3.0 * _NormalMapScale ) )).xz);
				float2 temp_output_32_0_g12 = panner44;
				float2 panner5_g12 = ( temp_output_11_0_g12 * float2( 0.1,0.1 ) + temp_output_32_0_g12);
				float temp_output_33_0_g12 = _NormalIntensity;
				float3 unpack3_g12 = UnpackNormalScale( tex2D( _NormalMap, panner5_g12 ), temp_output_33_0_g12 );
				unpack3_g12.z = lerp( 1, unpack3_g12.z, saturate(temp_output_33_0_g12) );
				float2 panner16_g12 = ( temp_output_11_0_g12 * float2( -0.1,-0.1 ) + ( temp_output_32_0_g12 + float2( 0.418,0.355 ) ));
				float3 unpack13_g12 = UnpackNormalScale( tex2D( _NormalMap, panner16_g12 ), temp_output_33_0_g12 );
				unpack13_g12.z = lerp( 1, unpack13_g12.z, saturate(temp_output_33_0_g12) );
				float2 panner19_g12 = ( temp_output_11_0_g12 * float2( -0.1,0.1 ) + ( temp_output_32_0_g12 + float2( 0.865,0.148 ) ));
				float3 unpack20_g12 = UnpackNormalScale( tex2D( _NormalMap, panner19_g12 ), temp_output_33_0_g12 );
				unpack20_g12.z = lerp( 1, unpack20_g12.z, saturate(temp_output_33_0_g12) );
				float2 panner23_g12 = ( temp_output_11_0_g12 * float2( 0.1,-0.1 ) + ( temp_output_32_0_g12 + float2( 0.651,0.752 ) ));
				float3 unpack24_g12 = UnpackNormalScale( tex2D( _NormalMap, panner23_g12 ), temp_output_33_0_g12 );
				unpack24_g12.z = lerp( 1, unpack24_g12.z, saturate(temp_output_33_0_g12) );
				float temp_output_11_0_g13 = ( temp_output_443_0 * _TimeParameters.x );
				float2 panner50 = ( 1.0 * _Time.y * float2( 0.1,0.06 ) + (( WorldPosition / ( 9.0 * _NormalMapScale ) )).xz);
				float2 temp_output_32_0_g13 = panner50;
				float2 panner5_g13 = ( temp_output_11_0_g13 * float2( 0.1,0.1 ) + temp_output_32_0_g13);
				float temp_output_33_0_g13 = _NormalIntensity;
				float3 unpack3_g13 = UnpackNormalScale( tex2D( _NormalMap, panner5_g13 ), temp_output_33_0_g13 );
				unpack3_g13.z = lerp( 1, unpack3_g13.z, saturate(temp_output_33_0_g13) );
				float2 panner16_g13 = ( temp_output_11_0_g13 * float2( -0.1,-0.1 ) + ( temp_output_32_0_g13 + float2( 0.418,0.355 ) ));
				float3 unpack13_g13 = UnpackNormalScale( tex2D( _NormalMap, panner16_g13 ), temp_output_33_0_g13 );
				unpack13_g13.z = lerp( 1, unpack13_g13.z, saturate(temp_output_33_0_g13) );
				float2 panner19_g13 = ( temp_output_11_0_g13 * float2( -0.1,0.1 ) + ( temp_output_32_0_g13 + float2( 0.865,0.148 ) ));
				float3 unpack20_g13 = UnpackNormalScale( tex2D( _NormalMap, panner19_g13 ), temp_output_33_0_g13 );
				unpack20_g13.z = lerp( 1, unpack20_g13.z, saturate(temp_output_33_0_g13) );
				float2 panner23_g13 = ( temp_output_11_0_g13 * float2( 0.1,-0.1 ) + ( temp_output_32_0_g13 + float2( 0.651,0.752 ) ));
				float3 unpack24_g13 = UnpackNormalScale( tex2D( _NormalMap, panner23_g13 ), temp_output_33_0_g13 );
				unpack24_g13.z = lerp( 1, unpack24_g13.z, saturate(temp_output_33_0_g13) );
				float temp_output_11_0_g14 = ( 2.1 * _TimeParameters.x );
				float2 panner453 = ( 1.0 * _Time.y * float2( 0.02,0.1 ) + (( WorldPosition / ( ( 0.5 * _NormalDetailScale ) * _NormalMapScale ) )).xz);
				float2 temp_output_32_0_g14 = panner453;
				float2 panner5_g14 = ( temp_output_11_0_g14 * float2( 0.1,0.1 ) + temp_output_32_0_g14);
				float temp_output_33_0_g14 = _NormalDetailIntensity;
				float3 unpack3_g14 = UnpackNormalScale( tex2D( _NormalMap, panner5_g14 ), temp_output_33_0_g14 );
				unpack3_g14.z = lerp( 1, unpack3_g14.z, saturate(temp_output_33_0_g14) );
				float2 panner16_g14 = ( temp_output_11_0_g14 * float2( -0.1,-0.1 ) + ( temp_output_32_0_g14 + float2( 0.418,0.355 ) ));
				float3 unpack13_g14 = UnpackNormalScale( tex2D( _NormalMap, panner16_g14 ), temp_output_33_0_g14 );
				unpack13_g14.z = lerp( 1, unpack13_g14.z, saturate(temp_output_33_0_g14) );
				float2 panner19_g14 = ( temp_output_11_0_g14 * float2( -0.1,0.1 ) + ( temp_output_32_0_g14 + float2( 0.865,0.148 ) ));
				float3 unpack20_g14 = UnpackNormalScale( tex2D( _NormalMap, panner19_g14 ), temp_output_33_0_g14 );
				unpack20_g14.z = lerp( 1, unpack20_g14.z, saturate(temp_output_33_0_g14) );
				float2 panner23_g14 = ( temp_output_11_0_g14 * float2( 0.1,-0.1 ) + ( temp_output_32_0_g14 + float2( 0.651,0.752 ) ));
				float3 unpack24_g14 = UnpackNormalScale( tex2D( _NormalMap, panner23_g14 ), temp_output_33_0_g14 );
				unpack24_g14.z = lerp( 1, unpack24_g14.z, saturate(temp_output_33_0_g14) );
				float3 WaterNormal274 = BlendNormal( BlendNormal( ( ( ( unpack3_g12 + unpack13_g12 ) + ( unpack20_g12 + unpack24_g12 ) ) * 1.0 ) , ( ( ( unpack3_g13 + unpack13_g13 ) + ( unpack20_g13 + unpack24_g13 ) ) * 1.0 ) ) , ( ( ( unpack3_g14 + unpack13_g14 ) + ( unpack20_g14 + unpack24_g14 ) ) * 0.2 ) );
				float4 temp_output_270_0 = ( ase_screenPosNorm + float4( ( WaterNormal274 * _RefractionIntensity ) , 0.0 ) );
				float4 fetchOpaqueVal271 = float4( SHADERGRAPH_SAMPLE_SCENE_COLOR( temp_output_270_0.xy ), 1.0 );
				float eyeDepth413 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( temp_output_270_0.xy ),_ZBufferParams);
				float eyeDepth = input.ase_texcoord9.x;
				float ifLocalVar414 = 0;
				if( eyeDepth413 > eyeDepth )
				ifLocalVar414 = 1.0;
				else if( eyeDepth413 < eyeDepth )
				ifLocalVar414 = 0.0;
				float4 lerpResult418 = lerp( ( fetchOpaqueVal419 * 0.7 ) , ( fetchOpaqueVal271 * 0.7 ) , ifLocalVar414);
				float4 Refraction281 = lerpResult418;
				float screenDepth316 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy ),_ZBufferParams);
				float distanceDepth316 = ( screenDepth316 - LinearEyeDepth( ase_screenPosNorm.z,_ZBufferParams ) ) / ( _Float3 );
				float clampResult325 = clamp( ( distanceDepth316 * _Float6 ) , 0.0 , 1.0 );
				float4 lerpResult329 = lerp( _ShallowColor , _DeepColor , saturate( clampResult325 ));
				float4 Color362 = lerpResult329;
				float4 color422 = IsGammaSpace() ? float4(0.8679245,0.8679245,0.8679245,0) : float4(0.7254258,0.7254258,0.7254258,0);
				float screenDepth182 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy ),_ZBufferParams);
				float distanceDepth182 = saturate( abs( ( screenDepth182 - LinearEyeDepth( ase_screenPosNorm.z,_ZBufferParams ) ) / ( _FoamAmount ) ) );
				float saferPower188 = abs( ( 1.0 - distanceDepth182 ) );
				float2 panner197 = ( 1.0 * _Time.y * float2( 0.1,0 ) + (( WorldPosition / _FoamScale )).xz);
				float2 panner194 = ( 1.0 * _Time.y * float2( 0.2,0 ) + (( WorldPosition / _FoamScale )).xz);
				float saferPower252 = abs( ( tex2D( _FoamTexture, panner194 ).g * 0.88 ) );
				float2 panner466 = ( 1.0 * _Time.y * float2( 0.15,0.08 ) + (( WorldPosition / 1.0 )).xz);
				float2 panner470 = ( 1.0 * _Time.y * float2( 0.012,0.04 ) + (( WorldPosition / 5.0 )).xz);
				float4 tex2DNode475 = tex2D( _FoamTexture, panner470 );
				float saferPower476 = abs( tex2DNode475.g );
				float FoamFinal420 = saturate( ( ( ( ( ( saturate( pow( saferPower188 , _FoamContrast ) ) - tex2D( _FoamTexture, panner197 ).r ) - saturate( pow( saferPower252 , 0.65 ) ) ) - ( tex2D( _FoamTexture, panner466 ).r * 0.35 ) ) - pow( saferPower476 , 0.5 ) ) * 2.0 ) );
				float4 lerpResult424 = lerp( Color362 , ( color422 + float4( 0,0,0,0 ) ) , ( FoamFinal420 * _FoamOpacity ));
				float3 ase_viewVectorWS = ( _WorldSpaceCameraPos.xyz - WorldPosition );
				float3 ase_viewDirWS = normalize( ase_viewVectorWS );
				float3 tanToWorld0 = float3( WorldTangent.x, WorldBiTangent.x, WorldNormal.x );
				float3 tanToWorld1 = float3( WorldTangent.y, WorldBiTangent.y, WorldNormal.y );
				float3 tanToWorld2 = float3( WorldTangent.z, WorldBiTangent.z, WorldNormal.z );
				float3 tanNormal384 = WaterNormal274;
				float fresnelNdotV384 = dot( float3(dot(tanToWorld0,tanNormal384), dot(tanToWorld1,tanNormal384), dot(tanToWorld2,tanNormal384)), ase_viewDirWS );
				float fresnelNode384 = ( 0.0 + _FresnelScale * pow( max( 1.0 - fresnelNdotV384 , 0.0001 ), _FresnelPower ) );
				float lerpResult441 = lerp( 1.0 , fresnelNode384 , _FresnelOpacityStrength);
				float ColorOpacity365 = lerpResult329.a;
				float FresnelOpacity402 = ( saturate( lerpResult441 ) * ColorOpacity365 );
				float screenDepth256 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy ),_ZBufferParams);
				float distanceDepth256 = saturate( abs( ( screenDepth256 - LinearEyeDepth( ase_screenPosNorm.z,_ZBufferParams ) ) / ( 0.5 ) ) );
				float saferPower258 = abs( distanceDepth256 );
				float WaterEdge428 = saturate( pow( saferPower258 , 1.5 ) );
				float4 lerpResult493 = lerp( Refraction281 , lerpResult424 , ( FresnelOpacity402 * WaterEdge428 ));
				
				float3 temp_cast_5 = (_WaterSpecularity).xxx;
				

				float3 BaseColor = lerpResult493.rgb;
				float3 Normal = WaterNormal274;
				float3 Emission = 0;
				float3 Specular = temp_cast_5;
				float Metallic = 0;
				float Smoothness = _WaterSmoothness;
				float Occlusion = 1;
				float Alpha = WaterEdge428;
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;
				float3 BakedGI = 0;
				float3 RefractionColor = 1;
				float RefractionIndex = 1;
				float3 Transmission = 1;
				float3 Translucency = 1;

				#ifdef ASE_DEPTH_WRITE_ON
					float DepthValue = input.positionCS.z;
				#endif

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				InputData inputData = (InputData)0;
				inputData.positionWS = WorldPosition;
				inputData.positionCS = input.positionCS;
				inputData.shadowCoord = ShadowCoords;

				#ifdef _NORMALMAP
					#if _NORMAL_DROPOFF_TS
						inputData.normalWS = TransformTangentToWorld(Normal, half3x3( WorldTangent, WorldBiTangent, WorldNormal ));
					#elif _NORMAL_DROPOFF_OS
						inputData.normalWS = TransformObjectToWorldNormal(Normal);
					#elif _NORMAL_DROPOFF_WS
						inputData.normalWS = Normal;
					#endif
				#else
					inputData.normalWS = WorldNormal;
				#endif

				inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
				inputData.viewDirectionWS = SafeNormalize( WorldViewDirection );

				inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;

				#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
					float3 SH = SampleSH(inputData.normalWS.xyz);
				#else
					float3 SH = input.lightmapUVOrVertexSH.xyz;
				#endif

				#if defined(DYNAMICLIGHTMAP_ON)
					inputData.bakedGI = SAMPLE_GI(input.lightmapUVOrVertexSH.xy, input.dynamicLightmapUV.xy, SH, inputData.normalWS);
					inputData.shadowMask = SAMPLE_SHADOWMASK(input.lightmapUVOrVertexSH.xy);
				#elif !defined(LIGHTMAP_ON) && (defined(PROBE_VOLUMES_L1) || defined(PROBE_VOLUMES_L2))
					inputData.bakedGI = SAMPLE_GI( SH, GetAbsolutePositionWS(inputData.positionWS),
						inputData.normalWS,
						inputData.viewDirectionWS,
						input.positionCS.xy,
						input.probeOcclusion,
						inputData.shadowMask );
				#else
					inputData.bakedGI = SAMPLE_GI(input.lightmapUVOrVertexSH.xy, SH, inputData.normalWS);
					inputData.shadowMask = SAMPLE_SHADOWMASK(input.lightmapUVOrVertexSH.xy);
				#endif

				#ifdef ASE_BAKEDGI
					inputData.bakedGI = BakedGI;
				#endif

				inputData.normalizedScreenSpaceUV = NormalizedScreenSpaceUV;

				#if defined(DEBUG_DISPLAY)
					#if defined(DYNAMICLIGHTMAP_ON)
						inputData.dynamicLightmapUV = input.dynamicLightmapUV.xy;
						#endif
					#if defined(LIGHTMAP_ON)
						inputData.staticLightmapUV = input.lightmapUVOrVertexSH.xy;
					#else
						inputData.vertexSH = SH;
					#endif
					#if defined(USE_APV_PROBE_OCCLUSION)
						inputData.probeOcclusion = input.probeOcclusion;
					#endif
				#endif

				#ifdef _DBUFFER
					ApplyDecal(input.positionCS,
						BaseColor,
						Specular,
						inputData.normalWS,
						Metallic,
						Occlusion,
						Smoothness);
				#endif

				BRDFData brdfData;
				InitializeBRDFData
				(BaseColor, Metallic, Specular, Smoothness, Alpha, brdfData);

				Light mainLight = GetMainLight(inputData.shadowCoord, inputData.positionWS, inputData.shadowMask);
				half4 color;
				MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI, inputData.shadowMask);
				color.rgb = GlobalIllumination(brdfData, inputData.bakedGI, Occlusion, inputData.positionWS, inputData.normalWS, inputData.viewDirectionWS);
				color.a = Alpha;

				#ifdef ASE_FINAL_COLOR_ALPHA_MULTIPLY
					color.rgb *= color.a;
				#endif

				#ifdef ASE_DEPTH_WRITE_ON
					outputDepth = DepthValue;
				#endif

				return BRDFDataToGbuffer(brdfData, inputData, Smoothness, Emission + color.rgb, Occlusion);
			}

			ENDHLSL
		}

		
		Pass
		{
			
			Name "SceneSelectionPass"
			Tags { "LightMode"="SceneSelectionPass" }

			Cull Off
			AlphaToMask Off

			HLSLPROGRAM

			#pragma multi_compile_local_fragment _ALPHATEST_ON
			#define _NORMAL_DROPOFF_TS 1
			#define ASE_FOG 1
			#define _SPECULAR_SETUP 1
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define _NORMALMAP 1
			#define ASE_VERSION 19701
			#define ASE_SRP_VERSION 170003
			#define REQUIRE_DEPTH_TEXTURE 1


			#pragma vertex vert
			#pragma fragment frag

			#if defined(_SPECULAR_SETUP) && defined(_ASE_LIGHTING_SIMPLE)
				#define _SPECULAR_COLOR 1
			#endif

			#define SCENESELECTIONPASS 1

			#define ATTRIBUTES_NEED_NORMAL
			#define ATTRIBUTES_NEED_TANGENT
			#define SHADERPASS SHADERPASS_DEPTHONLY

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
            #include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRendering.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/DebugMipmapStreamingMacros.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			

			struct Attributes
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct PackedVaryings
			{
				float4 positionCS : SV_POSITION;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _ShallowColor;
			float4 _DeepColor;
			float _WaterNormalSpeed;
			float _FresnelOpacityStrength;
			float _FresnelPower;
			float _FresnelScale;
			float _FoamOpacity;
			float _FoamScale;
			float _FoamContrast;
			float _FoamAmount;
			float _Float6;
			float _Float3;
			float _RefractionIntensity;
			float _NormalDetailIntensity;
			float _NormalDetailScale;
			float _NormalIntensity;
			float _NormalMapScale;
			float _WaterSpecularity;
			float _WaterSmoothness;
			#ifdef ASE_TRANSMISSION
				float _TransmissionShadow;
			#endif
			#ifdef ASE_TRANSLUCENCY
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			#ifdef SCENEPICKINGPASS
				float4 _SelectionID;
			#endif

			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif

			

			
			struct SurfaceDescription
			{
				float Alpha;
				float AlphaClipThreshold;
			};

			PackedVaryings VertexFunction(Attributes input  )
			{
				PackedVaryings output;
				ZERO_INITIALIZE(PackedVaryings, output);

				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

				float4 ase_clipPos = TransformObjectToHClip((input.positionOS).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				output.ase_texcoord = screenPos;
				

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = input.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					input.positionOS.xyz = vertexValue;
				#else
					input.positionOS.xyz += vertexValue;
				#endif

				input.normalOS = input.normalOS;

				float3 positionWS = TransformObjectToWorld( input.positionOS.xyz );

				output.positionCS = TransformWorldToHClip(positionWS);

				return output;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 normalOS : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( Attributes input )
			{
				VertexControl output;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				output.vertex = input.positionOS;
				output.normalOS = input.normalOS;
				
				return output;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> input)
			{
				TessellationFactors output;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(input[0].vertex, input[1].vertex, input[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(input[0].vertex, input[1].vertex, input[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(input[0].vertex, input[1].vertex, input[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				output.edge[0] = tf.x; output.edge[1] = tf.y; output.edge[2] = tf.z; output.inside = tf.w;
				return output;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			PackedVaryings DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				Attributes output = (Attributes) 0;
				output.positionOS = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				output.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = output.positionOS.xyz - patch[i].normalOS * (dot(output.positionOS.xyz, patch[i].normalOS) - dot(patch[i].vertex.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				output.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * output.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], output);
				return VertexFunction(output);
			}
			#else
			PackedVaryings vert ( Attributes input )
			{
				return VertexFunction( input );
			}
			#endif

			half4 frag(PackedVaryings input ) : SV_TARGET
			{
				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				float4 screenPos = input.ase_texcoord;
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float screenDepth256 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy ),_ZBufferParams);
				float distanceDepth256 = saturate( abs( ( screenDepth256 - LinearEyeDepth( ase_screenPosNorm.z,_ZBufferParams ) ) / ( 0.5 ) ) );
				float saferPower258 = abs( distanceDepth256 );
				float WaterEdge428 = saturate( pow( saferPower258 , 1.5 ) );
				

				surfaceDescription.Alpha = WaterEdge428;
				surfaceDescription.AlphaClipThreshold = 0.5;

				#if _ALPHATEST_ON
					float alphaClipThreshold = 0.01f;
					#if ALPHA_CLIP_THRESHOLD
						alphaClipThreshold = surfaceDescription.AlphaClipThreshold;
					#endif
					clip(surfaceDescription.Alpha - alphaClipThreshold);
				#endif

				half4 outColor = 0;

				#ifdef SCENESELECTIONPASS
					outColor = half4(_ObjectId, _PassValue, 1.0, 1.0);
				#elif defined(SCENEPICKINGPASS)
					outColor = _SelectionID;
				#endif

				return outColor;
			}

			ENDHLSL
		}

		
		Pass
		{
			
			Name "ScenePickingPass"
			Tags { "LightMode"="Picking" }

			AlphaToMask Off

			HLSLPROGRAM

			#pragma multi_compile_local_fragment _ALPHATEST_ON
			#define _NORMAL_DROPOFF_TS 1
			#define ASE_FOG 1
			#define _SPECULAR_SETUP 1
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define _NORMALMAP 1
			#define ASE_VERSION 19701
			#define ASE_SRP_VERSION 170003
			#define REQUIRE_DEPTH_TEXTURE 1


			#pragma vertex vert
			#pragma fragment frag

			#if defined(_SPECULAR_SETUP) && defined(_ASE_LIGHTING_SIMPLE)
				#define _SPECULAR_COLOR 1
			#endif

		    #define SCENEPICKINGPASS 1

			#define ATTRIBUTES_NEED_NORMAL
			#define ATTRIBUTES_NEED_TANGENT
			#define SHADERPASS SHADERPASS_DEPTHONLY

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
            #include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRendering.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/DebugMipmapStreamingMacros.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			

			struct Attributes
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct PackedVaryings
			{
				float4 positionCS : SV_POSITION;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _ShallowColor;
			float4 _DeepColor;
			float _WaterNormalSpeed;
			float _FresnelOpacityStrength;
			float _FresnelPower;
			float _FresnelScale;
			float _FoamOpacity;
			float _FoamScale;
			float _FoamContrast;
			float _FoamAmount;
			float _Float6;
			float _Float3;
			float _RefractionIntensity;
			float _NormalDetailIntensity;
			float _NormalDetailScale;
			float _NormalIntensity;
			float _NormalMapScale;
			float _WaterSpecularity;
			float _WaterSmoothness;
			#ifdef ASE_TRANSMISSION
				float _TransmissionShadow;
			#endif
			#ifdef ASE_TRANSLUCENCY
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			#ifdef SCENEPICKINGPASS
				float4 _SelectionID;
			#endif

			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif

			

			
			struct SurfaceDescription
			{
				float Alpha;
				float AlphaClipThreshold;
			};

			PackedVaryings VertexFunction(Attributes input  )
			{
				PackedVaryings output;
				ZERO_INITIALIZE(PackedVaryings, output);

				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

				float4 ase_clipPos = TransformObjectToHClip((input.positionOS).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				output.ase_texcoord = screenPos;
				

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = input.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					input.positionOS.xyz = vertexValue;
				#else
					input.positionOS.xyz += vertexValue;
				#endif

				input.normalOS = input.normalOS;

				float3 positionWS = TransformObjectToWorld( input.positionOS.xyz );
				output.positionCS = TransformWorldToHClip(positionWS);

				return output;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 normalOS : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( Attributes input )
			{
				VertexControl output;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				output.vertex = input.positionOS;
				output.normalOS = input.normalOS;
				
				return output;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> input)
			{
				TessellationFactors output;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(input[0].vertex, input[1].vertex, input[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(input[0].vertex, input[1].vertex, input[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(input[0].vertex, input[1].vertex, input[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				output.edge[0] = tf.x; output.edge[1] = tf.y; output.edge[2] = tf.z; output.inside = tf.w;
				return output;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			PackedVaryings DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				Attributes output = (Attributes) 0;
				output.positionOS = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				output.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = output.positionOS.xyz - patch[i].normalOS * (dot(output.positionOS.xyz, patch[i].normalOS) - dot(patch[i].vertex.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				output.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * output.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], output);
				return VertexFunction(output);
			}
			#else
			PackedVaryings vert ( Attributes input )
			{
				return VertexFunction( input );
			}
			#endif

			half4 frag(PackedVaryings input ) : SV_TARGET
			{
				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				float4 screenPos = input.ase_texcoord;
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float screenDepth256 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy ),_ZBufferParams);
				float distanceDepth256 = saturate( abs( ( screenDepth256 - LinearEyeDepth( ase_screenPosNorm.z,_ZBufferParams ) ) / ( 0.5 ) ) );
				float saferPower258 = abs( distanceDepth256 );
				float WaterEdge428 = saturate( pow( saferPower258 , 1.5 ) );
				

				surfaceDescription.Alpha = WaterEdge428;
				surfaceDescription.AlphaClipThreshold = 0.5;

				#if _ALPHATEST_ON
					float alphaClipThreshold = 0.01f;
					#if ALPHA_CLIP_THRESHOLD
						alphaClipThreshold = surfaceDescription.AlphaClipThreshold;
					#endif
						clip(surfaceDescription.Alpha - alphaClipThreshold);
				#endif

				half4 outColor = 0;

				#ifdef SCENESELECTIONPASS
					outColor = half4(_ObjectId, _PassValue, 1.0, 1.0);
				#elif defined(SCENEPICKINGPASS)
					outColor = _SelectionID;
				#endif

				return outColor;
			}

			ENDHLSL
		}

		
		Pass
		{
			
			Name "MotionVectors"
			Tags { "LightMode"="MotionVectors" }

			ColorMask RG

			HLSLPROGRAM

			#pragma multi_compile_local_fragment _ALPHATEST_ON
			#define _NORMAL_DROPOFF_TS 1
			#define ASE_FOG 1
			#define _SPECULAR_SETUP 1
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define _NORMALMAP 1
			#define ASE_VERSION 19701
			#define ASE_SRP_VERSION 170003
			#define REQUIRE_DEPTH_TEXTURE 1


			#pragma vertex vert
			#pragma fragment frag

			#if defined(_SPECULAR_SETUP) && defined(_ASE_LIGHTING_SIMPLE)
				#define _SPECULAR_COLOR 1
			#endif
	
            #define SHADERPASS SHADERPASS_MOTION_VECTORS

            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"
		    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
		    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
		    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
		    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
		    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
		    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
            #include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRendering.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/DebugMipmapStreamingMacros.hlsl"
		    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
		    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#if defined(LOD_FADE_CROSSFADE)
				#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
			#endif

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MotionVectorsCommon.hlsl"

			

			struct Attributes
			{
				float4 positionOS : POSITION;
				float3 positionOld : TEXCOORD4;
				#if _ADD_PRECOMPUTED_VELOCITY
					float3 alembicMotionVector : TEXCOORD5;
				#endif
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct PackedVaryings
			{
				float4 positionCS : SV_POSITION;
				float4 positionCSNoJitter : TEXCOORD0;
				float4 previousPositionCSNoJitter : TEXCOORD1;
				float4 ase_texcoord2 : TEXCOORD2;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _ShallowColor;
			float4 _DeepColor;
			float _WaterNormalSpeed;
			float _FresnelOpacityStrength;
			float _FresnelPower;
			float _FresnelScale;
			float _FoamOpacity;
			float _FoamScale;
			float _FoamContrast;
			float _FoamAmount;
			float _Float6;
			float _Float3;
			float _RefractionIntensity;
			float _NormalDetailIntensity;
			float _NormalDetailScale;
			float _NormalIntensity;
			float _NormalMapScale;
			float _WaterSpecularity;
			float _WaterSmoothness;
			#ifdef ASE_TRANSMISSION
				float _TransmissionShadow;
			#endif
			#ifdef ASE_TRANSLUCENCY
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			#ifdef SCENEPICKINGPASS
				float4 _SelectionID;
			#endif

			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif

			

			
			PackedVaryings VertexFunction( Attributes input  )
			{
				PackedVaryings output = (PackedVaryings)0;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

				float4 ase_clipPos = TransformObjectToHClip((input.positionOS).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				output.ase_texcoord2 = screenPos;
				

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = input.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					input.positionOS.xyz = vertexValue;
				#else
					input.positionOS.xyz += vertexValue;
				#endif

				VertexPositionInputs vertexInput = GetVertexPositionInputs( input.positionOS.xyz );

				#if defined(APLICATION_SPACE_WARP_MOTION)
					// We do not need jittered position in ASW
					output.positionCSNoJitter = mul(_NonJitteredViewProjMatrix, mul(UNITY_MATRIX_M, input.positionOS));;
					output.positionCS = output.positionCSNoJitter;
				#else
					// Jittered. Match the frame.
					output.positionCS = vertexInput.positionCS;
					output.positionCSNoJitter = mul( _NonJitteredViewProjMatrix, mul( UNITY_MATRIX_M, input.positionOS));
				#endif

				float4 prevPos = ( unity_MotionVectorsParams.x == 1 ) ? float4( input.positionOld, 1 ) : input.positionOS;

				#if _ADD_PRECOMPUTED_VELOCITY
					prevPos = prevPos - float4(input.alembicMotionVector, 0);
				#endif

				output.previousPositionCSNoJitter = mul( _PrevViewProjMatrix, mul( UNITY_PREV_MATRIX_M, prevPos ) );
				// removed in ObjectMotionVectors.hlsl found in unity 6000.0.23 and higher
				//ApplyMotionVectorZBias( output.positionCS );
				return output;
			}

			PackedVaryings vert ( Attributes input )
			{
				return VertexFunction( input );
			}

			half4 frag(	PackedVaryings input  ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( input );

				float4 screenPos = input.ase_texcoord2;
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float screenDepth256 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy ),_ZBufferParams);
				float distanceDepth256 = saturate( abs( ( screenDepth256 - LinearEyeDepth( ase_screenPosNorm.z,_ZBufferParams ) ) / ( 0.5 ) ) );
				float saferPower258 = abs( distanceDepth256 );
				float WaterEdge428 = saturate( pow( saferPower258 , 1.5 ) );
				

				float Alpha = WaterEdge428;
				float AlphaClipThreshold = 0.5;

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				#if defined(LOD_FADE_CROSSFADE)
					LODFadeCrossFade( input.positionCS );
				#endif

				#if defined(APLICATION_SPACE_WARP_MOTION)
					return float4( CalcAswNdcMotionVectorFromCsPositions( input.positionCSNoJitter, input.previousPositionCSNoJitter ), 1 );
				#else
					return float4( CalcNdcMotionVectorFromCsPositions( input.positionCSNoJitter, input.previousPositionCSNoJitter ), 0, 0 );
				#endif
			}		
			ENDHLSL
		}
		
	}
	
	
	FallBack "Hidden/Shader Graph/FallbackError"
	
	Fallback "Hidden/InternalErrorShader"
}
/*ASEBEGIN
Version=19701
Node;AmplifyShaderEditor.CommentaryNode;261;1908.342,305.3318;Inherit;False;1109.405;186.9951;Water Edge;4;256;259;258;428;Water Edge;1,1,1,1;0;0
Node;AmplifyShaderEditor.DepthFade;256;1958.342,357.3268;Inherit;False;True;True;True;2;1;FLOAT3;0,0,0;False;0;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;258;2271.242,356.8022;Inherit;False;True;2;0;FLOAT;0;False;1;FLOAT;1.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;259;2494.747,355.3318;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;168;-1883.531,539.155;Inherit;False;2826.004;1855.721;Comment;39;274;175;266;267;11;100;103;44;50;443;6;49;43;444;53;12;41;48;47;40;73;71;46;42;72;445;446;447;448;449;450;451;452;453;454;455;456;457;459;Normal;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;263;-2388.434,-2508.96;Inherit;False;2468.436;1407.48;Comment;30;469;250;462;466;252;193;465;197;253;196;464;202;199;463;194;195;215;198;214;200;213;467;470;471;472;473;474;475;476;478;Foam Texture;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;262;-978.1631,-592.0611;Inherit;False;1190.497;301.6274;Comment;6;182;210;188;190;187;189;Foam Mask;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;401;1943.301,-1201.08;Inherit;False;1143.056;347.9071;Comment;6;319;316;324;323;325;336;Depth ;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;292;1184,560;Inherit;False;1839.671;755.5186;Comment;17;417;416;415;414;413;271;419;418;281;270;269;293;294;275;497;498;499;Refraction;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;405;3381.633,-357.5098;Inherit;False;1524.082;470.5134;Comment;11;390;402;400;398;386;384;404;439;440;441;442;Fresnel;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;429;5112.138,-687.8749;Inherit;False;731.6436;560.7823;Comment;7;423;426;425;424;422;427;501;Foam Blend;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;428;2681.863,364.3602;Inherit;False;WaterEdge;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;448;-1535.934,1983.554;Inherit;False;Constant;_Float7;Float 7;7;0;Create;True;0;0;0;False;0;False;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;42;-1408.456,800.0391;Inherit;False;Constant;_Float2;Float 2;7;0;Create;True;0;0;0;False;0;False;3;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;459;-1656.688,2138.036;Inherit;False;Property;_NormalDetailScale;Normal Detail Scale;20;0;Create;True;0;0;0;False;0;False;1;1.17;0;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;46;-1373.425,1466.793;Inherit;False;Constant;_Float1;Float 1;7;0;Create;True;0;0;0;False;0;False;9;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;72;-1711.766,1083.572;Inherit;False;Property;_NormalMapScale;Normal Map Scale;1;0;Create;True;0;0;0;False;0;False;1;1.15;0;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;200;-2300.402,-2085.663;Inherit;False;Property;_FoamScale;Foam Scale;8;0;Create;True;0;0;0;False;0;False;3;1.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.WorldPosInputsNode;213;-2336.148,-1953.533;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;71;-1259.791,796.759;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldPosInputsNode;40;-1444.45,644.411;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleDivideOpNode;214;-2059.116,-1903.405;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WorldPosInputsNode;47;-1157.046,1260.723;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;458;-1327.688,2118.036;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;73;-1121.016,1440.472;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldPosInputsNode;198;-2338.434,-2262.793;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.ComponentMaskNode;215;-1897.975,-1908.115;Inherit;False;True;False;True;False;1;0;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;187;-930.1631,-500.9594;Inherit;False;Property;_FoamAmount;Foam Amount;5;0;Create;True;0;0;0;False;0;False;0;1.313;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;6;-1839.496,1270.224;Inherit;True;Property;_NormalMap;Normal Map;0;1;[Normal];Create;True;0;0;0;False;0;False;None;437fcbf1eee883f4b8b194c794fa1a2b;True;bump;LockedToTexture2D;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;449;-1181.269,1971.274;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldPosInputsNode;450;-1365.928,1818.926;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleDivideOpNode;48;-873.3176,1390.048;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;41;-1256.911,646.326;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TexturePropertyNode;195;-1544.13,-2457.606;Inherit;True;Property;_FoamTexture;Foam Texture;7;0;Create;True;0;0;0;False;0;False;None;3ebf940de200d0946bcd96c41b54100a;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.DepthFade;182;-644.3587,-542.0087;Inherit;False;True;True;True;2;1;FLOAT3;0,0,0;False;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;12;-776.9367,1146.421;Inherit;False;Constant;_WaterSpeed;Water Speed;4;0;Create;True;0;0;0;False;0;False;1;0.6;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;49;-679.366,1412.718;Inherit;False;True;False;True;False;1;0;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.WorldPosInputsNode;463;-2334.882,-1673.267;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;467;-2294.141,-1502.674;Inherit;False;Constant;_Float10;Float 10;23;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;445;-1572.516,1268.504;Inherit;False;NormalMap;-1;True;1;0;SAMPLER2D;;False;1;SAMPLER2D;0
Node;AmplifyShaderEditor.PannerNode;194;-1503.13,-2048.606;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0.2,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;53;-758.6761,1233.323;Inherit;False;Constant;_Float4;Float 4;4;0;Create;True;0;0;0;False;0;False;0.6;0.6;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;444;-748.1498,1315.652;Inherit;False;Property;_WaterNormalSpeed;Water Normal Speed;18;0;Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;451;-1178.389,1820.841;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ComponentMaskNode;43;-1090.258,641.6962;Inherit;False;True;False;True;False;1;0;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;199;-2061.403,-2212.664;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ComponentMaskNode;202;-1900.26,-2217.373;Inherit;False;True;False;True;False;1;0;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;474;-2290.804,-1184.712;Inherit;False;Constant;_Float11;Float 11;23;0;Create;True;0;0;0;False;0;False;5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;319;1993.301,-1083.193;Inherit;False;Property;_Float3;Float 3;10;0;Create;True;0;0;0;False;0;False;0;2;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;103;-603.303,1000.823;Inherit;False;Property;_NormalIntensity;Normal Intensity;2;0;Create;True;0;0;0;False;0;False;0;3;0;5;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;196;-1139.132,-2231.606;Inherit;True;Property;_TextureSample1;Texture Sample 1;24;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;6;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT3;5
Node;AmplifyShaderEditor.RangedFloatNode;189;-929.3262,-384.4337;Inherit;False;Property;_FoamContrast;Foam Contrast;6;0;Create;True;0;0;0;False;0;False;1.5;3.51;0;5;0;1;FLOAT;0
Node;AmplifyShaderEditor.WorldPosInputsNode;471;-2331.545,-1355.305;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;100;-468.6771,1125.966;Inherit;False;Constant;_Float0;Float 0;12;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;443;-509.6422,1209.95;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;452;-1011.736,1816.211;Inherit;False;True;False;True;False;1;0;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;464;-2057.851,-1623.14;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;446;-324.5093,1078.128;Inherit;False;445;NormalMap;1;0;OBJECT;;False;1;SAMPLER2D;0
Node;AmplifyShaderEditor.GetLocalVarNode;447;-338.5093,810.128;Inherit;False;445;NormalMap;1;0;OBJECT;;False;1;SAMPLER2D;0
Node;AmplifyShaderEditor.OneMinusNode;210;-363.6125,-542.061;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;50;-416.6439,1356.147;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0.1,0.06;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PannerNode;44;-870.4365,643.6251;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0.02,0.1;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;11;-471.3009,828.6318;Inherit;False;Constant;_Float;Float;6;0;Create;True;0;0;0;False;0;False;1;0.8;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;197;-1504.031,-2209.705;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0.1,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;456;-493.6121,1747.363;Inherit;False;Property;_NormalDetailIntensity;Normal Detail Intensity;19;0;Create;True;0;0;0;False;0;False;1;0.39;0;5;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;472;-2054.514,-1305.178;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.PowerNode;188;-144.8135,-485.7395;Inherit;False;True;2;0;FLOAT;0;False;1;FLOAT;1.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.DepthFade;316;2193.07,-1151.08;Inherit;False;True;False;False;2;1;FLOAT3;0,0,0;False;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;455;-427.6121,1606.363;Inherit;False;445;NormalMap;1;0;OBJECT;;False;1;SAMPLER2D;0
Node;AmplifyShaderEditor.RangedFloatNode;324;2173.071,-969.1729;Inherit;False;Property;_Float6;Float 6;11;0;Create;True;0;0;0;False;0;False;0;1.5;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;267;-122.347,791.584;Inherit;True;4WayChaos;-1;;12;c91857f78a432b948baf6cdc0c5f4513;0;5;32;FLOAT2;0,0;False;31;SAMPLER2D;0,0,0,0;False;29;FLOAT;0.2;False;33;FLOAT;1;False;10;FLOAT;1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;253;-707.7326,-2173.406;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0.88;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;266;-123.6438,1059.149;Inherit;True;4WayChaos;-1;;13;c91857f78a432b948baf6cdc0c5f4513;0;5;32;FLOAT2;0,0;False;31;SAMPLER2D;0,0,0,0;False;29;FLOAT;0.2;False;33;FLOAT;1;False;10;FLOAT;1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ComponentMaskNode;465;-1896.71,-1627.849;Inherit;False;True;False;True;False;1;0;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PannerNode;453;-791.9145,1818.14;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0.02,0.1;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PowerNode;252;-433.963,-2173.65;Inherit;True;True;2;0;FLOAT;0;False;1;FLOAT;0.65;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;190;47.33499,-510.2267;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;193;-1138.645,-2458.96;Inherit;True;Property;_texture1;texture 1;24;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;6;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT3;5
Node;AmplifyShaderEditor.ComponentMaskNode;473;-1893.373,-1309.887;Inherit;False;True;False;True;False;1;0;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;323;2503.271,-1047.174;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;454;-127.4274,1630.374;Inherit;True;4WayChaos;-1;;14;c91857f78a432b948baf6cdc0c5f4513;0;5;32;FLOAT2;0,0;False;31;SAMPLER2D;0,0,0,0;False;29;FLOAT;0.2;False;33;FLOAT;1;False;10;FLOAT;2.1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.PannerNode;466;-1494.275,-1782.54;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0.15,0.08;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.BlendNormalsNode;175;280.6129,1019.386;Inherit;True;0;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.BlendNormalsNode;457;539.4868,1358.966;Inherit;False;0;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SaturateNode;250;-156.9062,-2171.572;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;325;2713.124,-1046.945;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;462;-1138.314,-1944.404;Inherit;True;Property;_TextureSample4;Texture Sample 4;24;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;6;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT3;5
Node;AmplifyShaderEditor.PannerNode;470;-1490.938,-1464.578;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0.012,0.04;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;235;428.4011,-1014.186;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;328;3507.485,-1199.839;Inherit;False;Property;_ShallowColor;Shallow Color;13;0;Create;True;0;0;0;False;0;False;0.2282841,0.4686714,0.509434,0;0.09803905,0.2274508,0.1921567,0;True;True;0;6;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT3;5
Node;AmplifyShaderEditor.SimpleSubtractOpNode;254;591.1565,-1014.321;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;469;-666.1371,-1765.74;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.35;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;475;-1142.577,-1536.27;Inherit;True;Property;_TextureSample5;Texture Sample 5;24;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;6;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT3;5
Node;AmplifyShaderEditor.RegisterLocalVarNode;274;626.0599,1013.149;Inherit;False;WaterNormal;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SaturateNode;336;2921.358,-1048.108;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;327;3520.436,-1018.884;Inherit;False;Property;_DeepColor;Deep Color;12;0;Create;True;0;0;0;False;0;False;0.08940016,0.2804352,0.3867925,0;0.09718724,0.2264147,0.1941078,1;True;True;0;6;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT3;5
Node;AmplifyShaderEditor.PowerNode;476;-523.627,-1489.347;Inherit;False;True;2;0;FLOAT;0;False;1;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;468;763.562,-1014.738;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;440;3474.115,-113.7284;Inherit;False;Property;_FresnelPower;Fresnel Power;17;0;Create;True;0;0;0;False;0;False;0;0.6;0;25;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;329;3845.612,-1105.625;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;294;1218.561,949.1688;Inherit;False;Property;_RefractionIntensity;Refraction Intensity;9;0;Create;True;0;0;0;False;0;False;5;0.25;0;5;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;275;1232,800;Inherit;False;274;WaterNormal;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;439;3475.115,-201.7285;Inherit;False;Property;_FresnelScale;Fresnel Scale;16;0;Create;True;0;0;0;False;0;False;0;1.53;0;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;404;3557.482,-284.9214;Inherit;False;274;WaterNormal;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ScreenPosInputsNode;269;1248,608;Float;False;0;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleSubtractOpNode;477;930.2861,-1014.676;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FresnelNode;384;3803.175,-278.7395;Inherit;False;Standard;TangentNormal;ViewDir;True;True;5;0;FLOAT3;0,0,1;False;4;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;3;False;3;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;390;3819.34,-75.46136;Inherit;False;Property;_FresnelOpacityStrength;Fresnel Opacity Strength;14;0;Create;True;0;0;0;False;0;False;0.1;0.918;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;331;3887.921,-914.4048;Inherit;False;COLOR;1;0;COLOR;0,0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.RangedFloatNode;442;4058.196,-277.9173;Inherit;False;Constant;_Float9;Float 9;18;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;480;926.3591,-802.8953;Inherit;False;Constant;_Float12;Float 12;22;0;Create;True;0;0;0;False;0;False;2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;293;1440.493,822.2026;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;479;1103.359,-854.8953;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;365;4057.225,-847.6518;Inherit;False;ColorOpacity;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;441;4205.496,-230.5173;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;270;1536.541,689.0806;Inherit;False;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;416;1763.664,1094.767;Inherit;False;Constant;_Float5;Float 5;15;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;417;1763.664,1180.767;Inherit;False;Constant;_Float8;Float 8;15;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SurfaceDepthNode;415;1639.915,1013.014;Inherit;False;0;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;209;1266.704,-833.5115;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenColorNode;271;1953.886,784.229;Inherit;False;Global;_GrabScreen0;Grab Screen 0;17;0;Create;True;0;0;0;False;0;False;Instance;419;False;True;False;False;2;0;FLOAT4;0,0,0,0;False;1;FLOAT;0;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ScreenDepthNode;413;1699.96,923.85;Inherit;False;0;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;498;2219.876,711.8734;Inherit;False;Constant;_Float13;Float 13;22;0;Create;True;0;0;0;False;0;False;0.7;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;398;4331.003,-93.88538;Inherit;False;365;ColorOpacity;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;386;4374.484,-210.732;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenColorNode;419;1964.708,602.5023;Inherit;False;Global;_GrabScreen1;Grab Screen 1;17;0;Create;True;0;0;0;False;0;False;Object;-1;False;True;False;False;2;0;FLOAT4;0,0,0,0;False;1;FLOAT;0;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;400;4551.763,-158.2399;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ConditionalIfNode;414;1992.176,989.6844;Inherit;False;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;420;1437.008,-837.4538;Inherit;False;FoamFinal;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;499;2233.876,796.8734;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;497;2227.876,602.8734;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0.2830189;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;418;2514.727,606.8517;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;422;5142.768,-619.1477;Inherit;False;Constant;_Color0;Color 0;15;0;Create;True;0;0;0;False;0;False;0.8679245,0.8679245,0.8679245,0;0,0,0,0;True;True;0;6;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT3;5
Node;AmplifyShaderEditor.RegisterLocalVarNode;362;4057.676,-1110.875;Inherit;False;Color;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;402;4709.284,-162.2393;Inherit;False;FresnelOpacity;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;423;5240.23,-339.1806;Inherit;False;420;FoamFinal;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;426;5140.007,-234.5797;Inherit;False;Property;_FoamOpacity;Foam Opacity;15;0;Create;True;0;0;0;False;0;False;1;0.619;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;427;5447.766,-469.6035;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;281;2818.549,605.379;Inherit;False;Refraction;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;425;5447.269,-319.289;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;490;6245.811,-155.8583;Inherit;False;402;FresnelOpacity;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;438;6266.773,-60.27494;Inherit;False;428;WaterEdge;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;501;5446.674,-587.7356;Inherit;False;362;Color;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;494;6531.287,-430.0428;Inherit;False;281;Refraction;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;496;6567.173,-101.5215;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;424;5689.022,-440.2384;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;165;6605.292,-728.5204;Inherit;False;Property;_WaterSmoothness;Water Smoothness;3;0;Create;True;0;0;0;False;0;False;0.95;0.94;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;478;-768.1394,-1323.921;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.61;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;493;6769.287,-385.0428;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;166;6605.436,-810.0662;Inherit;False;Property;_WaterSpecularity;Water Specularity;4;0;Create;True;0;0;0;False;0;False;1;0.27;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;330;6691.669,-890.186;Inherit;False;274;WaterNormal;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;486;7026.458,-1151.06;Float;False;False;-1;2;UnityEditor.ShaderGraphLitGUI;0;1;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;Universal2D;0;5;Universal2D;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;255;False;;255;False;;255;False;;7;False;;1;False;;1;False;;1;False;;7;False;;1;False;;1;False;;1;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Lit;True;5;True;12;all;0;False;True;1;5;False;;10;False;;1;1;False;;10;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;False;False;True;2;False;;True;3;False;;True;True;0;False;;0;False;;True;1;LightMode=Universal2D;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;487;7026.458,-1151.06;Float;False;False;-1;2;UnityEditor.ShaderGraphLitGUI;0;1;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;DepthNormals;0;6;DepthNormals;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;255;False;;255;False;;255;False;;7;False;;1;False;;1;False;;1;False;;7;False;;1;False;;1;False;;1;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Lit;True;5;True;12;all;0;False;True;1;1;False;;0;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=DepthNormals;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;481;6789.128,-1015.077;Float;False;False;-1;2;UnityEditor.ShaderGraphLitGUI;0;12;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;ExtraPrePass;0;0;ExtraPrePass;5;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;255;False;;255;False;;255;False;;7;False;;1;False;;1;False;;1;False;;7;False;;1;False;;1;False;;1;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Lit;True;5;True;12;all;0;False;True;1;1;False;;0;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;255;False;;255;False;;255;False;;7;False;;1;False;;1;False;;1;False;;7;False;;1;False;;1;False;;1;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;0;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;485;7026.458,-1151.06;Float;False;False;-1;2;UnityEditor.ShaderGraphLitGUI;0;1;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;Meta;0;4;Meta;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;255;False;;255;False;;255;False;;7;False;;1;False;;1;False;;1;False;;7;False;;1;False;;1;False;;1;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Lit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;483;7026.458,-1151.06;Float;False;False;-1;2;UnityEditor.ShaderGraphLitGUI;0;1;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;255;False;;255;False;;255;False;;7;False;;1;False;;1;False;;1;False;;7;False;;1;False;;1;False;;1;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Lit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;True;False;False;False;False;0;False;;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=ShadowCaster;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;488;7026.458,-1151.06;Float;False;False;-1;2;UnityEditor.ShaderGraphLitGUI;0;1;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;GBuffer;0;7;GBuffer;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;255;False;;255;False;;255;False;;7;False;;1;False;;1;False;;1;False;;7;False;;1;False;;1;False;;1;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Lit;True;5;True;12;all;0;False;True;1;5;False;;10;False;;1;1;False;;10;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;255;False;;255;False;;255;False;;7;False;;1;False;;1;False;;1;False;;7;False;;1;False;;1;False;;1;False;;False;True;2;False;;True;3;False;;True;True;0;False;;0;False;;True;1;LightMode=UniversalGBuffer;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;482;7141.989,-903.9125;Float;False;True;-1;2;;0;12;TriForge/Fantasy Forest/SimpleWater;94348b07e5e8bab40bd6c8a1e3df54cd;True;Forward;0;1;Forward;21;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;2;False;;False;False;False;False;False;False;False;False;False;True;False;255;False;;255;False;;255;False;;7;False;;1;False;;1;False;;1;False;;7;False;;1;False;;1;False;;1;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;4;RenderPipeline=UniversalPipeline;RenderType=Transparent=RenderType;Queue=Transparent=Queue=0;UniversalMaterialType=Lit;True;5;True;12;all;0;False;True;1;5;False;;10;False;;1;1;False;;10;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;255;False;;255;False;;255;False;;7;False;;1;False;;1;False;;1;False;;7;False;;1;False;;1;False;;1;False;;False;True;2;False;;True;3;False;;True;True;0;False;;0;False;;True;1;LightMode=UniversalForward;False;False;0;Hidden/InternalErrorShader;0;0;Standard;45;Lighting Model;0;0;Workflow;0;638000469866331032;Surface;1;638000475594219351;  Refraction Model;0;0;  Blend;0;0;Two Sided;0;638000472330963098;Alpha Clipping;1;0;  Use Shadow Threshold;0;0;Fragment Normal Space,InvertActionOnDeselection;0;0;Forward Only;0;0;Transmission;0;0;  Transmission Shadow;0.5,False,;0;Translucency;0;0;  Translucency Strength;1,False,;0;  Normal Distortion;0.5,False,;0;  Scattering;2,False,;0;  Direct;0.9,False,;0;  Ambient;0.1,False,;0;  Shadow;0.5,False,;0;Cast Shadows;0;638000470060465416;Receive Shadows;1;0;Receive SSAO;1;0;Motion Vectors;1;0;  Add Precomputed Velocity;0;0;GPU Instancing;0;638000470002695760;LOD CrossFade;0;638000469989877552;Built-in Fog;1;0;_FinalColorxAlpha;0;0;Meta Pass;1;0;Override Baked GI;0;0;Extra Pre Pass;0;638000472208320335;Tessellation;0;0;  Phong;0;0;  Strength;0.5,False,;0;  Type;0;0;  Tess;16,False,;0;  Min;10,False,;0;  Max;25,False,;0;  Edge Length;16,False,;0;  Max Displacement;25,False,;0;Write Depth;0;0;  Early Z;0;0;Vertex Position,InvertActionOnDeselection;1;0;Debug Display;0;0;Clear Coat;0;0;0;11;False;True;False;True;True;True;True;True;True;True;True;False;;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;484;7026.458,-1151.06;Float;False;False;-1;2;UnityEditor.ShaderGraphLitGUI;0;1;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;DepthOnly;0;3;DepthOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;255;False;;255;False;;255;False;;7;False;;1;False;;1;False;;1;False;;7;False;;1;False;;1;False;;1;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Lit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;True;False;False;False;False;0;False;;False;False;False;False;False;False;False;False;False;True;1;False;;False;False;True;1;LightMode=DepthOnly;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;502;7141.989,-823.9125;Float;False;False;-1;2;UnityEditor.ShaderGraphLitGUI;0;1;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;SceneSelectionPass;0;8;SceneSelectionPass;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Lit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;2;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=SceneSelectionPass;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;503;7141.989,-823.9125;Float;False;False;-1;2;UnityEditor.ShaderGraphLitGUI;0;1;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;ScenePickingPass;0;9;ScenePickingPass;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Lit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Picking;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;504;7141.989,-803.9125;Float;False;False;-1;2;UnityEditor.ShaderGraphLitGUI;0;1;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;MotionVectors;0;10;MotionVectors;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Lit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;False;False;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=MotionVectors;False;False;0;;0;0;Standard;0;False;0
WireConnection;258;0;256;0
WireConnection;259;0;258;0
WireConnection;428;0;259;0
WireConnection;71;0;42;0
WireConnection;71;1;72;0
WireConnection;214;0;213;0
WireConnection;214;1;200;0
WireConnection;458;0;448;0
WireConnection;458;1;459;0
WireConnection;73;0;46;0
WireConnection;73;1;72;0
WireConnection;215;0;214;0
WireConnection;449;0;458;0
WireConnection;449;1;72;0
WireConnection;48;0;47;0
WireConnection;48;1;73;0
WireConnection;41;0;40;0
WireConnection;41;1;71;0
WireConnection;182;0;187;0
WireConnection;49;0;48;0
WireConnection;445;0;6;0
WireConnection;194;0;215;0
WireConnection;451;0;450;0
WireConnection;451;1;449;0
WireConnection;43;0;41;0
WireConnection;199;0;198;0
WireConnection;199;1;200;0
WireConnection;202;0;199;0
WireConnection;196;0;195;0
WireConnection;196;1;194;0
WireConnection;443;0;12;0
WireConnection;443;1;53;0
WireConnection;443;2;444;0
WireConnection;452;0;451;0
WireConnection;464;0;463;0
WireConnection;464;1;467;0
WireConnection;210;0;182;0
WireConnection;50;0;49;0
WireConnection;44;0;43;0
WireConnection;197;0;202;0
WireConnection;472;0;471;0
WireConnection;472;1;474;0
WireConnection;188;0;210;0
WireConnection;188;1;189;0
WireConnection;316;0;319;0
WireConnection;267;32;44;0
WireConnection;267;31;447;0
WireConnection;267;29;11;0
WireConnection;267;33;103;0
WireConnection;267;10;443;0
WireConnection;253;0;196;2
WireConnection;266;32;50;0
WireConnection;266;31;446;0
WireConnection;266;29;100;0
WireConnection;266;33;103;0
WireConnection;266;10;443;0
WireConnection;465;0;464;0
WireConnection;453;0;452;0
WireConnection;252;0;253;0
WireConnection;190;0;188;0
WireConnection;193;0;195;0
WireConnection;193;1;197;0
WireConnection;473;0;472;0
WireConnection;323;0;316;0
WireConnection;323;1;324;0
WireConnection;454;32;453;0
WireConnection;454;31;455;0
WireConnection;454;33;456;0
WireConnection;466;0;465;0
WireConnection;175;0;267;0
WireConnection;175;1;266;0
WireConnection;457;0;175;0
WireConnection;457;1;454;0
WireConnection;250;0;252;0
WireConnection;325;0;323;0
WireConnection;462;0;195;0
WireConnection;462;1;466;0
WireConnection;470;0;473;0
WireConnection;235;0;190;0
WireConnection;235;1;193;1
WireConnection;254;0;235;0
WireConnection;254;1;250;0
WireConnection;469;0;462;1
WireConnection;475;0;195;0
WireConnection;475;1;470;0
WireConnection;274;0;457;0
WireConnection;336;0;325;0
WireConnection;476;0;475;2
WireConnection;468;0;254;0
WireConnection;468;1;469;0
WireConnection;329;0;328;0
WireConnection;329;1;327;0
WireConnection;329;2;336;0
WireConnection;477;0;468;0
WireConnection;477;1;476;0
WireConnection;384;0;404;0
WireConnection;384;2;439;0
WireConnection;384;3;440;0
WireConnection;331;0;329;0
WireConnection;293;0;275;0
WireConnection;293;1;294;0
WireConnection;479;0;477;0
WireConnection;479;1;480;0
WireConnection;365;0;331;3
WireConnection;441;0;442;0
WireConnection;441;1;384;0
WireConnection;441;2;390;0
WireConnection;270;0;269;0
WireConnection;270;1;293;0
WireConnection;209;0;479;0
WireConnection;271;0;270;0
WireConnection;413;0;270;0
WireConnection;386;0;441;0
WireConnection;419;0;269;0
WireConnection;400;0;386;0
WireConnection;400;1;398;0
WireConnection;414;0;413;0
WireConnection;414;1;415;0
WireConnection;414;2;416;0
WireConnection;414;4;417;0
WireConnection;420;0;209;0
WireConnection;499;0;271;0
WireConnection;499;1;498;0
WireConnection;497;0;419;0
WireConnection;497;1;498;0
WireConnection;418;0;497;0
WireConnection;418;1;499;0
WireConnection;418;2;414;0
WireConnection;362;0;329;0
WireConnection;402;0;400;0
WireConnection;427;0;422;0
WireConnection;281;0;418;0
WireConnection;425;0;423;0
WireConnection;425;1;426;0
WireConnection;496;0;490;0
WireConnection;496;1;438;0
WireConnection;424;0;501;0
WireConnection;424;1;427;0
WireConnection;424;2;425;0
WireConnection;478;0;475;2
WireConnection;493;0;494;0
WireConnection;493;1;424;0
WireConnection;493;2;496;0
WireConnection;482;0;493;0
WireConnection;482;1;330;0
WireConnection;482;9;166;0
WireConnection;482;4;165;0
WireConnection;482;6;438;0
ASEEND*/
//CHKSM=3FDEDAB8759DC76929B314AFA92D91563AF27584