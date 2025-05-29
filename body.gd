# Attached to each gravitating body
extends Node2D

@export var mass = 1.0
var velocity = Vector2.ZERO

func _physics_process(delta):
	position += velocity * delta
