# for html5 export to gh pages - remove threading
extends Node2D

var elapsed_time: float
var enable_audio: bool = true
var master_bus_idx: int

@onready var elapsed_time_label: Label = $CanvasLayer/ElapsedTimeLabel
@onready var end_screen = $CanvasLayer/EndScreen
@onready var end_label = $CanvasLayer/EndScreen/EndLabel
@onready var cursor = $MouseCursor
@onready var audio_button = $CanvasLayer/AudioButton
@onready var loading_screen = $CanvasLayer/LoadingScreen
@onready var loading_rotator = $CanvasLayer/LoadingScreen/Rotator

# overworld things
@onready var outer_boundary: StaticBody2D = $OuterBoundary
@onready var bottom_boundary: CollisionShape2D = $OuterBoundary/BottomBoundary
@onready var top_boundary: CollisionShape2D = $OuterBoundary/TopBoundary
@onready var left_boundary: CollisionShape2D = $OuterBoundary/LeftBoundary
@onready var right_boundary: CollisionShape2D = $OuterBoundary/RightBoundary
@onready var overworld = $overworld
var loading_thread: Thread
const tile_size:int = 32
# map data - move to its own script after this works
@export var num_rows: int = 500
@export var num_cols: int = 500
var map_width: int = num_cols * tile_size
var map_height: int = num_rows * tile_size
var half_map_width: int = int(map_width / 2)
var half_map_height: int = int(map_height / 2)

var open_cells: Array[Vector2i] = []
var BRICK_FLOOR: Array[Vector2i] = [
	Vector2i(17,14), Vector2i(18,14), Vector2i(19,14), Vector2i(20,14),
]
var BRICK_WALL: Array[Vector2i] = [
	Vector2i(22,13), Vector2i(23,13), Vector2i(24,13), Vector2i(25,13), 
	Vector2i(26,13), Vector2i(27,13), Vector2i(28,13),
]

var WATER: Array[Vector2i] = [
	#Vector2i(27, 19), Vector2i(28, 19), Vector2i(29, 19), Vector2i(30, 19), Vector2i(31, 19),
	#Vector2i(32, 19), Vector2i(33, 19), Vector2i(34, 19), Vector2i(35, 19),
	Vector2i(19, 19), Vector2i(20, 19)#, Vector2i(21, 19), Vector2i(22, 19), 
]
var GRASS: Array[Vector2i] = [
	Vector2i(0, 15), Vector2i(1, 15), Vector2i(2, 15), Vector2i(3, 15), 
	Vector2i(4, 15), Vector2i(5, 15), Vector2i(6, 15), 
]
var BEACH: Array[Vector2i] = [
	Vector2i(14, 13), Vector2i(15, 13), Vector2i(16, 13), Vector2i(17, 13), 
	Vector2i(18, 13), Vector2i(19, 13), Vector2i(20, 13), Vector2i(21, 13), 
]
var STONE: Array[Vector2i] = [
	Vector2i(17,14), Vector2i(18,14), Vector2i(19,14), Vector2i(20,14)
]

var SNOW: Array[Vector2i] = [
	Vector2i(41,13), Vector2i(42,13), Vector2i(43,13), Vector2i(44,13), 
]

var noise = FastNoiseLite.new()
var noise2 = FastNoiseLite.new()
#---



@onready var enemy_spawner = $EnemySpawner
@onready var player = $player
@onready var camera = $Camera2D
#@export var overworld: PackedScene = preload("res://scenes/overworld.tscn")

# camera info
@export_category("Camera")
@export var camera_zoom_min: float = 0.1
@export var camera_zoom_max: float = 1.5
@export var camera_zoom_step: float = 0.15
@export var camera_zoom_speed: float = 5.0
var target_zoom = 1.0



@onready var GP_enemy = $enemy

#var game_map
#var loading_done: bool = false
#var loading_start: bool = false
#var lr: float = 0.0

