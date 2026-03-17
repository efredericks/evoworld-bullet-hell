extends Camera2D

# creature poops and a plant grows?

@onready var target = $"../player"
@export var follow_rate: float = 2.0

var shake_intensity: float = 0.0
var snapped: bool = false

func damage_shake() -> void:
	shake_intensity = 8.0
	
func _process(delta):
	if not snapped: # lock on to first frame
		global_position = target.global_position
		snapped = true
	else:
		global_position = global_position.lerp(target.global_position, follow_rate * delta)
	
	#print("target pos: ", target.global_position)
	#print("camera pos: ", global_position)
	#global_position = target.global_position  # hard snap, no lerp
	
	if shake_intensity > 0:
		shake_intensity = lerpf(shake_intensity, 0.0, delta * 10.0)
		offset = _get_random_offset()
		
func _get_random_offset() -> Vector2:
	var x = randf_range(-shake_intensity, shake_intensity)
	var y = randf_range(-shake_intensity, shake_intensity)
	
	return Vector2(x, y)
