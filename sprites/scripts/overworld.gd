extends TileMapLayer

@export var num_rows: int = 500
@export var num_cols: int = 500
const tile_size: int = 32
var open_cells: Array[Vector2]

@onready var overworld: TileMapLayer = $"."
@onready var player = $"../player"

# boundaries
@onready var bottom_boundary: CollisionShape2D = $"../OuterBoundary/BottomBoundary"
@onready var top_boundary: CollisionShape2D = $"../OuterBoundary/TopBoundary"
@onready var left_boundary: CollisionShape2D = $"../OuterBoundary/LeftBoundary"
@onready var right_boundary: CollisionShape2D = $"../OuterBoundary/RightBoundary"


#@onready var p = $CharacterBody2D
#var EMPTY_FLOOR = Vector2i()
#var DIRT_FLOOR = Vector2i()
#var GRASS_FLOOR = Vector2i()
#var move_input: Vector2

#var WALKABLE: Array[Vector2i] = [EMPTY_FLOOR, DIRT_FLOOR, GRASS_FLOOR]
var WALKABLE: Dictionary = {
	"BRICK_FLOOR": [Vector2i(17,14), Vector2i(18,14), Vector2i(19,14), Vector2i(20,14)],
}
var BLOCKING: Dictionary = { 
	"BRICK_WALL": [Vector2i(22,13), Vector2i(23,13), Vector2i(24,13), Vector2i(25,13), Vector2i(26,13), Vector2i(27,13), Vector2i(28,13)],
}
func _ready() -> void:
	randomize()
	
	#overworld.clear()
	for r in range(num_rows):
		for c in range(num_cols):
			var pos = Vector2i(r, c)
			var atlas_pos = Vector2i(0, 0)
			
			if c == 0 or c == num_cols-1 or r == 0 or r == num_rows-1:
				atlas_pos = BLOCKING['BRICK_WALL'][randi_range(0, len(BLOCKING['BRICK_WALL'])-1)]
			else:
				atlas_pos = WALKABLE['BRICK_FLOOR'][randi_range(0, len(WALKABLE['BRICK_FLOOR'])-1)]
				open_cells.append(Vector2i(c, r))
			#atlas_pos = Vector2i(2,2)
			overworld.set_cell(pos, 0, atlas_pos)
			
	var oc = open_cells[randi_range(0, len(open_cells)-1)]
	player.global_position = Vector2i(tile_size * oc.x, tile_size * oc.y)
	print(player.global_position)
	# set bounds
	left_boundary.global_position.x = 0
	right_boundary.global_position.x = num_cols * tile_size
	top_boundary.global_position.y = 0
	bottom_boundary.global_position.y = num_rows * tile_size
	
#func _physics_process(delta) -> void:
	#move_input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	#
	#if move_input.length() > 0:
		#p.velocity = p.velocity.lerp(move_input * 200.0, .2)
	#else:
		#p.velocity = p.velocity.lerp(Vector2.ZERO, 0.9)
	#p.move_and_slide()
