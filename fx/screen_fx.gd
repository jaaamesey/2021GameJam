extends CanvasLayer

var black_dir := -2.0

func _process(delta: float) -> void:
	var black_a: float = $Black.modulate.a
	black_a += black_dir * delta
	black_a = clamp(black_a, 0, 1)
	$Black.modulate = Color(0, 0, 0, black_a)

