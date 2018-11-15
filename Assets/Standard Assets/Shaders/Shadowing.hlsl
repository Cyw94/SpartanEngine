//= DEFINES ======
#define CASCADES 3
//================

//= TEXTURES ===============================
Texture2D texNormal : register(t0);
Texture2D texDepth : register(t1);
Texture2D texNoise : register(t2);
Texture2D lightDepthTex[3] : register(t3);
//==========================================

//= SAMPLERS ===================================
SamplerState samplerPoint : register(s0);
SamplerState samplerLinear_clamp : register(s1);
SamplerState samplerLinear_wrap : register(s2);
//==============================================

//= CONSTANT BUFFERS =====================
cbuffer DefaultBuffer : register(b0)
{
    matrix mWorldViewProjectionOrtho;
    matrix mViewProjectionInverse;
	matrix mLightView;
    matrix mLightViewProjection[CASCADES];
    float4 shadowSplits;
    float3 lightDir;
    float shadowMapResolution;
    float2 resolution;
    float nearPlane;
    float farPlane;
    float doShadowMapping;
    float3 padding;
};
//========================================

// = INCLUDES ===============
#include "Common.hlsl"
#include "ShadowMapping.hlsl"
#include "SSAO.hlsl"
//===========================

//= STRUCTS ========================
struct PixelInputType
{
    float4 position : SV_POSITION;
    float2 uv : TEXCOORD;
};
//==================================

PixelInputType mainVS(Vertex_PosUv input)
{
    PixelInputType output;
	
    input.position.w = 1.0f;
    output.position = mul(input.position, mWorldViewProjectionOrtho);
    output.uv = input.uv;
	
    return output;
}

float2 mainPS(PixelInputType input) : SV_TARGET
{
    float2 texCoord     = input.uv;
    float3 normal       = texNormal.Sample(samplerLinear_clamp, texCoord).rgb;
    float2 depthSample  = texDepth.Sample(samplerLinear_clamp, texCoord).rg;
    float depth_linear  = depthSample.r * farPlane;
    float depth_cs      = depthSample.g;
    float3 positionWS   = ReconstructPositionWorld(depth_cs, mViewProjectionInverse, texCoord);
	
	
	//== SSAO ===========================================================
    float ssao = SSAO(texCoord, samplerLinear_clamp, samplerLinear_wrap);
	//===================================================================
	
	//= SHADOW MAPPING ===========================================================================	
    float shadow = 1.0f;
    if (doShadowMapping != 0.0f)
    {
		// Determine cascade to use
		int cascadeIndex 	= 2;
        cascadeIndex 		-= step(depth_linear, shadowSplits.x);
        cascadeIndex 		-= step(depth_linear, shadowSplits.y);
		
        float cascadeCompensation   = (cascadeIndex + 1.0f) * 2.0f; // the further the cascade, the more ugly under sharp angles, damn
        float shadowTexel           = 1.0f / shadowMapResolution;
        float normalOffset          = 70.0f * cascadeCompensation;
        float NdotL                 = dot(normal, lightDir);
        float cosAngle              = saturate(1.0f - NdotL);
        float3 scaledNormalOffset   = normal * (normalOffset * cosAngle * shadowTexel);
		float4 worldPos 			= float4(positionWS + scaledNormalOffset, 1.0f);
		float compareDepth			= mul(worldPos, mLightView).z / farPlane;
		float4 lightPos 			= mul(worldPos, mLightViewProjection[cascadeIndex]);

        if (cascadeIndex == 0)
        {      
            shadow = ShadowMapping(lightDepthTex[0], samplerPoint, shadowMapResolution, lightPos, normal, lightDir, compareDepth);
        }
        else if (cascadeIndex == 1)
        {
            shadow = ShadowMapping(lightDepthTex[1], samplerPoint, shadowMapResolution, lightPos, normal, lightDir, compareDepth);
        }
        else if (cascadeIndex == 2)
        {
            shadow = ShadowMapping(lightDepthTex[2], samplerPoint, shadowMapResolution, lightPos, normal, lightDir, compareDepth);
        }
    }
	//============================================================================================

    return float2(shadow, ssao);
}