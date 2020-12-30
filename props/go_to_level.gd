extends Area2D

export var is_diary := false
export var level_name: String

var dead := false

func _on_go_to_level_body_entered(body: Node) -> void:
	if dead:
		return
	if body is Player:
		go_to_level()
		dead = true

func go_to_level():
	ScreenFX.black_dir = 2.0
	yield(get_tree().create_timer(2), "timeout")
	if is_diary:
		get_tree().change_scene("res://scn/dialogue2.tscn")
		return
	get_tree().change_scene("res://scn/levels/" + level_name)
