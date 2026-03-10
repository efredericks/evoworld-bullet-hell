extends CharacterBody2D

@export_category("Stats")
@export var hp: int = 50
@export var maxHP: int = 50

@export_category("Movement")
@export var max_speed: float = 100.0
@export var acceleration: float = 0.2
@export var braking: float = 0.15

@export_category("Bullets")
@export var shoot_rate: float = 0.1

@onready var muzzle = $muzzle
@onready var sprite: Sprite2D = $sprite
@onready var bullet_pool = $PlayerBulletPool
@onready var health_bar: ProgressBar = $HealthBar
@onready var shoot_audio: AudioStreamPlayer = $ShootAudio
@onready var damaged_audio: AudioStreamPlayer = $DamagedAudio
@onready var potion_audio: AudioStreamPlayer = $PotionAudio

var move_input: Vector2
var last_shoot_time: float
var additional_bullet_speed: float = 0.0

func _ready() -> void:
	hp = maxHP
	health_bar.max_value = maxHP
	health_bar.value = hp
	
func _physics_process(delta):
	move_input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if move_input.length() > 0:
		velocity = velocity.lerp(move_input * max_speed, acceleration)
	else:
		velocity = velocity.lerp(Vector2.ZERO, braking)
	move_and_slide()
	 
	sprite.flip_h = move_input.x > 0
	
func _process(delta):
	# sprite flip
	#sprite.flip_h = get_global_mouse_position().x > global_position.x
	if Input.is_action_pressed("mouse_shoot"):
		if Time.get_unix_time_from_system() - last_shoot_time > shoot_rate:
			_shoot()
	_move_wobble()
			
func _shoot():
	last_shoot_time = Time.get_unix_time_from_system()
	var bullet = bullet_pool.spawn()
	
	bullet.global_position = muzzle.global_position
	var mouse_pos = get_global_mouse_position()
	var mouse_dir = muzzle.global_position.direction_to(mouse_pos)
	bullet.move_dir = mouse_dir
	bullet.additional_speed = additional_bullet_speed
	
	shoot_audio.play()
	
# checked via bullet script
func take_damage(dmg: int) -> void:
	hp -= dmg
	if hp <= 0:
		hp = 0
		$"..".set_game_over()
	else:
		_damage_flash()
		damaged_audio.play()
		$"../Camera2D".damage_shake()
		health_bar.value = hp

func heal(amt: int) -> void:
	hp += amt
	if hp > maxHP: hp = maxHP
	health_bar.value = hp
	
	sprite.modulate = Color.GREEN_YELLOW
	await get_tree().create_timer(0.05).timeout
	sprite.modulate = Color.WHITE

func _damage_flash() -> void:
	sprite.modulate = Color.RED
	await get_tree().create_timer(0.05).timeout
	sprite.modulate = Color.WHITE
	
func _move_wobble():
	if move_input.length() == 0:
		sprite.rotation_degrees = 0
		return
	
	var t = Time.get_unix_time_from_system()
	var rot = 2 * sin(20 * t)
	sprite.rotation_degrees = rot

func drink_potion() -> void:
	potion_audio.play()
