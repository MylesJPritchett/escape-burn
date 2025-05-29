# Global space manager node
extends Node2D

const BodyScript = preload("res://body.gd")
const PlanetScene = preload("res://planet.tscn")
const MoonScene = preload("res://moon.tscn")
const StarTexture = preload("res://the-sun.webp")
const OrbitalSystemGenerator = preload("res://orbital_system_generator.gd")

var bodies = []
@export var G = 10000.0 # Reduced G to slow down the simulation
var star_node: Node2D = null # To store a reference to the star

func _clear_existing_system():
	for body in bodies:
		if is_instance_valid(body):
			body.queue_free()
	bodies.clear()
	star_node = null # Reset the reference to the star node

func _generate_and_spawn_system():
	# Note: randomize() should be called by the caller (_ready or _on_restart_button_pressed)
	var star_config = {
		"mass": randf_range(800.0, 1200.0), # Randomized star mass
		"position": Vector2.ZERO, # Center the star at SpaceManager's origin
		"velocity": Vector2.ZERO # Star initially stationary
	}

	var planets_configs = [
		{
			"mass": randf_range(25.0, 35.0), 
			"orbital_radius": randf_range(350.0, 450.0), 
			"initial_angle_degrees": randf_range(0.0, 360.0),
			"clockwise": randf() > 0.5,
			"moons": [
				{ 
					"mass": randf_range(0.5, 1.5), 
					"orbital_radius": randf_range(20.0, 35.0), # Ensure moon radius is much smaller than planet's
					"initial_angle_degrees": randf_range(0.0, 360.0),
					"clockwise": randf() > 0.5
				}
			]
		},
		{
			"mass": randf_range(15.0, 25.0), 
			"orbital_radius": randf_range(550.0, 650.0), # Further out
			"initial_angle_degrees": randf_range(0.0, 360.0),
			"clockwise": randf() > 0.5
			# No moons for this planet for variety
		},
		{
			"mass": randf_range(45.0, 55.0), 
			"orbital_radius": randf_range(700.0, 800.0), # Furthest out
			"initial_angle_degrees": randf_range(0.0, 360.0),
			"clockwise": randf() > 0.5,
			"moons": [
				{ 
					"mass": randf_range(1.5, 2.5), 
					"orbital_radius": randf_range(30.0, 50.0), 
					"initial_angle_degrees": randf_range(0.0, 360.0),
					"clockwise": randf() > 0.5
				}
			]
		}
	]

	var solar_system_data = OrbitalSystemGenerator.generate_star_system_data(G, star_config, planets_configs)

	# Spawn the star
	if solar_system_data.has("star") and not solar_system_data.star.is_empty():
		var spawned_star_info = _spawn_body(solar_system_data.star)
		if spawned_star_info and spawned_star_info.get("type") == "star_node_ref": # Check for our custom return
			star_node = spawned_star_info.node

	# Spawn planets and their moons
	if solar_system_data.has("planets"):
		for planet_data in solar_system_data.planets:
			_spawn_body(planet_data)
			if planet_data.has("moons"):
				for moon_data in planet_data.moons:
					_spawn_body(moon_data)
	
	print("Dynamically spawned bodies in simulation: ", bodies.size())

func _ready():
	randomize() # Ensure the first run is random and different if game restarts quickly
	_generate_and_spawn_system()

func _on_restart_button_pressed():
	_clear_existing_system()
	randomize() # Ensure the new system is different from the previous one
	_generate_and_spawn_system()

func _physics_process(delta):
	apply_gravity(delta)

	# Update Player position to follow the star
	if star_node and is_instance_valid(star_node):
		var player_node = get_parent().get_node_or_null("Player")
		if player_node and is_instance_valid(player_node):
			player_node.global_position = star_node.global_position

func apply_gravity(delta):
	for i in range(bodies.size()):
		var body_a = bodies[i]
		for j in range(i + 1, bodies.size()):
			var body_b = bodies[j]
			
			var dir = body_b.position - body_a.position
			var distance = dir.length()
			if distance == 0:
				continue
			
			var force_mag = G * body_a.mass * body_b.mass / (distance * distance)
			var force = dir.normalized() * force_mag
			
			# Update velocities
			body_a.velocity += force / body_a.mass * delta
			body_b.velocity -= force / body_b.mass * delta  # Newton's third law

func _spawn_body(body_data: Dictionary):
	var new_body # Will hold the Node2D instance

	var body_type = body_data.get("type", "unknown")

	if body_type == "star":
		new_body = Node2D.new()
		new_body.name = "StarDynamic" # Give it a name for easier debugging
		var sprite = Sprite2D.new()
		sprite.texture = StarTexture
		sprite.scale = Vector2(0.3, 0.3) # Adjust as needed, matches current main.tscn Star
		new_body.add_child(sprite)
		new_body.script = BodyScript # Assign the generic body script
	elif body_type == "planet":
		new_body = PlanetScene.instantiate()
		new_body.name = "PlanetDynamic"
	elif body_type == "moon":
		new_body = MoonScene.instantiate()
		new_body.name = "MoonDynamic"
	else:
		printerr("Unknown body type to spawn: ", body_type)
		return null # Return null if spawning failed

	# Common setup for all bodies
	# Ensure the script instance is valid before setting properties if script is set dynamically
	if not new_body.get_script(): # For star, script is set above
		if body_type == "planet" or body_type == "moon": # PlanetScene/MoonScene should have script attached
			pass # Assume script is already on the scene's root
	
	# Set properties. Assumes the script on the body (body.gd or on PlanetScene/MoonScene root)
	# has 'mass' and 'velocity' variables.
	if new_body.has_method("set_mass"): # If there's a setter
		new_body.set_mass(body_data.mass)
	elif "mass" in new_body:
		new_body.mass = body_data.mass
	else:
		printerr("Body node does not have a 'mass' property or set_mass method: ", new_body.name)


	if "velocity" in new_body:
		new_body.velocity = body_data.velocity
	else:
		# This is crucial. If body.gd (or equivalent) doesn't define 'velocity',
		# you'll need to add 'var velocity: Vector2 = Vector2.ZERO' to it.
		printerr("Body node does not have a 'velocity' property: ", new_body.name)
		# As a fallback, you could try setting it anyway, but it's better to ensure it exists.
		#	new_body.set("velocity", body_data.velocity) # Less safe

	new_body.position = body_data.position

	# Add to the scene tree (as a child of SpaceManager's parent, e.g., Main)
	if get_parent():
		get_parent().call_deferred("add_child", new_body)
	else:
		printerr("SpaceManager has no parent, cannot add spawned body to scene tree.")
		return null # Cannot proceed without a parent

	# Add to the list for physics simulation
	bodies.append(new_body)

	if body_type == "star":
		return {"type": "star_node_ref", "node": new_body} # Return a reference to the star
	return new_body # For other types, or if not star
