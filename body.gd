# Attached to each gravitating body
extends Node2D

@export var mass = 1.0
var velocity = Vector2.ZERO

@export var trail_enabled: bool = true
@export var trail_max_points: int = 200
@export var trail_color: Color = Color(1,1,1,0.5) # White with some transparency
@export var trail_width: float = 1.5

var trail_node: Line2D

# Kinematic orbit parameters
var is_kinematic_orbit: bool = false
var orbit_center_node: Node2D = null
var kinematic_orbital_radius: float = 0.0
var kinematic_angular_speed: float = 0.0 # Radians per second
var kinematic_current_angle_rad: float = 0.0
var kinematic_orbit_clockwise: bool = false

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
	if is_kinematic_orbit and is_instance_valid(orbit_center_node) and kinematic_orbital_radius > 0.0 and delta > 0.0:
		var angle_change = kinematic_angular_speed * delta
		if kinematic_orbit_clockwise:
			kinematic_current_angle_rad -= angle_change
		else:
			kinematic_current_angle_rad += angle_change
		
		# Optional: Normalize angle if it grows too large, though not strictly necessary for Vector2.rotated()
		# kinematic_current_angle_rad = fmod(kinematic_current_angle_rad, TAU)

		var relative_position = Vector2(kinematic_orbital_radius, 0).rotated(kinematic_current_angle_rad)
		var new_global_position = orbit_center_node.global_position + relative_position

		# Update 'velocity' primarily for trail rendering and consistency if accessed elsewhere
		self.velocity = (new_global_position - global_position) / delta
		global_position = new_global_position
	else:
		# For the star (or non-kinematic bodies), use existing velocity.
		# Star's velocity is (0,0) and won't be changed by gravity, so it stays put.
		position += velocity * delta

	# Trail rendering logic (uses self.velocity and global_position)
	if trail_enabled and trail_max_points > 0 and is_instance_valid(trail_node):
		trail_node.add_point(global_position)
		while trail_node.get_point_count() > trail_max_points:
			trail_node.remove_point(0)
