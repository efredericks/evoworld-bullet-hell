extends CharacterBody2D

#@onready var plant = preload("res://scenes/plant.tscn")
#@onready var plants_group: Node = get_node("../Plants") $Plants
var main_node: Node2D
var atlas_id: Vector2i
var plant_node

func _ready() -> void:
	# get info for spawning plant
	main_node = get_tree().root.get_node("main")
	plant_node = main_node.get_node("plant_map")
	atlas_id = main_node.PLANT_SPAWNS[randi_range(0, len(main_node.PLANT_SPAWNS)-1)]
	
func _process(delta) -> void:
	var t = Time.get_unix_time_from_system()
	var s = 1.0 + (sin(t  * 10) * 0.1)
	scale.x = s
	scale.y = s
	
func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player") and body.has_method("get_energy"):
		body.get_energy()
		queue_free()
		
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
	

func _on_timer_timeout() -> void:
	#var _plant = plant.instantiate()
	#_plant.global_position = global_position
	#_plant.z_index = 2
	#get_tree().get_root().add_child.call_deferred(_plant)
	
	# spawn plant on tilemap
	var grid_pos = main_node.convert_world_to_cells(global_position)
	if grid_pos.x != -1:
		plant_node.set_cell(grid_pos, 0, atlas_id)
		main_node.plant_positions.append({'pos': grid_pos, 'atlas_id': atlas_id})
		main_node.remove_open_cell(grid_pos)
	queue_free()
	
	# in _physics_process or on input
#func check_plant_interaction() -> void:
	#var player_cell = Vector2i(
		#int(player.global_position.x / tile_size),
		#int(player.global_position.y / tile_size)
	#)
	### check player cell and neighbors
	##for offset in [Vector2i(0,0), Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
		##var cell = player_cell + offset
		##var data = plant_layer.get_cell_tile_data(cell)
		##if data and data.get_custom_data("interactable"):
			##_interact_with_plant(cell)
			##break
