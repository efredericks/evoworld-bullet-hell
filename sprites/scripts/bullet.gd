extends Area2D

@export var speed: float = 200.0
@export var owner_group: String
@onready var destroy_timer = $DestroyTimer

var additional_speed: float = 0.0 # potion impact
var move_dir: Vector2

func _process(delta):
	translate(move_dir * (speed + additional_speed) * delta)
	rotation = move_dir.angle()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(owner_group):
		return
		
	if body.has_method("take_damage"):
		body.take_damage(1)

	visible = false
	set_process(false)
	set_physics_process(false)
	global_position = Vector2(0, -99999999)
	
func _on_destroy_timer_timeout() -> void:
	visible = false
	set_process(false)
	set_physics_process(false)
	global_position = Vector2(0, -99999999)

func _on_visibility_changed() -> void:
	if visible and destroy_timer:
		destroy_timer.start()
		additional_speed = 0.0
