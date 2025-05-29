extends RigidBody2D

@export var space_manager_node_path: NodePath
var space_manager: Node

# These constants define acceleration. Force applied will be mass * acceleration.
const FORWARD_ACCELERATION = 100 #pixels/sec^2 
const SIDE_AND_BACK_ACCELERATION = 25 #pixels/sec^2
const MAX_SPEED = 200 #pixels/sec
const ROTATION_SPEED = 5 #rad/sec for rotation lerp speed

func _ready():
	if space_manager_node_path:
		space_manager = get_node_or_null(space_manager_node_path)
	
	if not is_instance_valid(space_manager):
		printerr("Player: SpaceManager node not found (path: '%s'). Gravity and correct body interactions will not function." % space_manager_node_path)

func _physics_process(delta):
	_handle_rotation_and_thrust(delta)
	_apply_gravity_forces()
	_clamp_speed()

func _handle_rotation_and_thrust(delta):
	# Rotation: Make the player face the mouse
	var direction_to_mouse = get_global_mouse_position() - global_position
	var angle_to_mouse = transform.x.angle_to(direction_to_mouse) # transform.x is the forward vector
	# Rotate by the smaller of (delta * ROTATION_SPEED) or the actual angle_to_mouse
	# This creates a smooth, frame-rate independent turn towards the mouse.
	rotate(sign(angle_to_mouse) * min(delta * ROTATION_SPEED, abs(angle_to_mouse)))

	# Input for thrust
	var forward_input = -Input.get_axis("up", "down") # Negative because "up" is usually positive Y
	var strafe_input = Input.get_axis("left", "right")
	
	var thrust_acceleration_vector := Vector2.ZERO # Stores the calculated acceleration based on input
	
	# Calculate acceleration component from forward/backward input
	if forward_input > 0: # Moving forward (relative to player orientation)
		thrust_acceleration_vector += transform.x * forward_input * FORWARD_ACCELERATION
	elif forward_input < 0: # Moving backward
		thrust_acceleration_vector += transform.x * forward_input * SIDE_AND_BACK_ACCELERATION
		
	# Calculate acceleration component from strafing input
	thrust_acceleration_vector += transform.y * strafe_input * SIDE_AND_BACK_ACCELERATION # transform.y is the right vector
	
	# Apply thrust force: F = m * a. 'mass' is a built-in property of RigidBody2D.
	# Only apply force if there's some acceleration input.
	if thrust_acceleration_vector.length_squared() > 0.001: # Check against a small epsilon
		apply_central_force(thrust_acceleration_vector * mass)

func _apply_gravity_forces():
	if not is_instance_valid(space_manager):
		return

	# Assuming G and bodies are public properties of SpaceManager script
	var G = space_manager.get("G") # Use .get() for safety if unsure about property existence
	var bodies_to_attract = space_manager.get("bodies")

	if G == null:
		printerr("Player: SpaceManager does not have property 'G'.")
		return
	if not bodies_to_attract is Array:
		# This might also trigger if bodies is null but G was found.
		# printerr("Player: SpaceManager.bodies is not an Array or is null.") 
		return

	for body_node in bodies_to_attract:
		if not is_instance_valid(body_node) or body_node == self: # Don't attract to self or invalid nodes
			continue
		
		# Assuming celestial bodies have a 'mass' property.
		# If they are RigidBody2D, 'mass' is built-in. Otherwise, it must be a custom script property.
		var body_mass = body_node.get("mass")
		if body_mass == null:
			# This can be noisy if many non-massive helper nodes are in 'bodies' array.
			# printerr("Player: Attracting body '%s' does not have a 'mass' property." % body_node.name)
			continue 

		var vector_to_body = body_node.global_position - global_position
		var distance_sq = vector_to_body.length_squared()
		
		# Prevent extreme forces or division by zero if objects are too close or overlap.
		# A minimum distance (e.g., sum of radii, or a small constant) should be used.
		# Using 1.0 (1 pixel squared distance) as a placeholder minimum.
		if distance_sq < 1.0: 
			continue
			
		var force_magnitude = (G * mass * body_mass) / distance_sq # mass is player's mass
		var force_vector = vector_to_body.normalized() * force_magnitude
		
		apply_central_force(force_vector)

func _clamp_speed():
	if linear_velocity.length_squared() > MAX_SPEED * MAX_SPEED:
		linear_velocity = linear_velocity.normalized() * MAX_SPEED
