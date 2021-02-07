extends Node2D

onready var area: Area2D = $Area2D
var fall_dir := 1
func _ready():
	global_rotation_degrees = randf() * 360
	scale *= rand_range(1.2, 2.0)
	
	if randf() < 0.1: fall_dir = -1

func _physics_process(delta):
	var should_fall = true
	for body in area.get_overlapping_bodies():
		if body.owner.name == "Player":
			continue
		else:
			should_fall = false
	if should_fall:
		global_position.y += fall_dir * rand_range(0.1, 1.8)
		
	scale *= 0.9
	if scale.length_squared() < 0.1:
		queue_free()
