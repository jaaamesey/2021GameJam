class_name LevelFragment
extends Node2D

export(float, 0, 10) var difficulty := 0.0

onready var tilemap: TileMap = $TileMap
onready var tilemap_rect_size: Vector2 = tilemap.get_used_rect().size

# Called when the node enters the scene tree for the first time.
func _ready():
	remove_child($GUIDES)
	remove_child($player)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
