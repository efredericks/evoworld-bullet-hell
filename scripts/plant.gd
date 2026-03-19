extends Area2D

@export var spawn_radius := 25.0
@onready var plant_scene: PackedScene = preload("res://scenes/plant.tscn")
@onready var plant_map: TileMapLayer = $plant_map
var main_node
var random_anim_offset: float
var atlas_id: Vector2i

func _ready() -> void:
	main_node = get_tree().root.get_node("main")
	random_anim_offset = randf_range(0.0, 1000.0)
	atlas_id = main_node.PLANT_SPAWNS[randi_range(0, len(main_node.PLANT_SPAWNS)-1)]
	
func _process(delta) -> void:
	pass
	#var t = Time.get_unix_time_from_system() + random_anim_offset
	#var s = 1.0 + (sin(t  * 10) * 0.1)
	#scale.x = s
	#scale.y = s
	
func _on_body_entered(body: Node2D) -> void:
	pass
	#if not body.is_in_group("player"):
		#return
		#
	#if type == PotionType.HEALTH:
		#body.heal(value)
	#elif type == PotionType.SHOOT_SPEED:
		#body.shoot_rate *= value
		#body.additional_bullet_speed += 30.0
	#elif type == PotionType.MOVE_SPEED: 
		#body.max_speed *= value
	#else:
		#print("Invalid potion")
	#
	#body.drink_potion()
	#queue_free()

# spawn a neighbor on random chance
func _on_spawn_timer_timeout() -> void:
	# get a random position within radius
	var new_spawn_pos = Vector2(global_position.x + randf_range(-spawn_radius, spawn_radius), global_position.y + randf_range(-spawn_radius, spawn_radius))
	var grid_pos = main_node.convert_world_to_cells(new_spawn_pos)
	
	if grid_pos.x != -1: # check for valid position
		# check if occupied already
		var check = main_node.is_cell_open(grid_pos)
		if check:
			plant_tilemap_layer.set_cell(grid_pos, 0, plant_atlas_pos)
			#var new_plant = plant_scene.instantiate()
			#var grid_aligned_pos = Vector2i(grid_pos.x * main_node.tile_size + main_node.half_tile_size, grid_pos.y * main_node.tile_size + main_node.half_tile_size)
			#
			#new_plant.global_position = grid_aligned_pos #new_spawn_pos
			#new_plant.z_index = 2
			#get_tree().get_root().add_child.call_deferred(new_plant)
			main_node.remove_open_cell(grid_pos)#new_spawn_pos)
			
