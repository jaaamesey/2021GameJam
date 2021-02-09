extends Node2D

onready var player: Player = $player
onready var distance_text: Label = $CanvasLayer/Control/Travelled
onready var high_score_text: Label = $CanvasLayer/Control/HighScore

var fragments := []
var kill_x := -200.0
var kill_x_mod := 1.0

var max_travelled := 0.0
var high_score := 0.0

var next_fragment_x_pos := 0.0
var last_fragment_x_pos := 0.0

var next_fragment: LevelFragment = null
var last_fragment: LevelFragment = null
var fragment_stack := []

# Called when the node enters the scene tree for the first time.
func _ready():
	high_score = SaveManager.get_high_score()
	randomize()
	load_fragments()
	add_next_fragment()

func _physics_process(delta):
	var player_x := player.global_position.x
	kill_x += kill_x_mod * 60 * delta
	kill_x = max(kill_x, player_x - 460)
	kill_x_mod += 0.01 * delta
	kill_x_mod = min(kill_x_mod, 4.20)

	$KillRect.rect_size.x = kill_x - $KillRect.rect_global_position.x
	
	max_travelled = max(max_travelled, player_x)
	distance_text.text = str(floor(max_travelled / 32)) + "m"
	high_score_text.text = "Best: " + str(floor(high_score / 32)) + "m"
	
	if player_x < kill_x or player.global_position.y > 500:
		player.kill()
	
	if player_x >= last_fragment_x_pos:
		add_next_fragment()

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

func add_next_fragment(): 
	next_fragment = fragments[randi() % fragments.size()].duplicate()
	add_child(next_fragment)
	next_fragment.global_position = Vector2(next_fragment_x_pos, -64)
	
	if last_fragment != null:
		update_last_fragment_end_column()
	
	last_fragment = next_fragment
	last_fragment_x_pos = next_fragment_x_pos
	next_fragment_x_pos += 32 * next_fragment.tilemap_rect_size.x
	fragment_stack.push_back(next_fragment)
	
	if fragment_stack.size() >= 4:
		fragment_stack.pop_front().queue_free()
		
	

func update_last_fragment_end_column():
	var max_tilemap_height := max(last_fragment.tilemap_rect_size.y, next_fragment.tilemap_rect_size.y)
	var min_tilemap_y_pos := min(last_fragment.tilemap_rect.position.y, next_fragment.tilemap_rect.position.y)
	
	for y in range(min_tilemap_y_pos, min_tilemap_y_pos + max_tilemap_height):
		var cell := last_fragment.tilemap.get_cell(last_fragment.tilemap_rect_size.x - 1, y)
		next_fragment.tilemap.set_cell(-1, y, cell)
		cell = last_fragment.tilemap.get_cell(last_fragment.tilemap_rect_size.x - 2, y)
		next_fragment.tilemap.set_cell(-2, y, cell)
	var region_start = Vector2(-2, min_tilemap_y_pos)
	var region_end = Vector2(-1, min_tilemap_y_pos + max_tilemap_height)
	next_fragment.tilemap.update_bitmask_region(region_start, region_end)
	
	for y in range(min_tilemap_y_pos, min_tilemap_y_pos + max_tilemap_height):
		next_fragment.tilemap.set_cell(-2, y, -1)

func game_over():
	if max_travelled > high_score:
		SaveManager.save_high_score(max_travelled)
	get_tree().reload_current_scene()
	
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
