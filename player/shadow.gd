extends Node2D

onready var player: Player = owner
onready var shadow: Node2D = $ShadowPos
onready var raycast: RayCast2D = $RayCast2D

func _ready():
	raycast.add_exception(owner)

func _physics_process(delta):
	shadow.scale.x = 1
	shadow.visible = true
	if raycast.is_colliding(): 
		shadow.global_position.y = raycast.get_collision_point().y
		
		if player.timer_done("jump_cooldown") and player.grounded:
			if shadow.global_position.y > player.global_position.y:
				shadow.global_position.y = player.global_position.y
	
		shadow.scale.x = clamp((64.0 - shadow.position.y) / 64.0, 0.5, 1.0) 
		shadow.modulate.a += 0.025
	elif player.timer_done("jump_cooldown") and player.grounded:
		shadow.global_position.y = player.global_position.y

	else:
		shadow.global_position.y = player.global_position.y
		shadow.modulate.a -= 0.025
		shadow.visible = false
		
	shadow.modulate.a = clamp(shadow.modulate.a, 0, 0.25)
