class_name LevelFragment
extends Node2D

export(float, 0, 10) var difficulty := 0.0
export var enabled := true

onready var tilemap: TileMap = $TileMap
onready var tilemap_rect_size: Vector2 = tilemap.get_used_rect().size

# Called when the node enters the scene tree for the first time.
func _ready():
	if get_parent().name != "Endless":
		return
	remove_child($GUIDES)
	remove_child($player)
