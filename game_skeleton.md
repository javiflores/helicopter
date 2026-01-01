# Game Skeleton Blueprint
*Source of Truth derived from game_skeleton.json*

## 1. Game Overview
*   **Title:** Helicopter Helicopter Heli...
*   **Version:** 0.1
*   **Description:** Top down helicopter combat game with roguelike elements, procedurally generated content and a focus on strategy and resource management.

## 2. Core Resources & Economy
*   **Scraps:** Common currency for basic unlocks.
*   **Intel:** Rare data for advanced unlocks.
*   **Loot Tables:**
    *   *Mob Kill:* Scraps (1-5)
    *   *POI Complete:* Intel (1-3)
    *   *Boss Kill:* Scraps (200-300), Intel (2-4), Upgrades (3)

## 3. Game Progression (Run Structure)
*   **Biomes Order:**
    1.  Base: Oil Rig (Hub)
    2.  Biome: City
    3.  Arena: City Boss (Iron Foundry)
    4.  Base: Safe Zone 1 (FOB Echo)
    5.  Biome: Mountains
    6.  Arena: Mountain Boss (Thunderhead Summit)
    7.  Base: Safe Zone 2 (Outpost Mirage)
    8.  Biome: Desert
    9.  Arena: Desert Boss (Glass Cradle)
*   **Loop Mechanics:**
    *   *Roguelite:* Reset weapon upgrades on death. Persist Scraps, Intel, Unlocks.
    *   *Death:* 50% Loot Retention. Return to Hub.
    *   *Success:* 100% Loot Retention. Return to Hub.

## 4. Player Mechanics (The 3C's)
*   **Controls (Twin Stick):**
    *   Move: WASD
    *   Aim: Mouse Cursor
    *   Fire: Left/Right Click
    *   Dash: Spacebar
    *   Ultimate: F
*   **Physics:**
    *   *Movement:* Hybrid Arcade. Acceleration=50, Deceleration=20.
    *   *Combat:* Invulnerability Frames (1.0s on Hit, 0.3s on Dash).
    *   *Collision:* Damage from Walls (5) and Enemies.
*   **Ultimates:**
    *   Orbital Strike (Laser)
    *   Squadron Call-In (Drones)
    *   Nanite Cloud (Heal)
    *   Thunderclap EMP (Stun)
    *   Aegis Field (Shield)
    *   System Overdrive (Buff)

## 5. Content: World
*   **Biomes:**
    *   *City:* Concrete canyons, Hunter-killer drones.
    *   *Mountains:* Pine forests, Storms.
    *   *Desert:* Scorched dunes, Railguns.
*   **POIs:**
    *   Civilian Rescue (Scraps)
    *   Radar Sabotage (Intel)
    *   Convoy Protection (Mix)

## 6. Content: Arsenal
*   **Helicopters:**
    *   H11 (Starter)
    *   H21/H22 (Tier 1 Upgrades)
    *   H31/H32/H33 (Tier 2 Upgrades)
*   **Weapons:**
    *   Machine Gun (Projectile, Single Target)
    *   Rocket Launcher (Projectile, AOE)
    *   Laser (Beam, DOT - *implied*)
    *   Railgun (Hitscan, Pierce - *implied*)

## 7. User Interface
*   **HUD:** HealthBar, Minimap, WeaponInfo, ObjectiveTracker, ResourceCounter.
*   **Menus:** Pause, Settings, Upgrade Selection.
