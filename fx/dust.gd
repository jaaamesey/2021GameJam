extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	global_rotation_degrees = randf() * 360
	scale *= rand_range(1.2, 2.0)
	pass # Replace with function body.

func _physics_process(delta):
	scale *= 0.9
	if scale.length_squared() < 0.1:
		queue_free()
