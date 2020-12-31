class_name Player
extends RigidBody2D

var dirt_fx := preload("res://fx/Dirt Crumbles/dirt.tscn")

var x_spd_deadzone := 3.0

var ground_accel_spd := 3.0
var air_accel_spd := 2.4
var max_spd := 270.0
var ground_friction := 3.0
var air_friction := 0.4
var flip_dir_spd := 1.8
var vertical_crawl_spd := 260
var dig_slowdown := 124.0
var dig_y_slowdown := 0.64

var grav_spd := 10.0
var max_grav := 420.0
var jump_height := 450.0
var jump_let_go_fall_spd := 50.0

var wall_slide_slowdown := 1.0
var wall_climb_spd := -1.0 # disabled
var max_grav_during_wall_slide = 14.0
var wall_jump_height := 450.0
var wall_jump_pushback := 200.0

var ground_pound_spd := 400.0

var wait_to_dig_time := 0.134

onready var timer_times := {
	"jump_cooldown": 0.20,
	"jump_buffer": 0.18,
	"short_hop": 0.10,
	"coyote_time": 0.10,
	"wall_coyote_time": 0.10,
	"ground_pound_freeze": 0.22
}
var timers := {}

var grounded := false

var prev_ground_velocity := Vector2()
var last_wall_slide_dir := 0
var last_wall_jump_dir := 0
var was_inputting_x_during_wall_slide := false

var facing := Vector2.RIGHT
var dig_facing := facing

var input_x := 0
var input_y := 0

var last_input_x := 1

var in_ground_pound := false

var has_dug := false

var is_dead := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for key in timer_times:
		timers[key] = 0
	$DigIndicator.visible = false
	ScreenFX.black_dir = -2.0

