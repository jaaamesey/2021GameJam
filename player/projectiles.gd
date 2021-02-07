extends Node2D

var slash := preload("res://player/projectiles/slash.tscn")

onready var animator: AnimatedSprite = owner.get_node("AnimatedSprite")
onready var player: Player = owner
onready var melee_sprite = $MeleeSprite

var prev_frame_id := ""

func _physics_process(delta):
	var animation := animator.animation 
	var frame := animator.frame
	var frame_id := animation + "##" + str(frame)
	if frame_id == prev_frame_id: return
	prev_frame_id = frame_id
	melee_sprite.visible = false
	if animation == "ground_slash":
		if frame == 1:
			slash(Vector2(16, -20), 90)
	elif animation == "air_slash":
		if frame == 1:
			slash(Vector2(16, -20), 90)
		elif frame == 2:
			slash(Vector2(0, 16), 160)
		elif frame == 3:
			slash(Vector2(-20, -10), -100)

func slash(offset: Vector2, angle_degrees: float):
	if player.facing == Vector2.LEFT:
		angle_degrees *= -1
		offset.x *= -1
	var instanced_slash := slash.instance()
	instanced_slash.global_position = player.global_position + offset
	instanced_slash.global_rotation_degrees = angle_degrees
	
	owner.owner.add_child(instanced_slash)
	
	melee_sprite.visible = true
	melee_sprite.rotation_degrees = angle_degrees
	melee_sprite.position = offset
