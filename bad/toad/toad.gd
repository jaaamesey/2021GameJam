extends RigidBody2D

var killed := false
var splatted := false

var poison := preload("res://bad/toad/poison.tscn")

func _ready() -> void:
	$AnimatedSprite.play("idle")

func _integrate_forces(state: Physics2DDirectBodyState) -> void:
	if killed:
		if splatted:
			$AnimatedSprite.animation = "splat"
			if has_node("CollisionShape2D"):
				$CollisionShape2D.queue_free()
		else:
			$AnimatedSprite.animation = "attack"
		return

	for area in $Area2D.get_overlapping_areas():
		if area.name == "HurtBox" and area.owner is Player:
			var body: Player = area.owner
			var space_state = get_world_2d().direct_space_state
			var result = space_state.intersect_ray(global_position + Vector2(0, -32), body.global_position + Vector2(0, -64), [self])
			if result.empty() or result.collider is Player:
				kill()
				if body.global_position.x > global_position.x:
					$AnimatedSprite.flip_h = false
				elif body.global_position.x < global_position.x:
					$AnimatedSprite.flip_h = true

	if state.linear_velocity.x < -10:
		$AnimatedSprite.flip_h = true
	elif state.linear_velocity.x > 10:
		$AnimatedSprite.flip_h = false
	for i in range(state.get_contact_count()):
		var obj: Node2D = state.get_contact_collider_object(i)
		if obj is Boulder:
			kill()
			splatted = true

func kill():
	killed = true

func destroy():
	if !splatted:
		var poison_instance: Area2D = poison.instance()
		get_tree().current_scene.add_child(poison_instance)
		poison_instance.global_position = global_position + Vector2(0, -64)
	queue_free()


func _on_AnimatedSprite_animation_finished() -> void:
	if $AnimatedSprite.animation in ["attack", "splat"]:
		destroy()


func _on_Area2D_body_entered(body: Node) -> void:
	pass
