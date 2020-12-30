class_name Player
extends RigidBody2D

onready var ground_check: Area2D = $ground_check

var dirt_fx := preload("res://fx/Dirt Crumbles/dirt.tscn")

var x_spd_deadzone := 3.0

var ground_accel_spd := 4.0
var air_accel_spd := 3.0
var max_spd := 300.0
var ground_friction := 3.0
var air_friction := 0.4
var flip_dir_spd := 1.4
var vertical_crawl_spd := 260
var dig_slowdown := 124.0
var dig_y_slowdown := 0.64

var grav_spd := 10.0
var jump_height := 666
var jump_let_go_fall_spd := 50

var wait_to_dig_time := 0.134

onready var timer_times := {
	"jump_cooldown": 0.2,
	"jump_buffer": 0.33,
	"short_hop": 0.16,
	"coyote_time": 0.11,
	"prevent_expand": 0.1,
	"input_go_small_cooldown": 0.1,
	"prevent_jump_after_size_change": 0.2,
	"up_snap_cooldown": 0.4,
	"in_dig": 0.44
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
		var floor_normal := state.get_contact_local_normal(i)
		if floor_normal.dot(Vector2(0, -1)) > 0.6:
			grounded = true
			if body is RigidBody2D and abs(body.linear_velocity.x) > abs(ground_velocity.x):
				ground_velocity.x = body.linear_velocity.x


	# If just left ground
	if prev_grounded and !grounded:
		start_timer("coyote_time")

	# Handle input
	input_x = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))
	input_y = int(Input.is_action_pressed("down")) - int(Input.is_action_pressed("up"))

	var jump_held := Input.is_action_pressed("jump") or Input.is_action_pressed("up")
	if Input.is_action_just_pressed("jump") or  Input.is_action_just_pressed("up"):
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
		if !timer_done("input_go_small_cooldown"):
			dy += jump_let_go_fall_spd * 10
		elif !jump_held and timer_done("short_hop"):
			dy += jump_let_go_fall_spd

	if coasting and abs(dx) < x_spd_deadzone:
		dx = 0

	dx += ddx
	dy += grav_spd

	dx += ground_velocity.x

	if timer_done("prevent_expand"):
		if input_x > 0:
			facing = Vector2.RIGHT
		elif input_x < 0:
			facing = Vector2.LEFT

	state.linear_velocity = Vector2(dx, dy)
	prev_ground_velocity = ground_velocity

	var space_state := get_world_2d().direct_space_state
	var start_pos := global_position + Vector2(0, -45)
	var cast_length := 150.0
	var right_cast_room := cast_length
	var left_cast_room := -cast_length
	var up_cast_end := start_pos + Vector2(0, -70)

	var right_cast := space_state.intersect_ray(start_pos, start_pos + Vector2(right_cast_room, 0), [self])
	var left_cast := space_state.intersect_ray(start_pos, start_pos + Vector2(left_cast_room, 0), [self])

	var up_cast := space_state.intersect_ray(start_pos, up_cast_end, [self])
	var up_cast_right := space_state.intersect_ray(up_cast_end, up_cast_end + Vector2(110, 0), [self])
	var up_cast_left := space_state.intersect_ray(up_cast_end, up_cast_end + Vector2(-110, 0), [self])

	if !right_cast.empty():
		right_cast_room = right_cast.position.x - start_pos.x
	if !left_cast.empty():
		left_cast_room = left_cast.position.x - start_pos.x

	var total_room := abs(right_cast_room) + abs(left_cast_room)

	var force_up_snap := false
	if !can_jump() and !is_forced_small() and timer_done("up_snap_cooldown") and input_y == -1 and up_cast.empty() and (!up_cast_left.empty() and !up_cast_right.empty()):
		var room: float = abs(up_cast_left.position.x - up_cast_end.x) + abs(up_cast_right.position.x - up_cast_end.x)
		if room > 110 and room < 129:
			force_up_snap = true
			var target_x: float = (up_cast_left.position.x + up_cast_right.position.x) / 2.0
			var target_y: float = state.transform.origin.y - 65
			state.transform.origin = Vector2(target_x, target_y)
			state.linear_velocity = Vector2()
			start_timer("prevent_expand")
			start_timer("up_snap_cooldown")

	if input_y == 1:
		facing = Vector2.DOWN
	elif input_y == -1:
		facing = Vector2.UP

	if facing == Vector2.UP and (((grounded or (!timer_done("coyote_time") and timer_done("jump_cooldown"))) and !raw_forced_small and !force_up_snap) or state.linear_velocity.y > 0):
		if input_x < 0:
			facing = Vector2.LEFT
		elif input_x > 0:
			facing = Vector2.RIGHT
		else:
			facing = Vector2(last_input_x, 0)

	raw_forced_small = false

	if total_room < cast_length:
		raw_forced_small = true
		start_timer("prevent_expand")
		if facing.y == 0:
			facing = Vector2.UP
	elif timer_done("prevent_expand") and !force_up_snap:
		if input_y == 0:
			if input_x < 0:
				facing = Vector2.LEFT
			elif input_x > 0:
				facing = Vector2.RIGHT
			else:
				facing = Vector2(last_input_x, 0)

	if !timer_done("input_go_small_cooldown") and !raw_forced_small and input_y < 0:
		if input_x < 0:
			facing = Vector2.LEFT
		elif input_x > 0:
			facing = Vector2.RIGHT
		else:
			facing = Vector2(last_input_x, 0)

	if !timer_done("prevent_expand") and facing.y == 0:
		facing = Vector2.UP

	if force_up_snap:
		raw_forced_small = true
		facing = Vector2.UP
		clear_timer("input_go_small_cooldown")
		start_timer("prevent_expand")

	if input_x != 0:
		last_input_x = input_x

	var last_size: float = $Capsule.shape.height
	# Apply stuff based on facing state
	var dig_offset_amt := 128
	$FloorCastL.position.x = -69
	$FloorCastR.position.x = 69
	$Capsule.shape.height = 80
	if is_small():
		$FloorCastL.position.x = -40
		$FloorCastR.position.x = 40
		$Capsule.shape.height = 35

	if int(last_size) != int($Capsule.shape.height):
		start_timer("prevent_jump_after_size_change")

	if is_forced_small():
		state.linear_velocity.y = input_y * vertical_crawl_spd
		if in_dig():
			state.linear_velocity.y *= dig_y_slowdown
		start_timer("input_go_small_cooldown")

	dig_facing = facing
	if input_y > 0:
		dig_facing = Vector2.DOWN
	elif input_y < 0:
		dig_facing = Vector2.UP
	if input_x > 0:
		dig_facing = Vector2.RIGHT
	elif input_x < 0:
		dig_facing = Vector2.LEFT

	$DigHitbox.position = dig_facing * dig_offset_amt

	handle_digging()

