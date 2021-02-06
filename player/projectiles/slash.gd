extends Node2D

var speed := 6.0
func _ready():
	global_rotation_degrees = 90
	scale = Vector2(1.2, 1.2)
func _physics_process(delta):
	global_position += speed * Vector2.UP.rotated(global_rotation)
	scale = scale.linear_interpolate(Vector2.ONE, 0.1)

func _on_Area2D_body_entered(body):
	if body.owner.name == "player":
		print("Ignore player")
		return
	print("died to " + str(body))
	#queue_free()
	pass # Replace with function body.
