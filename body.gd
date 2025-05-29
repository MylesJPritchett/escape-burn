# Attached to each gravitating body
extends Node2D

@export var mass = 1.0
var velocity = Vector2.ZERO

@export var trail_enabled: bool = true
@export var trail_max_points: int = 200
@export var trail_color: Color = Color(1,1,1,0.5) # White with some transparency
@export var trail_width: float = 1.5

var trail_node: Line2D

func _ready():
	if trail_enabled and trail_max_points > 0:
		trail_node = Line2D.new()
		trail_node.name = "VisualTrail" # For easier identification in remote inspector
		trail_node.width = trail_width
		trail_node.default_color = trail_color
		
		# Make the Line2D draw in global coordinates, not relative to this body's movement
		trail_node.top_level = true 
		
		# Add as a child so it gets cleaned up when the body is removed
		add_child(trail_node)

func _physics_process(delta):
	position += velocity * delta

	if trail_enabled and trail_max_points > 0 and is_instance_valid(trail_node):
		trail_node.add_point(global_position)
		while trail_node.get_point_count() > trail_max_points:
			trail_node.remove_point(0)
