class_name DustMaker
extends Node2D

var dust_scn := preload("res://fx/dust.tscn")

func make_jump_dust():
	for i in range(3):
		var dust: Node2D = dust_scn.instance()
		dust.global_position = global_position + Vector2(i * rand_range(6, 10) - 8, 0)
		owner.owner.add_child(dust)

func make_wall_jump_dust(dir: int):
	for i in range(3):
		var dust: Node2D = dust_scn.instance()
		dust.global_position = global_position + Vector2(16 * -dir, i * rand_range(6, 10) - 24)
		owner.owner.add_child(dust)
		dust.scale *= 1.6

func make_ground_slide_dust():
	for i in range(3):
		var dust: Node2D = dust_scn.instance()
		dust.global_position = global_position + Vector2(i * rand_range(6, 10) - 8 , 0)
		owner.owner.add_child(dust)
		
	yield(get_tree().create_timer(0.2), "timeout")
	if !owner.grounded: return
	for i in range(3):
		var dust: Node2D = dust_scn.instance()
		dust.global_position = global_position + Vector2(i * rand_range(6, 10) - 8, 0)
		owner.owner.add_child(dust)
		dust.scale *= 0.8

func make_ground_pound_dust():
	for i in range(5):
		var dust: Node2D = dust_scn.instance()
		dust.global_position = global_position + Vector2(i * rand_range(6, 10) - 16 , 0)
		owner.owner.add_child(dust)
		dust.scale *= 2
		
	yield(get_tree().create_timer(0.2), "timeout")
	if !owner.grounded: return
	for i in range(8):
		var dust: Node2D = dust_scn.instance()
		dust.global_position = global_position + Vector2(i * rand_range(6, 10) - 28, 0)
		owner.owner.add_child(dust)
		dust.scale *= 1.1
