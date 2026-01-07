extends Control

@onready var heli_container = $MarginContainer/HBoxContainer/VBoxHeli/ScrollContainer/List
@onready var primary_container = $MarginContainer/HBoxContainer/VBoxWeapon/ScrollContainer/List
@onready var ult_container = $MarginContainer/HBoxContainer/VBoxUlt/ScrollContainer/List
@onready var start_button = $MarginContainer/Footer/StartButton

# We will create a secondary container dynamically or assume we can duplicate the VBox
var secondary_container = null
var skill_container = null

var selected_heli = "heli_starter"
var selected_primary = "weapon_machine_gun"
var selected_secondary = "weapon_machine_gun"
var selected_skill = "skill_repair"
var selected_ult = ""

func _ready():
	_setup_secondary_ui()
	_setup_skill_ui()
	
	populate_helis()
	populate_primary()
	populate_secondary()
	populate_skills()
	populate_ults()
	
	# Update Labels
	var vbox_primary = $MarginContainer/HBoxContainer/VBoxWeapon
	if vbox_primary.has_node("Label"):
		vbox_primary.get_node("Label").text = "Primary Slot"
	
	start_button.pressed.connect(_on_start_pressed)

func _setup_secondary_ui():
	var vbox_primary = $MarginContainer/HBoxContainer/VBoxWeapon
	# Duplicate the Primary VBox to create Secondary VBox
	var vbox_secondary = vbox_primary.duplicate()
	vbox_secondary.name = "VBoxSecondary"
	
	# Add it to the HBoxContainer. Index 2 (Heli, Primary, Secondary, Ult)
	$MarginContainer/HBoxContainer.add_child(vbox_secondary)
	$MarginContainer/HBoxContainer.move_child(vbox_secondary, 2)
	
	if vbox_secondary.has_node("Label"):
		vbox_secondary.get_node("Label").text = "Secondary Slot"
		
	secondary_container = vbox_secondary.get_node("ScrollContainer/List")
	# Clear any duped children
	for child in secondary_container.get_children():
		child.queue_free()

func _setup_skill_ui():
	var vbox_primary = $MarginContainer/HBoxContainer/VBoxWeapon
	# Duplicate the Primary VBox to create Skill VBox
	var vbox_skill = vbox_primary.duplicate()
	vbox_skill.name = "VBoxSkill"
	
	# Add it to the HBoxContainer. Index 3 (Heli, Primary, Secondary, Skill, Ult)
	$MarginContainer/HBoxContainer.add_child(vbox_skill)
	$MarginContainer/HBoxContainer.move_child(vbox_skill, 3)
	
	if vbox_skill.has_node("Label"):
		vbox_skill.get_node("Label").text = "Skill Slot"
		
	skill_container = vbox_skill.get_node("ScrollContainer/List")
	# Clear any duped children
	for child in skill_container.get_children():
		child.queue_free()

func populate_helis():
	var helis = GameManager.game_data.get("player", {}).get("helicopters", {})
	_populate_list(heli_container, helis, "heli_starter", "helicopter_id")

func populate_primary():
	var weapons = GameManager.game_data.get("player", {}).get("weapons", {})
	# Pass "primary_weapon_id" as tag
	_populate_list(primary_container, weapons, "weapon_machine_gun", "primary_weapon_id")

func populate_secondary():
	if not secondary_container: return
	var weapons = GameManager.game_data.get("player", {}).get("weapons", {})
	# Pass "secondary_weapon_id" as tag
	_populate_list(secondary_container, weapons, "weapon_machine_gun", "secondary_weapon_id")

func populate_skills():
	if not skill_container: return
	var skills = GameManager.game_data.get("player", {}).get("skills", {})
	# Pass "skill_id" as tag
	_populate_list(skill_container, skills, "skill_repair", "skill_id")

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
		# For now, only 'weapon_machine_gun' is allowed/unlocked in JSON default for weapons
		# 'weapon_rocket' is also unlocked.
		# Let's check 'default_unlocked' property
		var is_unlocked = item.get("default_unlocked", false)
		
		btn.disabled = not is_unlocked
		if not is_unlocked:
			btn.text += " (Locked)"
			
		btn.toggle_mode = false # Using click-to-select for simplicity with highlights
		
		btn.pressed.connect(func(): _on_item_selected(key, type_tag, container))
		
		# Highlight Logic
		var current_val = _get_current_selection(type_tag)
		if key == current_val:
			btn.modulate = Color(1, 1, 0)
		else:
			btn.modulate = Color(1, 1, 1)
			
		container.add_child(btn)

func _get_current_selection(type_tag):
	match type_tag:
		"helicopter_id": return selected_heli
		"primary_weapon_id": return selected_primary
		"secondary_weapon_id": return selected_secondary
		"skill_id": return selected_skill
		"ultimate_id": return selected_ult
	return ""

func _on_item_selected(key, type, container):
	match type:
		"helicopter_id": selected_heli = key
		"primary_weapon_id": selected_primary = key
		"secondary_weapon_id": selected_secondary = key
		"skill_id": selected_skill = key
		"ultimate_id": selected_ult = key
	
	print("Selected ", type, ": ", key)
	_refresh_highlights(container, key)

func _refresh_highlights(container, selected_key):
	for btn in container.get_children():
		# This is a bit hacky, relying on button text containing name. 
		# Ideally we'd store metadata. But for now, just checking if it's the one we clicked.
		# Actually, we can just rebuild the list or iterate.
		# Let's simple iterate and reset colors.
		pass
	
	# Re-populate is safest to get correct colors without complex button management
	if container == heli_container: populate_helis()
	elif container == primary_container: populate_primary()
	elif container == secondary_container: populate_secondary()
	elif container == skill_container: populate_skills()
	elif container == ult_container: populate_ults()

func _on_start_pressed():
	GameManager.current_loadout["helicopter_id"] = selected_heli
	GameManager.current_loadout["primary_weapon_id"] = selected_primary
	GameManager.current_loadout["secondary_weapon_id"] = selected_secondary
	GameManager.current_loadout["skill_id"] = selected_skill
	GameManager.current_loadout["ultimate_id"] = selected_ult
	
	get_tree().change_scene_to_file("res://scenes/GameWorld.tscn")