func get_random_open_position() -> Vector2:
	var cell = open_cells[randi_range(0, open_cells.size() - 1)]
	return Vector2(cell.x * tile_size, cell.y * tile_size)
	
func _ready() -> void:
	randomize()
	
	# camera zoom
	target_zoom = camera.zoom.x
	
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.005  # lower = larger features
	noise.domain_warp_enabled = true
	noise.domain_warp_amplitude = 50.0
	noise.domain_warp_frequency = 0.01
	
	noise2.seed = randi()
	noise2.frequency = 0.002  # higher frequency = smaller details

	Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
	cursor.visible = true
	cursor.global_position = get_global_mouse_position()
	master_bus_idx = AudioServer.get_bus_index("Master")

	# No thread - call directly
	#await get_tree().process_frame
	#_generate_overworld()
	#loading_screen.visible = true
	loading_thread = Thread.new()
	loading_thread.start(_generate_overworld)#.bind("args")	
	loading_thread.wait_to_finish()
	#loading_screen.visible = false
	#var oc = open_cells[randi_range(0, len(open_cells)-1)]
	
	outer_boundary.global_position = Vector2.ZERO
	left_boundary.global_position = Vector2(0, map_height / 2.0)
	right_boundary.global_position = Vector2(map_width, map_height / 2.0)
	top_boundary.global_position = Vector2(map_width / 2.0, 0)
	bottom_boundary.global_position = Vector2(map_width / 2.0, map_height)
	
	camera.limit_enabled = true
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = map_width
	camera.limit_bottom = map_height
	
	enemy_spawner.get_node("EnemySpawnPoint").global_position = get_random_open_position() #Vector2i(100, 100)
	enemy_spawner.get_node("EnemySpawnPoint2").global_position = get_random_open_position() #Vector2i(map_width - 100, 100)
	enemy_spawner.get_node("EnemySpawnPoint3").global_position = get_random_open_position() #Vector2i(100, map_height - 100)
	enemy_spawner.get_node("EnemySpawnPoint4").global_position = get_random_open_position() #Vector2i(map_width - 100, map_height - 100)
	
	
	#outer_boundary.global_position = Vector2(map_width / 2.0, map_height / 2.0)
	#left_boundary.global_position.x = -map_width / 2.0
	#right_boundary.global_position.x = map_width / 2.0
	#top_boundary.global_position.y = -map_height / 2.0
	#bottom_boundary.global_position.y = map_height / 2.0
	#
	player.global_position = get_random_open_position() #Vector2(oc.x * tile_size, oc.y * tile_size)
	GP_enemy.global_position = player.global_position + Vector2(tile_size, 4*tile_size)
	camera.global_position - player.global_position
	print("outer position:", outer_boundary.global_position)
	print("left boundary x: ", left_boundary.global_position.x)
	print("right boundary x: ", right_boundary.global_position.x)
	print("top boundary y: ", top_boundary.global_position.y)
	print("bottom boundary y: ", bottom_boundary.global_position.y)
	