func handle_digging():
	if Input.is_action_pressed("dig") and !in_dig():
		start_timer("in_dig")
		has_dug = false
		var x_sign := sign(linear_velocity.x)
		var x_abs := abs(linear_velocity.x)
		linear_velocity.x = x_sign * min(x_abs, dig_slowdown)

	var bodies: Array = $DigHitbox.get_overlapping_bodies()
	var tilemap: TileMap = null
	for body in bodies:
		if body is TileMap:
			tilemap = body
			break

	if tilemap == null:
		return

	var tile_pos := tilemap.world_to_map($DigHitbox.get_child(0).global_position)

	var tile_diggable := tilemap.get_cellv(tile_pos) == 0 # dirt

	$DigIndicator.visible = false
	if tile_diggable:
		$DigIndicator.visible = true
		$DigIndicator.global_position = 64 * Vector2.ONE + tilemap.map_to_world(tile_pos)

	if tile_diggable and in_dig() and !has_dug:
		has_dug = true
		dig_block(tile_pos, tilemap)

func dig_block(tile_pos: Vector2, tilemap: TileMap):
	yield(get_tree().create_timer(wait_to_dig_time), "timeout")
	if tilemap.get_cellv(tile_pos) == -1:
		return
	tilemap.set_cellv(tile_pos, -1)
	tilemap.update_bitmask_area(tile_pos)
	var dirt_instance: AnimatedSprite = dirt_fx.instance()
	get_tree().current_scene.add_child(dirt_instance)
	dirt_instance.global_position = 64 * Vector2.ONE + tilemap.map_to_world(tile_pos)

func kill():
	ScreenFX.black_dir = 3.0
	is_dead = true
	yield(get_tree().create_timer(0.6), "timeout")
	get_tree().reload_current_scene()

func can_jump():
	if raw_forced_small:
		return false
	if !timer_done("prevent_jump_after_size_change"):
		return false
	if !timer_done("input_go_small_cooldown"):
		return false
	if !timer_done("jump_cooldown"):
		return false
	if grounded or !timer_done("coyote_time"):
		return true
	return false

func is_small():
	return facing.y != 0

func is_forced_small():
	return !timer_done("prevent_expand")

func in_dig():
	return !timer_done("in_dig")

func timer_done(timer):
	return timers[timer] <= 0

func start_timer(timer):
	timers[timer] = timer_times[timer]

func get_timer(timer):
	return timers[timer]

func clear_timer(timer):
	timers[timer] = 0
