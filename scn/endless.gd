extends Node2D

onready var player: Player = $player
onready var distance_text: Label = $CanvasLayer/Control/Label

var fragments := []
var kill_x := -200.0
var kill_x_mod := 1.0

var max_travelled := 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	load_fragments()

func _physics_process(delta):
	var player_x := player.global_position.x
	kill_x += kill_x_mod * 60 * delta
	kill_x = max(kill_x, player_x - 460)
	kill_x_mod += 0.01 * delta
	kill_x_mod = min(kill_x_mod, 4.20)

	$KillRect.rect_size.x = kill_x - $KillRect.rect_global_position.x
	
	max_travelled = max(max_travelled, player_x)
	distance_text.text = str(floor(max_travelled / 32)) + "m"
	
	
	if player_x < kill_x or player.global_position.y > 500:
		player.kill()

func load_fragments():
	var fragments_path := "res://scn/level_fragments"
	var fragment_strings := get_files(fragments_path)
	for file_name in fragment_strings:
		var scene := load(fragments_path + "/" + file_name)
		var instanced_scene: LevelFragment = scene.instance()
		if !instanced_scene.enabled:
			continue
		fragments.push_back(instanced_scene)
	
	# Re-order fragments from least to most difficult
	fragments.sort_custom(LevelSorter, "sort_by_difficulty_asc")	
	
	var x_pos := 0
	for fragment in fragments:
		add_child(fragment)
		fragment.global_position = Vector2(x_pos, -64)
		x_pos += 32 * fragment.tilemap_rect_size.x


class LevelSorter:
	static func sort_by_difficulty_asc(a: LevelFragment, b: LevelFragment):
		if a.difficulty < b.difficulty:
			return true
		return false

		
func generate_level(): 
	pass
	
func get_files(path: String) -> Array:
	var files := []
	var dir := Directory.new()
	dir.open(path)
	dir.list_dir_begin(true)

	var file = dir.get_next()
	while file != '':
		files += [file]
		file = dir.get_next()

	return files