func _process(delta) -> void:
	# camera zoom
	var _camera_z := lerpf(camera.zoom.x, target_zoom, camera_zoom_speed * delta)
	camera.zoom = Vector2(_camera_z, _camera_z)
	
	
	#if loading_done:
	elapsed_time += delta
	elapsed_time_label.text = str("%.1f" % elapsed_time)
	#else:
		#if loading_start:
			#loading_rotator.rotation = lr
			#lr += 1 * delta
		#else:
			#game_map = overworld.instantiate()
			#add_child(game_map)
			#loading_start = false
			#move_child(player, get_child_count() - 1)
			#loading_done = true
			#loading_screen.visible = false

		
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
			cursor.visible = true
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			cursor.visible = false
			
	if Input.mouse_mode == Input.MOUSE_MODE_CONFINED_HIDDEN:
		cursor.global_position = get_global_mouse_position()
		
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
		
	if Input.is_action_just_pressed("fullscreen"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func set_game_over() -> void:
	Engine.time_scale = 0.0
	end_screen.visible = true
	end_label.text = "You survived for %.1f seconds" % elapsed_time

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				target_zoom = clampf(target_zoom + camera_zoom_step, camera_zoom_min, camera_zoom_max)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				target_zoom = clampf(target_zoom - camera_zoom_step, camera_zoom_min, camera_zoom_max)

func _on_retry_button_pressed() -> void:
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_button_pressed() -> void:
	print(enable_audio)
	enable_audio = not enable_audio
	if enable_audio: audio_button.text = "sound on"
	else: audio_button.text = "sound off"
	
	AudioServer.set_bus_mute(master_bus_idx, not enable_audio)

#func _generate_overworld() -> void:
	## mutex for sharing progress
	#for r in range(num_rows):
		#for c in range(num_cols):
			#var pos = Vector2i(r, c)
			#var atlas_pos = Vector2i(0, 0)
			#
			#if c == 0 or c == num_cols-1 or r == 0 or r == num_rows-1:
				#atlas_pos = BLOCKING['BRICK_WALL'][randi_range(0, len(BLOCKING['BRICK_WALL'])-1)]
			#else:
				#atlas_pos = WALKABLE['BRICK_FLOOR'][randi_range(0, len(WALKABLE['BRICK_FLOOR'])-1)]
				#open_cells.append(Vector2i(c, r))
			#overworld.set_cell(pos, 0, atlas_pos)
	##var oc = open_cells[randi_range(0, len(open_cells)-1)]
	##player.call_deferred("set_global_position", Vector2i(oc.x * tile_size, oc.y * tile_size))


# noise with falloff from center
func _generate_overworld() -> void:
	var center = Vector2(num_cols / 2.0, num_rows / 2.0)
	var max_dist = min(num_cols, num_rows) / 2.0
	
	for r in range(num_rows):
		for c in range(num_cols):
			var pos = Vector2i(c, r)  # fixed
			var atlas_pos = Vector2i(0, 0)
			
			if c == 0 or c == num_cols-1 or r == 0 or r == num_rows-1:
				atlas_pos = BRICK_WALL[randi() % BRICK_WALL.size()]
			else:
				# distance from center, normalized 0-1
				var dist = Vector2(c, r).distance_to(center) / max_dist
				#var noise_val = noise.get_noise_2d(c, r) * 0.1 # returns -1.0 to 1.0
				var noise_val = (noise.get_noise_2d(c, r) * 0.15) + (noise2.get_noise_2d(c, r) * 0.025)

				# combine distance with noise
				var val = dist + noise_val
				atlas_pos = _get_tile_for_value(val)#noise_val)
				if is_walkable(val):
					open_cells.append(pos)
				#atlas_pos = WALKABLE['BRICK_FLOOR'][randi_range(0, len(WALKABLE['BRICK_FLOOR'])-1)]
				#open_cells.append(Vector2i(c, r))
			overworld.set_cell(pos, 0, atlas_pos)

func is_walkable(val: float) -> bool:
	return val < 0.65 #-0.3 and val < 0.2  # anything that isn't beach or water
	
func _get_tile_for_value(val: float) -> Vector2i:
	if val < 0.1:
		return SNOW[randi() % SNOW.size()]
	elif val < 0.2:
		return STONE[randi() % STONE.size()]
	elif val < 0.45:
		return GRASS[randi() % GRASS.size()]
	elif val < 0.65:
		return BEACH[randi() % BEACH.size()]
	else:
		return WATER[randi() % WATER.size()]
	#if val < -0.3:
		#return WATER[randi() % WATER.size()]
	#elif val < -0.1:
		#return BEACH[randi() % BEACH.size()]
	#elif val < 0.2:
		#return GRASS[randi() % GRASS.size()]
	#else:
		#return STONE[randi() % STONE.size()]
#func _exit_tree():
	#loading_thread.wait_to_finish()

func _exit_tree():
	if loading_thread and loading_thread.is_started():
		loading_thread.wait_to_finish()
