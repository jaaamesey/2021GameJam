extends AnimatedSprite

onready var player : Player = owner

var vertical_flip_v := false

var frame_f := 0.0

var last_velocity := Vector2()

var time_since_last_anim := 0.0
var last_anim := "idle"

var squish := Vector2.ONE

func _physics_process(delta: float) -> void:
	last_anim = animation
	time_since_last_anim += delta
	playing = true
	rotation_degrees = 0
	offset = Vector2()
	flip_h = false
	flip_v = false
	speed_scale = 1.0
	var speed_scale_mod := 1.0
	var next_anim := "idle"

	match player.facing:
		Vector2.LEFT:
			flip_h = true
		Vector2.RIGHT:
			pass
			

	if (player.can_jump() or player.grounded) and (abs(player.input_x) > 0 or abs(player.linear_velocity.x - player.floor_velocity.x) > 80):
		next_anim = "walk"

	if !player.grounded:
		next_anim = "fall"
		reset_to_h()

		if player.linear_velocity.y < 0:
			next_anim = "jump"

	if player.doing_wall_slide:
		next_anim = "slide"
		
	if player.in_ground_pound or !player.timer_done("ground_pound_landing"):
		next_anim = "speen"
		flip_h = false
		
	if player.attacking:
		if player.grounded:
			next_anim = "ground_slash"
			if !player.timer_done("ground_slide"):
				next_anim = "ground_slide"
		else:
			next_anim = "air_slash"
		
	if animation == "walk" and next_anim == "idle":
		if not frame in [0, 2, 4]:
			next_anim = "walk"
			speed_scale_mod *= 2

	if next_anim == "walk":
		var spd := player.linear_velocity.x
		if player.facing.y != 0:
			spd = player.linear_velocity.y
		speed_scale = clamp(abs(spd) / 200.0, 0.6, 1.5)
	
	speed_scale *= speed_scale_mod
	
	if last_anim != next_anim and time_since_last_anim > 0.12:
		animation = next_anim
		time_since_last_anim = 0
		
	handle_squishing()

func reset_to_h():
	rotation_degrees = 0
	offset = Vector2()
	flip_v = false
	if player.last_input_x < 0:
		flip_h = true
	else:
		flip_h = false

func handle_squishing():
	var velocity := player.linear_velocity
	if player.grounded:
		velocity.y = 0
	var acceleration := last_velocity - velocity
	var squish_target := acceleration.normalized()
	squish_target = Vector2(abs(squish_target.x), abs(squish_target.y))
	if squish_target.length_squared() < 0.99:
		squish_target = Vector2.ONE
		
	var lerp_amt := 0.15
	if abs(acceleration.x) > 4.0:
		lerp_amt = 0.2
	
	if animation == "slide":
		if last_anim != "slide":
			squish_target = Vector2(-1, 3)
			squish = squish_target
		else:
			squish_target = Vector2.ONE
			squish = lerp(squish, squish_target, 0.09)
	elif !player.timer_done("jump_cooldown"):
		if player.last_wall_jump_dir != 0:
			# If wall jump
			squish_target = Vector2(1.5, -1.0)
		else:
			if abs(velocity.x) > 4.0:
				squish_target = Vector2(1, 0)
			if player.last_jump_floor_influence.y < -100:
				squish_target = Vector2(2, -1)
		squish = squish_target
	else:
		squish = lerp(squish, squish_target, lerp_amt)
		

	scale = (0.95 * Vector2.ONE) + 0.07 * squish

	var extra_y_offset := 2 * (max(16 - (scale.y * 16), 0))
	offset.y += extra_y_offset

	last_velocity = velocity

func _on_AnimatedSprite_animation_finished():
	if animation == "ground_slash" or animation == "air_slash":
		player.attacking = false
