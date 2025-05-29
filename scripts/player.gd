extends RigidBody2D


const FORWARD_ACCELERATION = 10000 #pixels/sec/sec
const SIDE_AND_BACK_ACCELERATION = 5000 #pixels/sec/sec
const MAX_SPEED = 200 #pixels/sec
const ROTATION_SPEED = 5 #lerp between current and mouse


func _physics_process(delta):
	movement(delta)
	
	
func movement(delta):
	var forward_input = -1 * Input.get_axis("up", "down")
	var strafe_input = Input.get_axis("left", "right")
	
	var thrust_force :Vector2
	
	var direction = get_global_mouse_position() - global_position
	var angle_to = transform.x.angle_to(direction)
	
	rotate(sign(angle_to) * min(delta * ROTATION_SPEED, abs(angle_to)))
	
	if forward_input > 0:
		thrust_force += transform.x * forward_input * FORWARD_ACCELERATION * delta
	elif forward_input < 0:
		thrust_force += transform.x * forward_input * SIDE_AND_BACK_ACCELERATION * delta
		
	thrust_force += transform.y * strafe_input * SIDE_AND_BACK_ACCELERATION * delta
	
	apply_force(thrust_force)
