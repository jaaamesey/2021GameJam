extends AnimatedSprite

onready var player : Player = owner

var vertical_flip_v := false

var frame_f := 0.0

var time_since_last_anim := 0.0
func _physics_process(delta: float) -> void:
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

	if (player.can_jump() or player.grounded) and (abs(player.input_x) > 0 or abs(player.linear_velocity.x) > 70):
		next_anim = "walk"

	if abs(player.input_y) > 0:
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

	if animation != next_anim and time_since_last_anim > 0.12:
		animation = next_anim
		time_since_last_anim = 0

func reset_to_h():
	rotation_degrees = 0
	offset = Vector2()
	flip_v = false
	if player.last_input_x < 0:
		flip_h = true
	else:
		flip_h = false
