extends Area2D

enum PotionType {
	HEALTH, SHOOT_SPEED, MOVE_SPEED	
}
@export var type: PotionType
@export var value: float

func _process(delta) -> void:
	var t = Time.get_unix_time_from_system()
	var s = 1.0 + (sin(t  * 10) * 0.1)
	scale.x = s
	scale.y = s
	
func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
		
	if type == PotionType.HEALTH:
		body.heal(value)
	elif type == PotionType.SHOOT_SPEED:
		body.shoot_rate *= value
		body.additional_bullet_speed += 30.0
	elif type == PotionType.MOVE_SPEED: 
		body.max_speed *= value
	else:
		print("Invalid potion")
	
	body.drink_potion()
	queue_free()
