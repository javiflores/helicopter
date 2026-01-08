extends Node

func create_weapon(weapon_id: String):
	if not GameManager.game_data:
		return null
		
	var weapons_db = GameManager.game_data.get("player", {}).get("weapons", {})
	if not weapon_id in weapons_db:
		print("Weapon not found: ", weapon_id)
		return null
		
	var data = weapons_db[weapon_id]
	# New Schema: Type is inside primary_attack -> specs -> type
	# Or purely based on ID map if we want overrides. 
	# Let's fallback to primary attack type.
	var primary = data.get("primary_attack", {})
	var specs = primary.get("specs", {})
	var type = specs.get("type", "projectile") 
	
	# Override for known complex types if needed, or rely on "type" string
	if weapon_id == "weapon_grinder": type = "melee"
	if weapon_id == "weapon_laser": type = "beam"
	if weapon_id == "weapon_shockwave": type = "wave"
	
	var weapon_instance = null
	
	match weapon_id:
		"weapon_machine_gun":
			weapon_instance = load("res://scripts/WeaponMachineGun.gd").new()
		"weapon_rocket":
			weapon_instance = load("res://scripts/WeaponRocket.gd").new()
		"weapon_shotgun":
			weapon_instance = load("res://scripts/WeaponShotgun.gd").new()
		_:
			# Fallbacks
			match type:
				"projectile":
					# Temporary fallback to generic script if exists, or Weapon.gd 
					# Since we are deleting ProjectileWeapon, fallback to base Weapon
					weapon_instance = load("res://scripts/Weapon.gd").new()
				_:
					weapon_instance = load("res://scripts/Weapon.gd").new()
			
	if weapon_instance:
		weapon_instance.name = weapon_id
		weapon_instance.configure(weapon_id, data)
		
	return weapon_instance