func _integrate_forces(state: Physics2DDirectBodyState) -> void:
	if is_dead:
		linear_velocity = Vector2()
		return
	if Input.is_action_just_released("reset"):
		kill()
	var delta := get_physics_process_delta_time()

	# Decrement timers
	for key in timer_times:
		timers[key] -= delta
		timers[key] = clamp(timers[key], -1, timer_times[key])

	# Ground check
	var prev_grounded := grounded
	var ground_velocity := Vector2()
	grounded = false
	
	# Get collisions
	var collisions := []
	for i in range(state.get_contact_count()):
		var body := state.get_contact_collider_object(i)
		if body == self:
			continue
		collisions.append(body)
		var normal := state.get_contact_local_normal(i)
		var threshold = 0.6
		if normal.dot(Vector2.UP) > threshold:
			grounded = true
			if body is RigidBody2D and abs(body.linear_velocity.x) > abs(ground_velocity.x):
				ground_velocity.x = body.linear_velocity.x
	

	# If just left ground
	if prev_grounded and !grounded:
		start_timer("coyote_time")
		
	# Handle input
	input_x = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))
	input_y = int(Input.is_action_pressed("down")) - int(Input.is_action_pressed("up"))

	var jump_held := Input.is_action_pressed("jump")
	if Input.is_action_just_pressed("jump"):
		start_timer("jump_buffer")

	# Handle movement
	var coasting := abs(input_x) < 0.3

	if coasting:
		input_x = 0

	var dx := state.linear_velocity.x
	var dy := state.linear_velocity.y

	if grounded:
		dx -= prev_ground_velocity.x
		last_wall_jump_dir = 0 # Reset wall jumps
		if in_ground_pound: 
			in_ground_pound = false
			$Camera2D.schedule_shake(0.26, 0.05)
			$Camera2D.schedule_shake(0.3, 0.14)

	var accel_spd := ground_accel_spd
	if !grounded:
		accel_spd = air_accel_spd

	var ddx := accel_spd * input_x

	if sign(ddx) != sign(dx) and dx != 0:
		ddx *= flip_dir_spd

	if dx + ddx > max_spd:
		ddx = max_spd - dx
	elif dx + ddx < -max_spd:
		ddx = -(max_spd + dx)

	var damp_spd := ground_friction
	if !grounded:
		damp_spd = air_friction

	if coasting:
		if dx > x_spd_deadzone:
			ddx = -damp_spd
		elif dx < -x_spd_deadzone:
			ddx = damp_spd
			
			
	# Wall slide check (needs to be separate to ensure grounded value is always correct)
	var wall_slide_dir := 0 # -1: wall on left, 0: not sliding, 1: wall on right
	if !grounded and !can_jump() and timer_done("jump_cooldown"):
		for i in range(state.get_contact_count()):
			var body := state.get_contact_collider_object(i)
			if body == self:
				continue
			var normal := state.get_contact_local_normal(i)
			var threshold = 0.6
			if normal.dot(Vector2.LEFT) > threshold:
				wall_slide_dir = 1
			elif normal.dot(Vector2.RIGHT) > threshold:
				wall_slide_dir = -1
	
	if wall_slide_dir != 0:
		last_wall_slide_dir = wall_slide_dir

		if input_x != 0:
			was_inputting_x_during_wall_slide = true
			
		elif timer_done("wall_coyote_time"):
			# Only set to false if on first frame of wall slide and no x input
			was_inputting_x_during_wall_slide = false 
			
		start_timer("wall_coyote_time")

	if !timer_done("jump_buffer"): 
		if can_jump():
			# Perform jump
			dy = -jump_height

			start_timer("jump_cooldown")
			start_timer("short_hop")
			clear_timer("jump_buffer")
			clear_timer("coyote_time")
		elif !grounded and !can_jump() and !timer_done("wall_coyote_time"):
			var wall_jump_dir := 0
			if last_wall_slide_dir == -1:
				wall_jump_dir = 1
			elif last_wall_slide_dir == 1:
				wall_jump_dir = -1
			
			var facing_right := facing == Vector2.RIGHT or input_x > 0
			var facing_left := facing == Vector2.LEFT or input_x < 0
			var facing_away_from_wall := (facing_right and wall_jump_dir == 1) or (facing_left and wall_jump_dir == -1)
			
			var can_wall_jump := facing_away_from_wall and wall_jump_dir != 0 #and last_wall_jump_dir != wall_jump_dir 
			
			if can_wall_jump and (was_inputting_x_during_wall_slide or input_x != 0):
				# Perform wall jump
				dx = wall_jump_dir * wall_jump_pushback
				dy = -wall_jump_height
				
				last_wall_jump_dir = wall_jump_dir
				
				start_timer("jump_cooldown")
				start_timer("short_hop")
				clear_timer("jump_buffer")
				clear_timer("wall_coyote_time")

	if dy < 0:
		if !jump_held and timer_done("short_hop") and !grounded:
			dy += jump_let_go_fall_spd 

	if coasting and abs(dx) < x_spd_deadzone:
		dx = 0

	dx += ddx
	
	var grav_spd_mod = 1.0
	var doing_wall_slide = dy > 0 and wall_slide_dir != 0 and sign(wall_slide_dir) == sign(input_x)
	if doing_wall_slide:
		grav_spd_mod *= wall_slide_slowdown
		
	dy += grav_spd * grav_spd_mod
	
	if doing_wall_slide:
		if input_y <= 0:
			dy = min(dy, max_grav_during_wall_slide)
		if wall_climb_spd > 0 and input_y < 0:
			dy = min(dy, -wall_climb_spd)
		
		
	dy = min(dy, max_grav)

	dx += ground_velocity.x
	
	if input_x > 0:
		facing = Vector2.RIGHT
	elif input_x < 0:
		facing = Vector2.LEFT
		
	# Ground pound logic (if down held down)
	if ground_pound_spd > 0 and !grounded and !in_ground_pound and timer_done("short_hop") and input_y > 0 and Input.is_action_pressed("attack"):
		in_ground_pound = true
		start_timer("ground_pound_freeze")
	
	if in_ground_pound:
		dx = 0
		if timer_done("ground_pound_freeze"):
			dy += ground_pound_spd
		else:
			dy = 0

	state.linear_velocity = Vector2(dx, dy)
	prev_ground_velocity = ground_velocity

	if input_x != 0:
		last_input_x = input_x

func kill():
	ScreenFX.black_dir = 3.0
	is_dead = true
	yield(get_tree().create_timer(0.6), "timeout")
	get_tree().reload_current_scene()

func can_jump():
	if !timer_done("jump_cooldown"):
		return false
	if grounded or !timer_done("coyote_time"):
		return true
	return false

func timer_done(timer):
	return timers[timer] <= 0

func start_timer(timer):
	timers[timer] = timer_times[timer]

func get_timer(timer):
	return timers[timer]

func clear_timer(timer):
	timers[timer] = 0
