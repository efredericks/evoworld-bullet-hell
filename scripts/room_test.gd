extends Node2D

@onready var player = $player
@onready var enemy = $enemy
@onready var pspawn = $PlayerSpawn
@onready var espawn = $EnemySpawn

func _ready() -> void:
	player.global_position = pspawn.global_position
	enemy.global_position = espawn.global_position
