extends Camera2D

var target_zoom_vector: Vector2

func _ready():
	pass

func _process(delta: float):
	
	var mouse_offset:Vector2 = (Vector2i(get_viewport().get_mouse_position()) - get_viewport().size / 2)
	self.position = lerp(Vector2(), mouse_offset.normalized() * 500, mouse_offset.length() / 1000)
	pass
