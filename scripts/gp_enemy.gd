extends CharacterBody2D

@export_category("Base stats")
@export var hp: int = 5
@export var maxHP: int = 5

@export var max_speed: float
@export var acceleration: float
@export var drag: float
@export var stop_range: float

@export var shoot_rate: float
@export var shoot_range: float
@export var flip_sprite: bool = false

@export var energy: int = 100
@export var maxEnergy: int = 100

@export_category("GP stats")
@export var GP_weights: Array[float]


var last_shoot_time: float

@onready var player = get_tree().get_first_node_in_group("player")
@onready var avoidance_ray: RayCast2D = $AvoidanceRay
@onready var sprite: Sprite2D = $sprite
@onready var bullet_pool = $EnemyBulletPool
@onready var muzzle = $muzzle
@onready var health_bar: ProgressBar = $HealthBar
@onready var energy_bar: ProgressBar = $EnergyBar
@onready var damaged_audio: AudioStreamPlayer = $DamagedAudio
@onready var GP_Label = $GPLabel

# sprites
@onready var sprite_a = $sprite
@onready var sprite_b = $SpriteB
@onready var sprite_c = $SpriteC
@onready var sprite_d = $SpriteD
@onready var sprite_list: Array[Sprite2D] = [sprite_a, sprite_b, sprite_c, sprite_d]
var active_sprite: Sprite2D

# dependencies
@onready var creature_leavings: PackedScene = preload("res://scenes/creature_leavings.tscn")
@onready var leavings_group: Node = get_node("../Leavings") # add leavings to this node group for ordering

# targeting
var target_dist: float
var target_dir: Vector2
var tracking_food: bool = false
var target: CharacterBody2D = null

var GP_stack: Array[String] = []
var GP_primitives: Array[String] = ["/", "\\", "-", "+", "*", "`", "~"]
@export var GP_max_random: int = 5


# components equipped by gene expression
## + joins
# eat: given
# swim:  			/+\
# attack nearby: 	*+*
# reproduce:	 	~
# place block:		\+\



func _setup_random():
	for i in range(10):#randi_range(0, GP_max_random)):
		GP_stack.append(GP_primitives[randi_range(0, len(GP_primitives)-1)])
	GP_Label.text = " ".join(PackedStringArray(GP_stack))
	
	# select sprite (random for now, assigned based on job)
	active_sprite = sprite_list[randi_range(0, len(sprite_list)-1)]
	active_sprite.visible = true
	
func _ready() -> void:
	health_bar.max_value = maxHP
	health_bar.value = hp
	
	energy_bar.max_value = maxEnergy
	energy_bar.value = energy
	
	scale = Vector2(4., 4.)
	
	target = player
	
	_setup_random()
	if "/" in GP_stack:
		set_collision_mask_value(3, false) # flying!
	else:
		set_collision_mask_value(3, true) # not flying!
	
# process components in randomized order
# drop 
func _process(delta: float) -> void:
	if not player: return
	
	if not tracking_food:
		target_dist = global_position.distance_to(player.global_position)
		target_dir = global_position.direction_to(player.global_position)
		target = player
	
	# face the player
	if flip_sprite:
		sprite.flip_h = target_dir.x < 0
	else:
		sprite.flip_h = target_dir.x > 0
	
	# shoot towards player
	#if player_dist < shoot_range:
		#if Time.get_unix_time_from_system() - last_shoot_time > shoot_rate:
			#_shoot(player)
	
	_move_wobble()

	
func _physics_process(delta: float) -> void:
	if not player: return
	
	var move_dir = target_dir
	#var forward_speed = player_dir.dot(velocity) # speed in moving direction
	var local_avoidance = _local_avoidance()
	
	if local_avoidance.length() > 0:
		move_dir = local_avoidance
	
	if velocity.length() < max_speed and target_dist > stop_range:
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
	
func _shoot(entity) -> void:
	last_shoot_time = Time.get_unix_time_from_system()
	var bullet = bullet_pool.spawn()
	bullet.global_position = muzzle.global_position
	bullet.override_target = entity
	bullet.move_dir = muzzle.global_position.direction_to(entity.global_position)#player.global_position)
	
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

func get_energy() -> void:
	energy += 50
	if energy > maxEnergy:
		energy = maxEnergy
	energy_bar.value = energy

func _on_sensing_radius_body_entered(body: Node2D) -> void:
	if body.is_in_group("CreatureLeavings"):
		pass
	#_shoot(body)

# eat some energy
func _on_energy_timer_timeout() -> void:
	if energy >= 0:
		energy -= 1
		
		# drop some plant food
		if energy % 5 == 0:
			var leaving = creature_leavings.instantiate()
			leaving.global_position = global_position
			leaving.z_index = 2
			#leavings_group.add_child.call_deferred(leaving)
			leavings_group.add_child.call_deferred(leaving)
		
		
	energy_bar.value = energy
	if energy <= 0: 
		take_damage(1)
		print("damaged goods")
			
