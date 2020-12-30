class_name Player
extends RigidBody2D

var dirt_fx := preload("res://fx/Dirt Crumbles/dirt.tscn")

var x_spd_deadzone := 3.0

var ground_accel_spd := 3.0
var air_accel_spd := 3.0
var max_spd := 270.0
var ground_friction := 3.0
var air_friction := 0.4
var flip_dir_spd := 1.8
var vertical_crawl_spd := 260
var dig_slowdown := 124.0
var dig_y_slowdown := 0.64

var grav_spd := 10.0
var max_grav := 420
var jump_height := 450
var jump_let_go_fall_spd := 50

var wait_to_dig_time := 0.134

onready var timer_times := {
	"jump_cooldown": 0.20,
	"jump_buffer": 0.20,
	"short_hop": 0.10,
	"coyote_time": 0.10
}
var timers := {}

var grounded := false

var prev_ground_velocity := Vector2()

var facing := Vector2.RIGHT
var dig_facing := facing

var input_x := 0
var input_y := 0

var last_input_x := 1

var raw_forced_small := false

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


	if !timer_done("jump_buffer") and can_jump():
		dy = -jump_height

		start_timer("jump_cooldown")
		start_timer("short_hop")
		clear_timer("jump_buffer")
		clear_timer("coyote_time")

	if dy < 0:
		if !jump_held and timer_done("short_hop") and !grounded:
			dy += jump_let_go_fall_spd 

	if coasting and abs(dx) < x_spd_deadzone:
		dx = 0

	dx += ddx
	dy += grav_spd
	
	dy = min(dy, max_grav)

	dx += ground_velocity.x
	
	if input_x > 0:
		facing = Vector2.RIGHT
	elif input_x < 0:
		facing = Vector2.LEFT

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
