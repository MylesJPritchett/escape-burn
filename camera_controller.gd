extends Camera2D

@export var default_zoom_level: float = 1.0
@export var zoom_lerp_speed: float = 2.0 # How fast the zoom changes

private var target_zoom_vector: Vector2

func _ready():
	target_zoom_vector = Vector2(default_zoom_level, default_zoom_level)
	self.zoom = target_zoom_vector

func _process(delta: float):
	if not self.zoom.is_equal_approx(target_zoom_vector):
		self.zoom = self.zoom.lerp(target_zoom_vector, zoom_lerp_speed * delta)

func set_target_zoom(new_zoom_level: float):
	if new_zoom_level <= 0:
		printerr("Camera zoom target must be positive.")
		return
	target_zoom_vector = Vector2(new_zoom_level, new_zoom_level)

func set_target_zoom_vector(new_zoom_vector: Vector2):
	if new_zoom_vector.x <= 0 or new_zoom_vector.y <= 0:
		printerr("Camera zoom target components must be positive.")
		return
	target_zoom_vector = new_zoom_vector
extends Camera2D

@export var default_zoom_level: float = 1.0
@export var zoom_lerp_speed: float = 2.0 # How fast the zoom changes

private var target_zoom_vector: Vector2

func _ready():
	target_zoom_vector = Vector2(default_zoom_level, default_zoom_level)
	self.zoom = target_zoom_vector

func _process(delta: float):
	if not self.zoom.is_equal_approx(target_zoom_vector):
		self.zoom = self.zoom.lerp(target_zoom_vector, zoom_lerp_speed * delta)

func set_target_zoom(new_zoom_level: float):
	if new_zoom_level <= 0:
		printerr("Camera zoom target must be positive.")
		return
	target_zoom_vector = Vector2(new_zoom_level, new_zoom_level)

func set_target_zoom_vector(new_zoom_vector: Vector2):
	if new_zoom_vector.x <= 0 or new_zoom_vector.y <= 0:
		printerr("Camera zoom target components must be positive.")
		return
	target_zoom_vector = new_zoom_vector
