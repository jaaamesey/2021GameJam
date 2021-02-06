extends Camera2D

var maxOffset := 200
var _trauma := 0.0

onready var _initial_y_pos := global_position.y
	
func _process(delta):
	_trauma = max(0, _trauma - delta)
	var shake = min(1.0, _trauma * _trauma * _trauma)
	offset = maxOffset * shake * Vector2(rand_range(-1, 1), rand_range(-1, 1))
	
	global_position.y = _initial_y_pos

func shake(additional_trauma: float):
	_trauma += additional_trauma 


func schedule_shake(additional_trauma: float, seconds: float):
	yield(get_tree().create_timer(seconds), "timeout")
	shake(additional_trauma)
