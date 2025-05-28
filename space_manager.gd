# Global space manager node
extends Node2D

var bodies = []
@export var G = 9.81

func _ready():
	# Populate the bodies array
	# We assume bodies are children of this node's parent and have a 'mass' property
	if get_parent():
		for child in get_parent().get_children():
			if child.has_meta("mass") or child.has_method("get_mass") or "mass" in child: # Check if it's a body
				if child != self: # Don't add self if SpaceManager somehow had a mass property
					bodies.append(child)
	print("Bodies in simulation: ", bodies.size())

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
