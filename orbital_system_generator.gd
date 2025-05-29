class_name OrbitalSystemGenerator
extends RefCounted # Use RefCounted or Object if no node features are needed

# Static function to calculate the speed for a circular orbit
static func calculate_circular_orbit_speed(G: float, central_mass: float, orbital_radius: float) -> float:
	if orbital_radius <= 0:
		printerr("Orbital radius must be positive to calculate orbit speed.")
		return 0.0
	return sqrt(G * central_mass / orbital_radius)

# Helper static function to generate moon data for a given parent (planet)
static func _generate_moons_data_for_parent(
		G: float,
		parent_mass: float,
		parent_position: Vector2,
		parent_velocity: Vector2,
		moon_configs: Array) -> Array:
	
	var moons_data_array: Array = []

	for moon_config in moon_configs:
		var moon_mass: float = moon_config.get("mass", 0.0)
		var orbital_radius: float = moon_config.get("orbital_radius", 0.0)
		# Use specified angle or generate a random one if not provided
		var initial_angle_degrees: float = moon_config.get("initial_angle_degrees", randf_range(0, 360.0))
		var initial_angle_radians: float = deg_to_rad(initial_angle_degrees)
		var clockwise: bool = moon_config.get("clockwise", false) # Default to counter-clockwise

		var moon_data: Dictionary = {}
		moon_data["type"] = "moon"
		moon_data["mass"] = moon_mass
		moon_data["is_orbiting"] = true
		moon_data["orbital_radius"] = orbital_radius # Already in config, but good to have explicitly
		moon_data["initial_angle_radians"] = initial_angle_radians
		moon_data["clockwise_orbit"] = clockwise

		# Calculate position relative to the parent
		var relative_pos = Vector2(orbital_radius, 0).rotated(initial_angle_radians)
		moon_data["position"] = parent_position + relative_pos

		# Calculate velocity for circular orbit around the parent (for initial trail & consistency)
		var speed: float = calculate_circular_orbit_speed(G, parent_mass, orbital_radius)
		moon_data["angular_speed"] = speed / orbital_radius if orbital_radius > 0.0 else 0.0
		var relative_velocity_direction: Vector2
		if clockwise:
			relative_velocity_direction = -relative_pos.orthogonal() # Clockwise tangential velocity
		else:
			relative_velocity_direction = relative_pos.orthogonal() # Counter-clockwise tangential velocity
		
		var relative_velocity = relative_velocity_direction.normalized() * speed
		moon_data["velocity"] = parent_velocity + relative_velocity
		
		moons_data_array.append(moon_data)
		
	return moons_data_array

# Main static function to generate data for the entire star system
static func generate_star_system_data(G: float, star_config: Dictionary, planets_configs: Array) -> Dictionary:
	var system_data: Dictionary = {}

	# Star data
	var star_data: Dictionary = {}
	star_data["type"] = "star"
	star_data["mass"] = star_config.get("mass", 1000.0) # Default mass if not specified
	star_data["position"] = star_config.get("position", Vector2.ZERO)
	star_data["velocity"] = star_config.get("velocity", Vector2.ZERO)
	star_data["is_orbiting"] = false # Star does not orbit kinematically
	system_data["star"] = star_data

	var planets_data_array: Array = []
	for planet_config in planets_configs:
		var planet_mass: float = planet_config.get("mass", 0.0)
		var orbital_radius: float = planet_config.get("orbital_radius", 0.0)
		# Use specified angle or generate a random one if not provided
		var initial_angle_degrees: float = planet_config.get("initial_angle_degrees", randf_range(0, 360.0))
		var initial_angle_radians: float = deg_to_rad(initial_angle_degrees)
		var clockwise: bool = planet_config.get("clockwise", false) # Default to counter-clockwise

		var planet_data: Dictionary = {}
		planet_data["type"] = "planet"
		planet_data["mass"] = planet_mass
		planet_data["is_orbiting"] = true
		planet_data["orbital_radius"] = orbital_radius # Already in config, but good to have explicitly
		planet_data["initial_angle_radians"] = initial_angle_radians
		planet_data["clockwise_orbit"] = clockwise

		# Calculate position relative to the star (which is at star_data.position)
		var relative_pos = Vector2(orbital_radius, 0).rotated(initial_angle_radians)
		planet_data["position"] = star_data.position + relative_pos

		# Calculate velocity for circular orbit around the star (for initial trail & consistency)
		var speed: float = calculate_circular_orbit_speed(G, star_data.mass, orbital_radius)
		planet_data["angular_speed"] = speed / orbital_radius if orbital_radius > 0.0 else 0.0
		var relative_velocity_direction: Vector2
		if clockwise:
			relative_velocity_direction = -relative_pos.orthogonal() # Clockwise tangential velocity
		else:
			relative_velocity_direction = relative_pos.orthogonal() # Counter-clockwise tangential velocity
		
		var relative_velocity = relative_velocity_direction.normalized() * speed
		# Absolute velocity includes the star's velocity (if the whole system is moving)
		planet_data["velocity"] = star_data.velocity + relative_velocity

		# Moons for this planet
		if planet_config.has("moons") and planet_config.moons is Array and not planet_config.moons.is_empty():
			planet_data["moons"] = _generate_moons_data_for_parent(
				G,
				planet_mass,
				planet_data.position, # Moons orbit the planet's absolute position
				planet_data.velocity, # Moons inherit the planet's absolute velocity
				planet_config.moons
			)
		else:
			planet_data["moons"] = [] # Ensure moons key exists

		planets_data_array.append(planet_data)

	system_data["planets"] = planets_data_array
	return system_data
