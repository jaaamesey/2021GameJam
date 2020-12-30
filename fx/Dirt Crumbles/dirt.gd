extends AnimatedSprite


# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	play("default")

func _physics_process(delta: float) -> void:
	position += 100 * delta * Vector2.DOWN

func _on_dirt_animation_finished() -> void:
	queue_free()
