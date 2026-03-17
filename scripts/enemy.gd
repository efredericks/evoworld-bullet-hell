extends CharacterBody2D

@export var hp: int = 5
@export var maxHP: int = 5

@export var max_speed: float
@export var acceleration: float
@export var drag: float
@export var stop_range: float

@export var shoot_rate: float
@export var shoot_range: float
@export var flip_sprite: bool = false

var last_shoot_time: float

@onready var player = get_tree().get_first_node_in_group("player")
@onready var avoidance_ray: RayCast2D = $AvoidanceRay
@onready var sprite: Sprite2D = $sprite
@onready var bullet_pool = $EnemyBulletPool
@onready var muzzle = $muzzle
@onready var health_bar: ProgressBar = $HealthBar
@onready var damaged_audio: AudioStreamPlayer = $DamagedAudio


var player_dist: float
var player_dir: Vector2

func _ready() -> void:
	health_bar.max_value = maxHP
	health_bar.value = hp
	
func _process(delta: float) -> void:
	if not player: return
	
	player_dist = global_position.distance_to(player.global_position)
	player_dir = global_position.direction_to(player.global_position)
	
	# face the player
	if flip_sprite:
		sprite.flip_h = player_dir.x < 0
	else:
		sprite.flip_h = player_dir.x > 0
	
	# shoot towards player
	#if player_dist < shoot_range:
		#if Time.get_unix_time_from_system() - last_shoot_time > shoot_rate:
			#_shoot()
			
	_move_wobble()
	
func _physics_process(delta: float) -> void:
	if not player: return
	
	var move_dir = player_dir
	#var forward_speed = player_dir.dot(velocity) # speed in moving direction
	var local_avoidance = _local_avoidance()
	
	if local_avoidance.length() > 0:
		move_dir = local_avoidance
	
	if velocity.length() < max_speed and player_dist > stop_range:
		velocity += move_dir * acceleration
	else:
		velocity *= drag
		
	move_and_slide()
	
# avoid obstacles when following
func _local_avoidance() -> Vector2:
	avoidance_ray.target_position = to_local(player.global_position).normalized()
	avoidance_ray.target_position *= 80 # only avoid within 80 pixels
	
	if not avoidance_ray.is_colliding():
		return Vector2.ZERO
	
	var obstacle = avoidance_ray.get_collider()
	if obstacle == player:
		return Vector2.ZERO
		
	# hitting an obstacle, so move around
	var obstacle_point = avoidance_ray.get_collision_point()
	var obstacle_dir = global_position.direction_to(obstacle_point)
	return Vector2(-obstacle_dir.y, obstacle_dir.x) # return adjacent 
	
func _shoot() -> void:
	last_shoot_time = Time.get_unix_time_from_system()
	var bullet = bullet_pool.spawn()
	bullet.global_position = muzzle.global_position
	bullet.move_dir = muzzle.global_position.direction_to(player.global_position)
	
func take_damage(dmg: int) -> void:
	hp -= dmg
	if hp <= 0:
		hp = 0
		visible = false
	else:
		_damage_flash()
		health_bar.value = hp
	damaged_audio.play()

func _damage_flash() -> void:
	sprite.modulate = Color.BLACK
	await get_tree().create_timer(0.05).timeout
	sprite.modulate = Color.WHITE

func _on_visibility_changed() -> void:
	if visible:
		set_process(true)
		set_physics_process(true)
		hp = maxHP
		if health_bar:
			health_bar.value = hp
		#global_position = Vector2(randi_range(-100, 100), randi_range(-100, 100))
	else:
		set_process(false)
		set_physics_process(false)
		global_position = Vector2(0, 99999999)
		
func _move_wobble():
	if get_real_velocity().length() == 0:
		sprite.rotation_degrees = 0
		return
	
	var t = Time.get_unix_time_from_system()
	var rot = 2 * sin(20 * t)
	sprite.rotation_degrees = rot
