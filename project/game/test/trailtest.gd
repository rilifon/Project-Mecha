extends Node2D

onready var trail = $Trail

func _process(dt):
	if is_instance_valid(trail):
		trail.add_point(get_global_mouse_position())
