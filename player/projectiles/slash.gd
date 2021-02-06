extends Node2D

var speed := 6.0
var alive_time := 0.0

func _ready():
	global_rotation_degrees = 90
	scale = Vector2(1.2, 1.2)
	
func _physics_process(delta):
	alive_time += delta
	global_position += speed * Vector2.UP.rotated(global_rotation)
	scale = scale.linear_interpolate(Vector2.ONE, 0.1)
	
	if alive_time > 10:
		queue_free()


func _on_Area2D_body_entered(body):
	pass

func _on_DieOnImpactChecker_body_entered(body):
	if body.owner is Player:
		print("Ignore player")
		return
	speed = 0
	yield(get_tree().create_timer(0.01), "timeout")
	queue_free()
	print("died to " + str(body))

