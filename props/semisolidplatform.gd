tool
class_name SemiSolidPlatform
extends Control

export(float, -1000, 1000) var target_x_offset := 0.0
export(float, -1000, 1000) var target_y_offset := 0.0
export(float, 0.0, 1.0) var starting_pos := 0.0
export(float, 0.01, 10) var seconds := 1.0
export var smooth := false
export var activate_when_player_standing := false
onready var lerp_pos := starting_pos
var dir := 1

var activated := true

onready var collision_shape := $NinePatch/RigidBody2D/CollisionShape2D
func _ready():
	var shape_template: SegmentShape2D = collision_shape.shape
	collision_shape.shape = SegmentShape2D.new()
	collision_shape.shape.a = shape_template.a
	collision_shape.shape.b = shape_template.b
	collision_shape.shape.b.x = rect_size.x
	
	if activate_when_player_standing:
		activated = false
	
	if Engine.editor_hint:
		pass
	else:
		$Guide.visible = false
		$Guide2.visible = false
		$StartingPos.visible = false
		set_process(false)
		if target_x_offset == 0:
			set_process(false)
			

func _process(delta):
	$Guide2.rect_position = Vector2()
	$Guide.rect_position = Vector2(target_x_offset, target_y_offset)
	$StartingPos.rect_position.x = lerp(0, target_x_offset, starting_pos)
	$StartingPos.rect_position.y = lerp(0, target_y_offset, starting_pos)
	collision_shape.shape.b.x = rect_size.x
		
	
func _physics_process(delta):
	if activated: lerp_pos += dir * (1.0 / seconds) * delta
	elif Engine.editor_hint: lerp_pos = starting_pos
	
	if lerp_pos >= 1.0: dir = -1
	elif lerp_pos <= 0.0: dir = 1
	
	var weight := lerp_pos
	if smooth: weight = quad_ease(weight)
		
	$NinePatch.rect_position.x = lerp(0, target_x_offset, weight)
	$NinePatch.rect_position.y = lerp(0, target_y_offset, weight)

func cubic_ease(x: float): 
	if x < 0.5: return 4 * x * x * x
	else: return 1 - pow(-2 * x + 2, 3) / 2

func quad_ease(x: float): 
	if x < 0.5: return 2 * x * x
	else: return 1 - pow(-2 * x + 2, 2) / 2
