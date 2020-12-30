extends Control


var dict := {}

var current: Dictionary

func _ready():
	var file = File.new()
	file.open("res://txt/game.poopliga", file.READ)
	var text = file.get_as_text()
	dict = parse_json(text)
	file.close()

	go_to("START")
	ScreenFX.black_dir = -2.0

func _input(event: InputEvent) -> void:
	if Input.is_action_just_released("next_dialogue"):
		go_to_next()

func go_to_next():
	match current["tail"]:
		"PLAY_SOUND":
			$AudioStreamPlayer.play()
			$RichTextLabel.text = ""
			$TextureRect.visible = false
			return
		"END_START":
			ScreenFX.black_dir = 2.0
			yield(get_tree().create_timer(2), "timeout")
			get_tree().change_scene("res://scn/levels/Level-0.tscn")
			return

	go_to(current["tail"])

func go_to(id):
	current = dict[id]
	$RichTextLabel.text = current.text



func _on_AudioStreamPlayer_finished() -> void:
	go_to("DUMB")
	$TextureRect.visible = true
