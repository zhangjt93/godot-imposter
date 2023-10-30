shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_disabled,diffuse_burley,specular_schlick_ggx;
uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color;
uniform sampler2D normal_texture : source_color;

uniform bool use_normalmap = false;
uniform bool use_alpha_texture = false;
uniform float roughness : hint_range(0,1);
uniform float alpha_scissor_threshold :  hint_range(0,1);
uniform float normal_scale :  hint_range(-5,5);

uniform vec3 uv1_scale;
uniform vec3 uv1_offset;


void vertex() {
	UV=UV*uv1_scale.xy+uv1_offset.xy;
}

void fragment() {
	vec2 base_uv = UV;
	vec4 albedo_tex = texture(texture_albedo,base_uv);
	vec4 normal_tex = texture(normal_texture,base_uv);
	// 0.5 + -1.0 == -1.0 + 0.5
	//ALBEDO = vec3(1.0 - NORMAL.y, 1.0 - NORMAL.x, - NORMAL.z)* 0.5;
	if(use_normalmap)
	{
		vec3 normalmap;
		normalmap.xy = normal_tex.xy * 2.0 - 1.0;
		normalmap.z = sqrt(max(0.0, 1.0 - dot(normalmap.xy, normalmap.xy)));
		NORMAL = normalize(mix(NORMAL, TANGENT * normalmap.x + BINORMAL * normalmap.y + NORMAL * normalmap.z, normal_scale));
	}

	
	
	ALBEDO = vec3(-NORMAL.x, NORMAL.y, -NORMAL.z) * 0.5 + 0.5;
	if(use_alpha_texture)
	{
		ALPHA = albedo_tex.a;
		ALPHA_SCISSOR_THRESHOLD = alpha_scissor_threshold;
	}

}
