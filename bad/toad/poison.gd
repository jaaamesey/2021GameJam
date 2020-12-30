extends Area2D


# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$AnimatedSprite.play("default")
	$AnimatedSprite.frame = 3

func _physics_process(delta: float) -> void:
	for area in get_overlapping_areas():
		if area.name == "HurtBox" and area.owner is Player:
			var body: Player = area.owner
			var space_state = get_world_2d().direct_space_state
			var result = space_state.intersect_ray(global_position, body.global_position + Vector2(0, -64), [self])
			if result.empty() or result.collider is Player:
				body.kill()

func _on_AnimatedSprite_animation_finished() -> void:
	queue_free()
