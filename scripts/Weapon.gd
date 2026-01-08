extends Node3D
class_name Weapon

var weapon_id: String
# New Structure: Two attack definitions
var primary_attack: Dictionary = {}
var secondary_attack: Dictionary = {}

var visuals: Dictionary = {}

# Cooldowns
var primary_cooldown: float = 0.0
var primary_cooldown_max: float = 0.0
var secondary_cooldown: float = 0.0
var secondary_cooldown_max: float = 0.0
var can_fire_primary: bool = true
var can_fire_secondary: bool = true

func configure(id: String, weapon_data: Dictionary):
	weapon_id = id
	visuals = weapon_data.get("visuals", {})
	
	# Parse attacks
	primary_attack = weapon_data.get("primary_attack", {})
	secondary_attack = weapon_data.get("secondary_attack", {})

	print("Weapon Configured: ", id)
	print("Primary: ", primary_attack.get("name", "None"))
	print("Secondary: ", secondary_attack.get("name", "None"))

func _process(delta):
	# Handle Primary Cooldown
	if primary_cooldown > 0:
		primary_cooldown -= delta
		if primary_cooldown <= 0:
			can_fire_primary = true
			primary_cooldown = 0
			
	# Handle Secondary Cooldown
	if secondary_cooldown > 0:
		secondary_cooldown -= delta
		if secondary_cooldown <= 0:
			can_fire_secondary = true
			secondary_cooldown = 0

func attempt_fire(is_primary: bool):
	if is_primary:
		if can_fire_primary:
			fire_primary()
			start_cooldown(true)
	else:
		if can_fire_secondary:
			fire_secondary()
			start_cooldown(false)

func fire_primary():
	print("Base Weapon Primary Fire")

func fire_secondary():
	print("Base Weapon Secondary Fire")

func start_cooldown(is_primary: bool):
	var specs = primary_attack.get("specs", {}) if is_primary else secondary_attack.get("specs", {})
	
	# Check for explicit cooldown first, then rate of fire
	var cooldown_val = float(specs.get("cooldown", 0.0))
	if cooldown_val > 0:
		if is_primary: 
			primary_cooldown = cooldown_val
			primary_cooldown_max = cooldown_val
		else: 
			secondary_cooldown = cooldown_val
			secondary_cooldown_max = cooldown_val
	else:
		var rate_of_fire = float(specs.get("rate of fire", 1.0))
		if rate_of_fire > 0:
			var cd = 1.0 / rate_of_fire
			if is_primary: 
				primary_cooldown = cd
				primary_cooldown_max = cd
			else: 
				secondary_cooldown = cd
				secondary_cooldown_max = cd
		else:
			# Default fallback
			if is_primary: 
				primary_cooldown = 1.0
				primary_cooldown_max = 1.0
			else: 
				secondary_cooldown = 1.0
				secondary_cooldown_max = 1.0
			
	if is_primary: can_fire_primary = false
	else: can_fire_secondary = false
