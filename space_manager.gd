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

	var planets_configs = []
	var num_planets = randi_range(1, 5) # Generate 1 to 5 planets
	var current_planet_min_radius = 300.0
	var planet_radius_step = 150.0 # Min distance between planet orbits
	var planet_radius_range = 100.0 # Variation in orbital radius

	for i in range(num_planets):
		var planet_mass = randf_range(10.0, 60.0)
		var planet_orbital_radius = randf_range(current_planet_min_radius, current_planet_min_radius + planet_radius_range)
		
		var planet_config = {
			"mass": planet_mass,
			"orbital_radius": planet_orbital_radius,
			"initial_angle_degrees": randf_range(0.0, 360.0),
			"clockwise": randf() > 0.5,
			"moons": []
		}
		
		current_planet_min_radius = planet_orbital_radius + planet_radius_step # Ensure next planet is further out

		var num_moons = randi_range(0, 3) # 0 to 3 moons per planet
		var current_moon_min_radius = 20.0
		var moon_radius_step = 15.0 # Min distance between moon orbits
		var moon_radius_range = 10.0 # Variation in orbital radius
		
		if num_moons > 0:
			var moons_array = []
			for j in range(num_moons):
				var moon_mass = randf_range(0.1, 5.0)
				# Ensure moon orbital radius is smaller than planet's visual radius (approx) and reasonable
				var moon_orbital_radius = clamp(randf_range(current_moon_min_radius, current_moon_min_radius + moon_radius_range), 10.0, planet_orbital_radius * 0.3)

				var moon_config = {
					"mass": moon_mass,
					"orbital_radius": moon_orbital_radius,
					"initial_angle_degrees": randf_range(0.0, 360.0),
					"clockwise": randf() > 0.5
				}
				moons_array.append(moon_config)
				current_moon_min_radius = moon_orbital_radius + moon_radius_step
			planet_config["moons"] = moons_array
			
		planets_configs.append(planet_config)

	var solar_system_data = OrbitalSystemGenerator.generate_star_system_data(G, star_config, planets_configs)

	# Clear previous progression path before generating new one
	progression_path_bodies.clear()
	var temp_first_moon = null
	var temp_first_planet = null
	# Spawn the star
	if solar_system_data.has("star"):
		var star_s_data = solar_system_data.star # Use a different var name to avoid conflict
		var spawned_star_info = _spawn_body(star_s_data)
		if spawned_star_info and spawned_star_info.get("type") == "star_node_ref":
			star_node = spawned_star_info.node
			if is_instance_valid(star_node) and star_s_data.has("is_orbiting"): # Check if key exists
				star_node.is_kinematic_orbit = star_s_data.is_orbiting # Should be false for star

	# Spawn planets and their moons
	if solar_system_data.has("planets"):
		for planet_data in solar_system_data.planets:
			var planet_node = _spawn_body(planet_data) # _spawn_body returns the node instance
			
			if is_instance_valid(planet_node) and planet_data.get("is_orbiting", false):
				planet_node.is_kinematic_orbit = true
				planet_node.orbit_center_node = star_node # Planet orbits the star
				planet_node.kinematic_orbital_radius = planet_data.orbital_radius
				planet_node.kinematic_angular_speed = planet_data.angular_speed
				planet_node.kinematic_current_angle_rad = planet_data.initial_angle_radians
				planet_node.kinematic_orbit_clockwise = planet_data.clockwise_orbit
			
			if is_instance_valid(planet_node) and planet_data.has("moons"):
				for moon_data in planet_data.moons:
					var moon_node = _spawn_body(moon_data) # _spawn_body returns the node instance
					if is_instance_valid(moon_node) and moon_data.get("is_orbiting", false):
						moon_node.is_kinematic_orbit = true
						moon_node.orbit_center_node = planet_node # Moon orbits the planet
						moon_node.kinematic_orbital_radius = moon_data.orbital_radius
						moon_node.kinematic_angular_speed = moon_data.angular_speed
						moon_node.kinematic_current_angle_rad = moon_data.initial_angle_radians
						moon_node.kinematic_orbit_clockwise = moon_data.clockwise_orbit
	
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
			var force = dir.normalized() * force_mag # Force is calculated
			
			# VELOCITY UPDATES REMOVED for celestial bodies.
			# They now move kinematically.
			# body_a.velocity += force / body_a.mass * delta
			# body_b.velocity -= force / body_b.mass * delta
			
			# If other, non-celestial objects were added that ARE affected by gravity,
			# this is where you'd apply 'force' to them.

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
