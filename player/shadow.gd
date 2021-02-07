extends Node2D

onready var player: Player = owner
onready var shadow: Node2D = $ShadowPos
onready var raycast: RayCast2D = $RayCast2D

func _ready():
	raycast.add_exception(owner)

func _physics_process(delta):
	shadow.global_position.y = player.global_position.y
	if !player.grounded and raycast.is_colliding(): # trying out disabling 
		shadow.global_position.y = raycast.get_collision_point().y
		if player.grounded and player.global_position.y < shadow.global_position.y:
			shadow.global_position.y = player.global_position.y
		shadow.modulate.a += 0.025
	else:
		shadow.global_position.y = player.global_position.y
		shadow.modulate.a -= 0.025
		
	shadow.modulate.a = clamp(shadow.modulate.a, 0, 0.25)
