shader_type spatial;
render_mode unshaded, depth_test_disabled;
uniform float depth_scaler = 1.0f;
uniform vec4 col: source_color;

uniform sampler2D DEPTH_TEXTURE:hint_depth_texture,filter_linear_mipmap;
varying mat4 CAMERA;
void vertex() {

	//POSITION = vec4(VERTEX, 1.0);
	//godot4.3 update : Reverse Z
	POSITION = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	CAMERA = INV_VIEW_MATRIX;
}

void fragment() {

  float depth = texture(DEPTH_TEXTURE, SCREEN_UV).x;

//Vulkan.z size range 0-1 ，penGL.z size range -1，1
  vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
//  vec3 ndc = vec3(SCREEN_UV, depth) * 2.0 - 1.0;

  vec4 world = CAMERA * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
  vec3 world_position = world.xyz / world.w;

float aabb_full = depth_scaler;

world_position *= 2.0; // going back to aabb but around 0
world_position.z = aabb_full/2.0 - world_position.z;

ALBEDO = vec3(clamp(world_position.z/aabb_full,0,1));
}
