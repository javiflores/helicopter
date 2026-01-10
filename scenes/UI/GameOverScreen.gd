extends Control

func _ready():
	hide()
	$Panel/VBoxContainer/RestartButton.pressed.connect(_on_restart_pressed)
	$Panel/VBoxContainer/RestartButton.text = "RETURN TO BASE"
	$Panel/VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)
	$Panel/VBoxContainer/QuitButton.text = "QUIT GAME"

func setup(is_victory: bool = false):
	show()
	if is_victory:
		$Panel/VBoxContainer/Label.text = "MISSION ACCOMPLISHED"
		$Panel/VBoxContainer/Label.add_theme_color_override("font_color", Color.GREEN)
	else:
		$Panel/VBoxContainer/Label.text = "MISSION FAILED"
		$Panel/VBoxContainer/Label.add_theme_color_override("font_color", Color.RED)
		
	# Pause the game?
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_restart_pressed():
	get_tree().paused = false
	GameManager.reset_objectives()
	# Return to Base (Start Screen)
	get_tree().change_scene_to_file("res://scenes/UI/RunStartScreen.tscn")

func _on_quit_pressed():
	get_tree().quit()
