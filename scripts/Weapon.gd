extends Node3D
class_name Weapon

var weapon_id: String
var specs: Dictionary = {}
var visuals: Dictionary = {}
var upgrades: Dictionary = {}

var current_cooldown: float = 0.0
var can_fire: bool = true

func configure(id: String, weapon_data: Dictionary):
	weapon_id = id
	specs = weapon_data.get("specs", {})
	visuals = weapon_data.get("visuals", {})
	upgrades = weapon_data.get("upgrades", {})

func _process(delta):
	if current_cooldown > 0:
		current_cooldown -= delta
		if current_cooldown <= 0:
			can_fire = true
			current_cooldown = 0

func attempt_fire():
	if can_fire:
		fire()
		start_cooldown()

func apply_modifier(mods: Dictionary):
	for stat in mods:
		var val_str = mods[stat]
		var val = val_str.to_float()
		
		# Get current spec
		var current = float(specs.get(stat, 0.0))
		
		if val_str.begins_with("+"):
			specs[stat] = str(current + val)
		elif val_str.begins_with("-"):
			specs[stat] = str(current - abs(val))
		else:
			specs[stat] = str(val)
			
	print("Weapon Stats Updated: ", specs)
	# Recalculate fire rate timers if needed or just let it happen in start_cooldown

func apply_mechanic(mechanics: Dictionary):
	# Store for specific weapon logic
	for key in mechanics:
		specs[key] = mechanics[key]
	print("Weapon Mechanics Updated: ", specs)

func fire():
	print("Base Weapon Fired")

func start_cooldown():
	var rate_of_fire = float(specs.get("rate of fire", 1.0))
	if rate_of_fire > 0:
		current_cooldown = 1.0 / rate_of_fire
	else:
		current_cooldown = 1.0 # Default safety
	can_fire = false
