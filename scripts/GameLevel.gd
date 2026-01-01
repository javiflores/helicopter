extends Node3D

@onready var game_over_screen = $CanvasLayer/GameOverScreen
@onready var player = $Player
@onready var dungeon_generator = $DungeonGenerator

func _ready():
	if player:
		player.player_died.connect(_on_player_died)
	
	# Reset state in singleton
	GameManager.reset_objectives()
	
	# Start with City Biome
	dungeon_generator.generate_dungeon("biome_city")
	
	if not GameManager.all_objectives_completed.is_connected(_on_all_objectives_completed):
		GameManager.all_objectives_completed.connect(_on_all_objectives_completed)

func _on_all_objectives_completed():
	print("LEVEL: Spawning Boss!")
	spawn_boss()

func spawn_boss():
	var boss_scene = load("res://scenes/BossConstructor.tscn")
	if boss_scene:
		var boss = boss_scene.instantiate()
		add_child(boss)
		# Spawn at the end of the dungeon
		boss.global_position = Vector3(0, 0, -200) # Slightly past the last room
		boss.boss_died.connect(_on_boss_died)

func _on_boss_died():
	print("LEVEL: Boss Defeated! Victory!")
	game_over_screen.setup(true) # Pass true for victory state

func _on_player_died():
	game_over_screen.setup()
