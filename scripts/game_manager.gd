extends Node2D

var elapsed_time: float

@onready var elapsed_time_label: Label = $CanvasLayer/ElapsedTimeLabel
@onready var end_screen = $CanvasLayer/EndScreen
@onready var end_label = $CanvasLayer/EndScreen/EndLabel
@onready var cursor = $MouseCursor
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
	cursor.visible = true
	cursor.global_position = get_global_mouse_position()
	
func _process(delta) -> void:
	elapsed_time += delta
	elapsed_time_label.text = str("%.1f" % elapsed_time)
	
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

func set_game_over() -> void:
	Engine.time_scale = 0.0
	end_screen.visible = true
	end_label.text = "You survived for %.1f seconds" % elapsed_time
	
func _on_retry_button_pressed() -> void:
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()


func _on_quit_button_pressed() -> void:
	get_tree().quit()
