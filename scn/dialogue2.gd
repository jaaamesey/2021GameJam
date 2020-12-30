extends Control


var dict := {}

var current: Dictionary

func _ready():
	var file = File.new()
	file.open("res://txt/game.poopliga", file.READ)
	var text = file.get_as_text()
	dict = parse_json(text)
	file.close()

	go_to("JOURNAL")
	ScreenFX.black_dir = -2.0

func _input(event: InputEvent) -> void:
	if Input.is_action_just_released("next_dialogue"):
		go_to_next()

func go_to_next():
	match current["tail"]:
		"END":
			$RichTextLabel.text = "To be continued..."
			$RichTextLabel.get_font("font").size = 80
			$TextureRect.visible = false
			return

	go_to(current["tail"])

func go_to(id):
	current = dict[id]
	$RichTextLabel.text = current.text



func _on_AudioStreamPlayer_finished() -> void:
	go_to("DUMB")
