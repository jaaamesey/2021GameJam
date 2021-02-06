class_name Player
extends RigidBody2D

var dirt_fx := preload("res://fx/Dirt Crumbles/dirt.tscn")

var x_spd_deadzone := 3.0

var ground_accel_spd := 3.0
var air_accel_spd := 2.4
var max_spd := 270.0
var ground_friction := 3.8
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

var ground_slide_additional_spd := 120 # Speed to add when using ground slide
var min_ground_slide_spd := 300.0 # Minimum speed when using ground slide (this will usually come up when stationary)

var wait_to_dig_time := 0.134

var apply_floor_velocity_on_jump := true

onready var timer_times := {
	"jump_cooldown": 0.20,
	"jump_buffer": 0.18,
	"short_hop": 0.10,
	"coyote_time": 0.10,
	"wall_coyote_time": 0.10,
	"ground_pound_freeze": 0.4,
	"ground_pound_landing": 0.4,
	"ground_slide": 0.4,
	"attack_buffer": 0.18,
	"store_floor_influence_y": 0.30
}
var timers := {}

var grounded := false

var last_wall_slide_dir := 0
var last_wall_jump_dir := 0
var doing_wall_slide := false
var was_inputting_x_during_wall_slide := false

var facing := Vector2.RIGHT
var dig_facing := facing

var input_x := 0
var input_y := 0

var last_input_x := 1

var in_ground_pound := false
var in_ground_slide := false

var attacking := false

var is_dead := false

var extra_velocity := Vector2()

var floor_velocity := Vector2()

var last_floor_body: RigidBody2D = null

var stored_floor_influence_y := 0.0
var last_jump_floor_influence := Vector2()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for key in timer_times:
		timers[key] = 0
	$DigIndicator.visible = false
	ScreenFX.black_dir = -2.0

func _integrate_forces(state: Physics2DDirectBodyState) -> void:
	if is_dead:
		state.linear_velocity = Vector2()
		return
	if Input.is_action_just_released("reset"):
		kill()
	var delta := get_physics_process_delta_time()

	# Decrement timers
	for key in timer_times:
		timers[key] -= delta
		timers[key] = clamp(timers[key], -1, timer_times[key])

	if timer_done("store_floor_influence_y"):
		stored_floor_influence_y = 0

	# Ground check
	var prev_grounded := grounded
	grounded = false
	
	state.linear_velocity -= extra_velocity
	floor_velocity = Vector2.ZERO
	
	var floor_body: RigidBody2D = null
	
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
			if body is RigidBody2D and body.linear_velocity.length_squared() > floor_velocity.length_squared():
				floor_velocity = body.linear_velocity
				floor_body = body
				if floor_velocity.y < stored_floor_influence_y:
					stored_floor_influence_y = floor_velocity.y
					start_timer("store_floor_influence_y")
					
			if body.owner is SemiSolidPlatform and body.owner.activate_when_player_standing:
				body.owner.activated = true

	var using_last_floor_body := false
	if false and floor_body == null and is_instance_valid(last_floor_body):
		grounded = true
		floor_velocity = last_floor_body.linear_velocity
		floor_body = last_floor_body
		using_last_floor_body = true
		print(floor_velocity)

	# If just left ground
	if prev_grounded and !grounded:
		start_timer("coyote_time")
		attacking = false
	
	# If just hit ground
	if !prev_grounded and grounded:
		attacking = false
		
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
		last_wall_jump_dir = 0 # Reset wall jumps
		if in_ground_pound and timer_done("ground_pound_freeze"): 
			in_ground_pound = false
			start_timer("ground_pound_landing")
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
			last_jump_floor_influence = Vector2()
			if apply_floor_velocity_on_jump:
				var floor_influence := Vector2()
				floor_influence.x = floor_velocity.x
				floor_influence.y = min(0, floor_velocity.y)
				
				if stored_floor_influence_y < floor_velocity.y:
					floor_influence.y = stored_floor_influence_y

				dx += floor_influence.x
				dy += floor_influence.y
				last_jump_floor_influence = floor_influence
				floor_velocity = Vector2()

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
				
				# Can't wall jump on any moving platforms yet :(
				last_jump_floor_influence = Vector2()
				
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
	doing_wall_slide = dy > 0 and wall_slide_dir != 0 and sign(wall_slide_dir) == sign(input_x)
	if doing_wall_slide:
		grav_spd_mod *= wall_slide_slowdown
		
	dy += grav_spd * grav_spd_mod
	
	if doing_wall_slide:
		if input_y <= 0:
			dy = min(dy, max_grav_during_wall_slide)
		if wall_climb_spd > 0 and input_y < 0:
			dy = min(dy, -wall_climb_spd)
		
		
	dy = min(dy, max_grav)
	
	if !attacking:
		if input_x > 0:
			facing = Vector2.RIGHT
		elif input_x < 0:
			facing = Vector2.LEFT
		
	if Input.is_action_just_pressed("attack"):
		start_timer("attack_buffer")
	
	# Ground pound logic (if down held down)
	if can_ground_pound() and input_y > 0 and !timer_done("attack_buffer"):
		in_ground_pound = true
		start_timer("ground_pound_freeze")
		clear_timer("attack_buffer")
	
	if in_ground_pound:
		dx = 0
		if timer_done("ground_pound_freeze"):
			dy += ground_pound_spd
		else:
			dy = 0
	
	if !timer_done("ground_pound_landing") and grounded:
		dx = 0
		
	if can_attack() and !timer_done("attack_buffer"):
		attacking = true
		clear_timer("attack_buffer")
		if grounded:
			if input_y > 0:
				start_timer("ground_slide")
				in_ground_slide = true
				var min_slide_velocity := min_ground_slide_spd * facing.x
				var max_slide_velocity := ground_slide_additional_spd * facing.x + dx
				if facing.x > 0:
					dx = max(min_slide_velocity, max_slide_velocity)
				else:
					dx = min(min_slide_velocity, max_slide_velocity)
				
			else:
				dx *= 0.5
	
	if in_ground_slide and timer_done("ground_slide"):
		attacking = false
		in_ground_slide = false
		
	extra_velocity = Vector2()
	extra_velocity.x += floor_velocity.x
	
	state.linear_velocity = Vector2(dx, dy) + extra_velocity
	
	last_floor_body = floor_body

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

func can_attack():
	if in_ground_pound or !timer_done("ground_pound_landing"):
		return false
	if attacking or !timer_done("ground_slide"):
		return false
	if doing_wall_slide:
		return false
	return true
	
func can_ground_pound():
	if in_ground_pound or !timer_done("ground_pound_landing"):
		return false
	if attacking or !timer_done("ground_slide"):
		return false
	if ground_pound_spd <= 0:
		return false
	if grounded:
		return false
	return true
	
func timer_done(timer):
	return timers[timer] <= 0

func start_timer(timer):
	timers[timer] = timer_times[timer]

func get_timer(timer):
	return timers[timer]

func clear_timer(timer):
	timers[timer] = 0
