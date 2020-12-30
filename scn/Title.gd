extends Control


# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _input(event: InputEvent) -> void:
	if Input.is_action_just_released("next_dialogue"):
		ScreenFX.black_dir = 2.0
		go_to_next()

func go_to_next():
	yield(get_tree().create_timer(2), "timeout")
	get_tree().change_scene("res://scn/levels/template.tscn")
