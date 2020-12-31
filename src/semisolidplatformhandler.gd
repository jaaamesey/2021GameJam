extends Area2D

func _physics_process(delta):
	var is_above_ssp := false
	
	if get_overlapping_bodies().size() > 0:
		is_above_ssp = true
	
	owner.set_collision_layer_bit(1, is_above_ssp)
	owner.set_collision_mask_bit(1, is_above_ssp)
