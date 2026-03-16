extends Node

@export var potion_scenes: Array[PackedScene]
@export var min_bounds: Vector2
@export var max_bounds: Vector2

func _on_spawn_timer_timeout() -> void:
	var potion = potion_scenes[randi() % len(potion_scenes)].instantiate()
	add_child(potion)
	var pos = get_parent().get_random_open_position()
	potion.global_position = pos # Vector2(randf_range(min_bounds.x, max_bounds.x), randf_range(min_bounds.y, max_bounds.y))
	print(potion.global_position)
