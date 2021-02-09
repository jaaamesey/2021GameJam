extends Node2D

onready var sprite: AnimatedSprite = get_parent()
onready var rect: Control = $rect
onready var cape: Node2D = $Cape
onready var player: Player = owner

onready var cape_base_offset := cape.position

var last_facing := 1
	
func _physics_process(delta):
	set_pos()
	var rot_target := 0.0
	var facing_changed := sign(last_facing) != sign(player.facing.x)

	if abs(player.linear_velocity.x) > 1.0 and sign(player.linear_velocity.x) == sign(player.facing.x):
		rot_target = 90 
		if player.facing.x < 0:
			rot_target = 360 - 90
	if player.linear_velocity.y > 20.0:
		rot_target = 180
	
	cape.position = rect.rect_position
	if player.facing.x < 0:
		cape.position.x *= -1
		cape.position.x += 3
		last_facing = -1
	else:
		last_facing = 1
		
	var lerp_spd := 0.05
	if facing_changed and rot_target != 180:
		rot_target = 360 - rot_target
		lerp_spd = 1.0
	cape.global_rotation = lerp_angle(cape.global_rotation, deg2rad(rot_target), lerp_spd)
	
	
func set_pos():
	var pos := Vector2()
	var rot := 0.0
	match sprite.animation:
		"idle":
			if sprite.frame == 0:
				pos = Vector2(0, -5)
			else:
				pos = Vector2(0, -4)
		"walk":
			rot = 90
			match sprite.frame:
				0:
					pos = Vector2(9, -3)
				1:
					pos = Vector2(8, -4)
				2: 
					pos = Vector2(10, -5)
				3: 
					pos = Vector2(8, -4)
		"air_slash":
			match sprite.frame:
				0:
					pos = Vector2(-1, -6)
				1:	
					pos = Vector2(-3, -6)
				2:	
					pos = Vector2(-5, -6)
				3:
					pos = Vector2(-4, -6)
		"fall":
			pos = Vector2(-4, -3)
		"ground_slash":
			pos = Vector2(0, -4)
		"ground_slide":
			pos = Vector2(-12, 7)
		"jump":
			pos = Vector2(0, -3)
		"slide":
			rot = 90
			pos = Vector2(2, -5)
		"speen":
			match sprite.frame:
				0:
					rot = 90
					pos = Vector2(6, 2)
				1:
					pos = Vector2(-1, 1)
				2:
					pos = Vector2(2, -2)
				3:
					pos = Vector2(2, -2)
		
	if sprite.flip_h:
		pos.x *= -1
		if rot == 90:
			pos.x += 1
	position = pos
	rect.rect_rotation = rot
