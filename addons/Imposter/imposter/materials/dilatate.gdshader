shader_type canvas_item;
render_mode blend_premul_alpha;

uniform sampler2D u_alpha_tex;
uniform int u_distance = 16;
uniform bool u_alpha_overwrite = true;


vec4 dilate(sampler2D a_tex, sampler2D tex, vec2 coords, vec2 texel_size, int dist, float alpha_cutoff)
{

	vec2 offsets[8] = {
		vec2(-1,0),vec2(1,0), vec2(0,1), vec2(0,-1), 
		vec2(-1,1), vec2(1,1), vec2(1,-1), vec2(-1,-1)
	};

	vec4 sample = textureLod(tex, coords, 0);
	vec4 a_sample = textureLod(a_tex, coords, 0);
	if(a_sample.a > alpha_cutoff)
		return sample;

	for(int curr_dist = 0; curr_dist < dist; curr_dist++)
	{
		for(int o = 0; o < 8; o++)
		{
			vec2 off_coords = offsets[o] * texel_size * float(curr_dist + 1);
			vec4 off_sample = textureLod(tex, coords + off_coords, 0);
			vec4 off_a_sample = textureLod(a_tex, coords + off_coords, 0);

			if (off_a_sample.a > alpha_cutoff)
			{
				if(u_alpha_overwrite)
					return off_sample;
				else
					return vec4(off_sample.rgb, a_sample.a);
			}
			
		}
	}
	return sample;
}

void fragment() {
    COLOR = dilate(u_alpha_tex, TEXTURE, UV, TEXTURE_PIXEL_SIZE, u_distance, 0.95);
	//COLOR.a = 1.0;
}
