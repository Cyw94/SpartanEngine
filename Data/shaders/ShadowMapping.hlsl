/*
Copyright(c) 2016-2019 Panos Karabelas

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
copies of the Software, and to permit persons to whom the Software is furnished
to do so, subject to the following conditions :

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

//= DEFINES =============================
#define PCF_SAMPLES 4
#define PCF_DIM float(PCF_SAMPLES) / 2.0f
//=======================================

//= INCLUDES ============
#include "Dithering.hlsl"
#include "SSCS.hlsl"
//=======================

float DepthTest_Directional(float slice, float2 uv, float compare)
{
	return light_depth_directional.SampleCmpLevelZero(sampler_cmp_depth, float3(uv, slice), compare).r;
}

float DepthTest_Point(float3 direction, float compare)
{
	return light_depth_point.SampleCmp(sampler_cmp_depth, direction, compare).r;
}

float DepthTest_Spot(float2 uv, float compare)
{
	return light_depth_spot.SampleCmp(sampler_cmp_depth, uv, compare).r;
}

float random(float2 seed2) 
{
	float4 seed4 		= float4(seed2.x, seed2.y, seed2.y, 1.0f);
	float dot_product 	= dot(seed4, float4(12.9898f, 78.233f, 45.164f, 94.673f));
    return frac(sin(dot_product) * 43758.5453);
}

float Technique_Poisson(int cascade, float3 uv, float compare, float2 dither)
{
	float packing = 700.0f; // how close together are the samples
	float2 poissonDisk[8] = 
	{
		float2(0.493393f, 0.394269f),
		float2(0.798547f, 0.885922f),
		float2(0.247322f, 0.92645f),
		float2(0.0514542f, 0.140782f),
		float2(0.831843f, 0.00955229f),
		float2(0.428632f, 0.0171514f),
		float2(0.015656f, 0.749779f),
		float2(0.758385f, 0.49617f)
	};
    
	uint samples 	= 16;
	float amountLit = 0.0f;
	[unroll]
	for (uint i = 0; i < samples; i++)
	{
		uint index 	= uint(samples * random(uv.xy * i)) % samples; // A pseudo-random number between 0 and 15, different for each pixel and each index

		#if DIRECTIONAL
		amountLit 	+= DepthTest_Directional(cascade, uv.xy + (poissonDisk[index] / packing), compare);
		#elif POINT
		amountLit 	+= DepthTest_Point(uv, compare);
		#elif SPOT
		amountLit 	+= DepthTest_Spot(uv.xy + (poissonDisk[index] / packing), compare);
		#endif
	}	

	amountLit /= (float)samples;
	return amountLit;
}

float Technique_PCF_2d(int cascade, float2 uv, float texel, float compare, float2 dither)
{
	float amountLit 	= 0.0f;
	float count 		= 0.0f;
	float2 offset_scale = texel * dither;
	
	[unroll]
	for (float y = -PCF_DIM; y <= PCF_DIM; ++y)
	{
		[unroll]
		for (float x = -PCF_DIM; x <= PCF_DIM; ++x)
		{
			float2 offset 	= float2(x, y) * offset_scale;
			
			#if DIRECTIONAL
			amountLit 	+= DepthTest_Directional(cascade, uv + offset, compare);
			#elif SPOT
			amountLit 	+= DepthTest_Spot(uv + offset, compare);
			#endif
			
			count++;			
		}
	}
	return amountLit /= count;
}

float Shadow_Map(float2 uv, float3 normal, float depth, float3 world_pos, float bias, float normal_bias, Light light)
{
    float n_dot_l               = dot(normal, normalize(-light.direction));
    float cos_angle             = saturate(1.0f - n_dot_l);
    float3 scaled_normal_offset = normal * cos_angle * g_shadow_texel_size * normal_bias * 10;
	float4 position_world   	= float4(world_pos + scaled_normal_offset, 1.0f);
	float shadow 				= 1.0f;
	float2 dither 				= Dither(uv + g_taa_jitterOffset).xy * 400;

	#if DIRECTIONAL
	{
		for (int cascade = 0; cascade < cascade_count; cascade++)
		{
            // Compute clip space position and uv for primary cascade
			float3 pos  = mul(position_world, light_view_projection[cascade]).xyz;
			float3 uv   = pos * float3(0.5f, -0.5f, 0.5f) + 0.5f;
			
			// If the position exists within the cascade, sample it
			[branch]
			if (is_saturated(uv))
			{	
				// Sample primary cascade
				float compare_depth 	= pos.z + (bias * (cascade + 1));
				float shadow_primary 	= Technique_PCF_2d(cascade, uv.xy, g_shadow_texel_size, compare_depth, dither);
				float3 cascade_edge 	= (abs(pos) - 0.9f) * 2.5f;
				float cascade_lerp 		= max(cascade_edge.x, max(cascade_edge.y, cascade_edge.z));

				// If we are close to the edge of the primary cascade and a secondary cascade exists, lerp with it.
				[branch]
				if (cascade_lerp > 0.0f && cascade < cascade_count - 1)
				{
					int cacade_secondary = cascade + 1;

                    // Compute clip space position and uv for secondary cascade
					pos = mul(position_world, light_view_projection[cacade_secondary]).xyz;
                    uv  = pos * float3(0.5f, -0.5f, 0.5f) + 0.5f;

                    // Sample secondary cascade
                    compare_depth           = pos.z + (bias * (cacade_secondary + 1));
					float shadow_secondary  = Technique_PCF_2d(cacade_secondary, uv.xy, g_shadow_texel_size, compare_depth, dither);

					// Blend cascades	
					shadow = lerp(shadow_primary, shadow_secondary, cascade_lerp);
				}
				else
				{
					shadow = shadow_primary;
				}

				break;
			}
		}
	}
	#elif POINT
	{
		float3 light_to_pixel_direction	= position_world.xyz - light.position;
		float light_to_pixel_distance = length(light_to_pixel_direction);
		light_to_pixel_direction = normalize(light_to_pixel_direction);
		
		[branch]
		if (light_to_pixel_distance < light.range)
		{
			///float depth = light_depth_point.Sample(samplerLinear_clamp, light_to_pixel_direction).r;
			//shadow = depth < (light_to_pixel_distance / light.range) ? 1.0f : 0.0f;

			float compare = (light_to_pixel_distance / light.range) + bias;
			return light_depth_point.SampleCmpLevelZero(sampler_cmp_depth, light_to_pixel_direction, compare).r;
		}
	}
	#elif SPOT
	{
		shadow = 1.0f;
	}
	#endif

	// Screen space contact shadow
	if (screen_space_contact_shadows_enabled)
	{
		float sscs = ScreenSpaceContactShadows(uv, light.direction);
		shadow = min(shadow, sscs);	
	}
	
	// Self shadow
	float self_shadow_contrast = 20.0f;
	float self_shadow = 1.0f - pow(1.0f - saturate(n_dot_l), self_shadow_contrast);
	shadow = min(shadow, self_shadow);

	return shadow;
}
