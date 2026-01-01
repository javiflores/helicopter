extends Control

func _ready():
	hide()
	$Panel/VBoxContainer/RestartButton.pressed.connect(_on_restart_pressed)
	$Panel/VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)

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
	get_tree().reload_current_scene()

func _on_quit_pressed():
	get_tree().quit()
