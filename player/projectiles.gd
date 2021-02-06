extends Node2D

var slash := preload("res://player/projectiles/slash.tscn")

onready var animator: AnimatedSprite = owner.get_node("AnimatedSprite")
onready var player: Player = owner

var prev_frame_id := ""

func _physics_process(delta):
	var animation := animator.animation 
	var frame := animator.frame
	var frame_id := animation + "##" + str(frame)
	if frame_id == prev_frame_id: return
	prev_frame_id = frame_id
	if animation == "ground_slash":
		if frame == 2:
			var instanced_slash := slash.instance()
			get_tree().root.add_child(instanced_slash)
			instanced_slash.global_position = player.global_position + Vector2(0, -20)
			instanced_slash.global_rotation_degrees = 90
			if player.facing == Vector2.LEFT:
				instanced_slash.global_rotation_degrees = -90
