cbuffer ShadowConstants : register(b2)
{
	float4x4 shadowmatrix;
}

cbuffer TerrainData : register(b1)
{
	float scale;
	float width;
	float depth;
	float base;
}

Texture2D<float> heightmap : register(t0);
SamplerState hmsampler : register(s0);
SamplerState detailsampler : register(s1);

struct DS_OUTPUT
{
	float4 pos : SV_POSITION;
};

// Output control point
struct HS_CONTROL_POINT_OUTPUT
{
	float3 worldpos : POSITION;
	float2 tex : TEXCOORD;
};

// Output patch constant data.
struct HS_CONSTANT_DATA_OUTPUT
{
	float EdgeTessFactor[4]			: SV_TessFactor; // e.g. would be [4] for a quad domain
	float InsideTessFactor[2]		: SV_InsideTessFactor; // e.g. would be Inside[2] for a quad domain
	uint skirt						: SKIRT;
};

#define NUM_CONTROL_POINTS 4

[domain("quad")]
DS_OUTPUT main(
	HS_CONSTANT_DATA_OUTPUT input,
	float2 domain : SV_DomainLocation,
	const OutputPatch<HS_CONTROL_POINT_OUTPUT, NUM_CONTROL_POINTS> patch)
{
	DS_OUTPUT output;
	float3 worldpos = lerp(lerp(patch[0].worldpos, patch[1].worldpos, domain.x), lerp(patch[2].worldpos, patch[3].worldpos, domain.x), domain.y);
	float2 tex = lerp(lerp(patch[0].tex, patch[1].tex, domain.x), lerp(patch[2].tex, patch[3].tex, domain.x), domain.y);

	if (input.skirt < 5) {
		if (input.skirt > 0 && domain.y == 1) {
			worldpos.z = heightmap.SampleLevel(hmsampler, tex, 0.0f) * scale;
		}
	} else {
		worldpos.z = heightmap.SampleLevel(hmsampler, tex, 0.0f) * scale;
	}

	output.pos = float4(worldpos, 1.0f);
	output.pos = mul(output.pos, shadowmatrix);
	return output;
}