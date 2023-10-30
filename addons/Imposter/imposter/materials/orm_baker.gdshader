shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_disabled,diffuse_burley,specular_schlick_ggx;
uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color;
uniform sampler2D ao_texture : source_color;
uniform vec4 ao_texture_channel;
uniform sampler2D roughness_texture : source_color;
uniform vec4  roughness_texture_channel;
uniform sampler2D metallic_texture : source_color;
uniform vec4  metallic_texture_channel;
uniform bool use_alpha_texture = false;
uniform float roughness : hint_range(0,1) = 1.0;
uniform float metallic : hint_range(0,1) = 0.0;
uniform float alpha_scissor_threshold :  hint_range(0,1);

uniform bool use_ao_texture = false;
uniform bool use_roughness_texture = false;
uniform bool use_metallic_texture = false;

uniform vec3 uv1_scale;
uniform vec3 uv1_offset;


void vertex() {
	UV=UV*uv1_scale.xy+uv1_offset.xy;
}

void fragment() {
	vec2 base_uv = UV;
	vec4 albedo_tex = texture(texture_albedo,base_uv);
	float ao_tex = mix(1.0, dot(texture(ao_texture,base_uv), ao_texture_channel), float(use_ao_texture));
	float rougness_tex = mix(1.0,dot(texture(roughness_texture,base_uv), roughness_texture_channel), float(use_roughness_texture));
	float metallic_tex = mix(1.0,dot(texture(metallic_texture,base_uv), metallic_texture_channel), float(use_metallic_texture));
	
	ALBEDO = vec3(ao_tex, rougness_tex * roughness, metallic_tex * metallic);
	if(use_alpha_texture)
	{
		ALPHA = albedo_tex.a;
		ALPHA_SCISSOR_THRESHOLD = alpha_scissor_threshold;
	}
}
