extends Control

@onready var heli_container = $MarginContainer/HBoxContainer/VBoxHeli/ScrollContainer/List
@onready var weapon_container = $MarginContainer/HBoxContainer/VBoxWeapon/ScrollContainer/List
@onready var ult_container = $MarginContainer/HBoxContainer/VBoxUlt/ScrollContainer/List
@onready var start_button = $MarginContainer/Footer/StartButton

var selected_heli = "heli_starter"
var selected_weapon = "weapon_machine_gun"
var selected_ult = ""

func _ready():
	populate_helis()
	populate_weapons()
	populate_ults()
	
	start_button.pressed.connect(_on_start_pressed)

func populate_helis():
	var helis = GameManager.game_data.get("player", {}).get("helicopters", {})
	_populate_list(heli_container, helis, "heli_starter", "helicopter_id")

func populate_weapons():
	var weapons = GameManager.game_data.get("player", {}).get("weapons", {})
	_populate_list(weapon_container, weapons, "weapon_machine_gun", "weapon_id")

func populate_ults():
	var ults = GameManager.game_data.get("player", {}).get("ultimates", {})
	_populate_list(ult_container, ults, "", "ultimate_id")

func _populate_list(container, data_dict, allowed_key, type_tag):
	for child in container.get_children():
		child.queue_free()
		
	for key in data_dict:
		var item = data_dict[key]
		var btn = Button.new()
		btn.text = item.get("name", key)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		# Constraint Logic:
		# Only allow specific keys for now
		var is_allowed = (key == allowed_key)
		
		# If it's ultimates, we might allow none or just show them
		# User said "add them as placeholders"
		
		btn.disabled = not is_allowed
		if not is_allowed:
			btn.text += " (Locked)"
			
		btn.toggle_mode = true
		btn.button_group = load("res://resources/ui_group_" + type_tag + ".tres") # Creating groups dynamically is tricky, let's manage manually
		# Simpler manual management for this quick implementation
		btn.toggle_mode = false
		
		btn.pressed.connect(func(): _on_item_selected(key, type_tag))
		
		# Highlight if currently selected (default)
		if key == allowed_key:
			btn.modulate = Color(1, 1, 0) # Yellow highlight text
			
		container.add_child(btn)

func _on_item_selected(key, type):
	# Since we disabled buttons for locked items, we only get here for valid ones
	match type:
		"helicopter_id": selected_heli = key
		"weapon_id": selected_weapon = key
		"ultimate_id": selected_ult = key
	
	print("Selected ", type, ": ", key)

func _on_start_pressed():
	GameManager.current_loadout["helicopter_id"] = selected_heli
	GameManager.current_loadout["weapon_id"] = selected_weapon
	GameManager.current_loadout["ultimate_id"] = selected_ult
	
	get_tree().change_scene_to_file("res://scenes/GameWorld.tscn")
