@tool
extends Node2D

var processed_image: Image = null
var _alpha_image: Image = null

func _dilatate_image(alpha_mask: Image, image: Image):
	
	var tex: ImageTexture = ImageTexture.create_from_image(image)
	var alpha_tex: ImageTexture = ImageTexture.create_from_image(alpha_mask)

	var world2d = World2D.new()
	$DilateViewport.world_2d=world2d
	
	$DilateViewport.size = image.get_size()

	$DilateViewport/tex.texture = tex
	$DilateViewport/tex.material.set_shader_parameter("u_alpha_tex", alpha_tex)
	$DilateViewport.transparent_bg = true
	$DilateViewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	await RenderingServer.frame_post_draw


	var viewport_texture = $DilateViewport.get_texture()
	await RenderingServer.frame_post_draw
	self.processed_image = viewport_texture.get_image()


func dilatate_mask(alpha_mask: Image, image: Image):
	$DilateViewport/tex.material.set_shader_parameter("u_alpha_overwrite", true)
	return await self._dilatate_image(alpha_mask, image)


func dilatate(image: Image, use_as_alpha = false):
	if use_as_alpha:
		_alpha_image = image

	$DilateViewport/tex.material.set_shader_parameter("u_alpha_overwrite", false)
	return await self._dilatate_image(_alpha_image, image)

func clean():
	_alpha_image=null
	processed_image=null
	$DilateViewport/tex.texture=null
	$DilateViewport/tex.material.set_shader_parameter("u_alpha_tex", null)


func set_dilatate_distance(value:int):
	$DilateViewport/tex.material.set_shader_parameter('u_distance',value)
