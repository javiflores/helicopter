# Agent Build Guide: Project "Helicopter Roguelike"

**Target Audience:** AI Agents (Antigravity or similar) & Developers
**Source of Truth:** `game_skeleton.json`

## 1. Project Overview
This project is a configuration-driven, top-down roguelite shooter where players pilot customizable helicopters. The goal is to build a functional prototype in a game engine (Unity, Godot, or Unreal) where **all gameplay values, entities, and flow rules are derived directly from `game_skeleton.json`**.

## 2. Core Architecture Principle: "Data-Driven Design"
**Do not hardcode gameplay values.**
*   **Bad:** `playerHealth = 100;`
*   **Good:** `playerHealth = GameConfig.player.helicopters[selectedHeli].specs.health;`

The engine should act as a generic simulation layer, while the JSON defines the specific content.

## 3. Implementation Phases

### Phase 1: The "Skeleton" Parser
Before building gameplay, build the infrastructure to read the JSON.
*   **Task:** Create a Singleton/Global manager (`GameManager` or `ConfigLoader`) that deserializes `game_skeleton.json` at startup.
*   **Requirement:** It must parse complex nested structures like `upgrades` and `loot_tables` into usable C#/C++/GDScript structs or classes.

### Phase 2: Player Controller (The "Twin-Stick" Core)
Refer to `player.mechanics.controls` and `player.mechanics.movement_physics`.
*   **Movement:** Implement "hybrid_arcade" physics. Use `acceleration` and `deceleration` values from `movement_physics.tuning_parameters`.
*   **Input:** WASD for movement, Mouse for Aim/Shooting.
*   **Hull:** Dynamically load the selected helicopter stats (`speed`, `health`) from `player.helicopters`.

### Phase 3: The Weapon System
This is the most complex system. It must be modular.
*   **Factory Pattern:** Create a `WeaponFactory` that takes a weapon ID (e.g., `weapon_machine_gun`) and returns a functional weapon instance.
*   **Behaviors:**
    *   `type: "projectile"` -> Instantiates bullet objects.
    *   `type: "beam"` -> Raycast logic.
    *   `type: "melee"` -> Hitbox logic attached to parent.
*   **Upgrades:** Implement a "Modifier System". If the player has `upgrade_rapid_fire`, the weapon logic should apply `stats_modifier` to the base stats *before* firing.

### Phase 4: Enemy AI & Spawning
Refer to `enemies.mobs` and `enemies.bosses`.
*   **State Machine:** Implement a generic Enemy AI with states defined in the `behavior` array (e.g., "Patrol", "Pursue", "Flee").
*   **Stats:** Enemies must act as containers for the JSON stats (`health`, `damage`, `speed`).
*   **Visuals:** Use the `visuals.model` key to instantiate the correct prefab. If assets are missing, use immediate geometry placeholders (Red Cube = Enemy).

### Phase 5: The Game Loop (Roguelite Flow)
Ref: `game.rules.game_loop`.
*   **State: Main Menu:** Player selects Heli/Weapon (reading `player.helicopters` keys).
*   **State: Run Start:** Initialize `current_resources` (scraps/intel) to 0 (or saved amount if implementing meta-progression).
*   **State: Biome:** Load environment based on `world.biomes`. Spawn POIs defined in `available_pois`.
*   **State: Death:** Apply `loot_retention_multiplier: 0.5`. Return to Menu.
*   **State: Success:** Apply `loot_retention_multiplier: 1.0`. Return to Menu.

## 4. Special Handling Instructions

### Asset Mapping ("The Fallback Protocol")
The JSON uses keys like `model_heli_chassis_h11`.
1.  **Search:** Look for a resource with this exact name in the engine's resource folder.
2.  **Fallback:** If not found, spawn a generic placeholder primitive (Capsule for Player, Cube for Enemy) and dye it a distinct color.
3.  **Log:** Print a warning "Missing Asset: [AssetKey]" to help artists identify work.

### Economy & Loot
*   **Loot Tables:** When an enemy dies, check `game.economy.loot_tables.mob_kill`. Retrieve the range (e.g., `[1, 5]`) and roll a random amount of `scraps`.
*   **Unlocks:** In the Main Menu, checks against `unlock_cost`. If `player.storage.scraps >= cost`, allow unlock and deduct currency.

## 5. Development Checklist for the Agent
1.  [ ] **Ingest:** Read `game_skeleton.json` and print "Game Name" to console to verify parsing.
2.  [ ] **Fly:** Spawn a cube that moves using `tuning_parameters`.
3.  [ ] **Shoot:** Spawn projectiles using `weapon_machine_gun` specs.
4.  [ ] **Fight:** Spawn a target dummy with `mob_drone_scout` health.
5.  [ ] **Loop:** Implement the Win/Loss state transitions.

---
*Good luck, Agent. Adhere to the JSON configuration, and the simulation will hold.*
