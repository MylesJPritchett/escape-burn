# Global space manager node
extends Node2D

const BodyScript = preload("res://body.gd")
const PlanetScene = preload("res://planet.tscn")
const MoonScene = preload("res://moon.tscn")
const StarTexture = preload("res://the-sun.webp")
const OrbitalSystemGenerator = preload("res://orbital_system_generator.gd")

var bodies = []
@export var G = 10000.0 # Reduced G to slow down the simulation

func _ready():
	randomize() # For random initial angles if not specified

	var star_config = {
		"mass": 1000.0,
		# Position the star at the center of where SpaceManager is (usually Main's origin if SpaceManager is at 0,0)
		# Or, if you want it screen-centered and SpaceManager is a child of Main (at 0,0):
		"position": Vector2.ZERO # Center the star at SpaceManager's origin
		# "velocity": Vector2.ZERO # Optional: if the whole system should have an initial drift
	}

	var planets_configs = [
		{
			"mass": 30.0, "orbital_radius": 400.0, "initial_angle_degrees": 0, # Increased planet's orbital radius
			"moons": [
				{ "mass": 1.0, "orbital_radius": 25.0, "initial_angle_degrees": 90, "clockwise": false }
			]
		},
		{
			"mass": 20.0, "orbital_radius": 600.0, "initial_angle_degrees": 180, "clockwise": true
		},
		{
			"mass": 50.0, "orbital_radius": 750.0, "initial_angle_degrees": 270,
			"moons": [
				{ "mass": 2.0, "orbital_radius": 40.0, "initial_angle_degrees": 0, "clockwise": true }
			]
		}
	]

	var solar_system_data = OrbitalSystemGenerator.generate_star_system_data(G, star_config, planets_configs)

	# Spawn the star
	if solar_system_data.has("star") and not solar_system_data.star.is_empty():
		_spawn_body(solar_system_data.star)

	# Spawn planets and their moons
	if solar_system_data.has("planets"):
		for planet_data in solar_system_data.planets:
			_spawn_body(planet_data)
			if planet_data.has("moons"):
				for moon_data in planet_data.moons:
					_spawn_body(moon_data)
	
	print("Dynamically spawned bodies in simulation: ", bodies.size())

func _physics_process(delta):
	apply_gravity(delta)

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
		return

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
		return # Cannot proceed without a parent

	# Add to the list for physics simulation
	bodies.append(new_body)
