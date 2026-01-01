extends Node

func create_weapon(weapon_id: String):
	if not GameManager.game_data:
		return null
		
	var weapons_db = GameManager.game_data.get("player", {}).get("weapons", {})
	if not weapon_id in weapons_db:
		print("Weapon not found: ", weapon_id)
		return null
		
	var data = weapons_db[weapon_id]
	var specs = data.get("specs", {})
	var type = specs.get("type", "projectile")
	
	var weapon_instance = null
	
	match type:
		"projectile":
			weapon_instance = load("res://scripts/ProjectileWeapon.gd").new()
		_:
			# Fallback for others
			weapon_instance = load("res://scripts/Weapon.gd").new()
			
	if weapon_instance:
		weapon_instance.name = weapon_id
		weapon_instance.configure(weapon_id, data)
		
	return weapon_instance
