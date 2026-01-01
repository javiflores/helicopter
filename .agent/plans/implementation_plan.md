# Implementation Plan
*Tracking progress against `game_skeleton.md` Blueprint*

## 1. Core Systems (Blueprint Sec 1 & 3)
- [x] **Project Setup** [Version 0.1]
    - [x] Godot Project Init & Config.
    - [x] Game Manager & Global State.
- [x] **Game Loop** [Sec 3]
    - [x] Core Loop: Start Run -> Play -> Die/Win -> Reset.
    - [x] Dungeon Generation (Linear Room Chain).
    - [ ] Biome Mechanics (City specific tilesets/enemies - *Basic Implementation Done*).

## 2. Player Mechanics (Blueprint Sec 4)
- [x] **Controls**
    - [x] Twin Stick Scheme (WASD + Mouse).
    - [x] Camera-Relative Input (Diagonal offsets supported).
    - [x] Dash (Spacebar/Gamepad) with I-Frames [0.3s].
    - [x] **Tactical Aiming:**
        - [x] Smooth Slerp Rotation (No snapping).
        - [x] Independent Weapon Cone [30 degrees].
        - [x] 3D Aim Reticle (Red Cross inside Circle).
- [x] **Physics**
    - [x] Hybrid Arcade Movement (Accel/Decel/Rotation tuned).
    - [x] Floating Physics (No floor bounce).
    - [x] Combat Physics (Collision Layers + No Friendly Fire).

## 3. Economy & Resources (Blueprint Sec 2)
- [x] **Resources**
    - [x] Scraps Collection & UI.
    - [x] Intel Collection & UI.
- [x] **Loot**
    - [x] Mob Drops (Scraps).
    - [x] Pickup Logic (Magnetic/Collision).

## 4. Content: Arsenal (Blueprint Sec 6)
- [x] **Helicopters**
    - [x] H11 Starter (Stats implemented).
    - [x] Visual Replacement (Integrated Military_Helicopter02 FBX).
    - [x] Rotor Animations (Custom pivots for center-axis rotation).
- [x] **Weapons**
    - [x] Machine Gun (Projectile, single target).
    - [x] Rocket Launcher (AOE, Slow Fire).
    - [ ] Laser / Railgun.
- [x] **Ultimates**
    - [ ] Orbital Strike / Drones / etc. (Not started).

## 5. Content: World (Blueprint Sec 5)
- [x] **Biomes**
    - [x] City (Greybox Prototype).
- [x] **Entities**
    - [x] Mob: Scout Drone (Chaser + Shooter).
    - [x] Mob: Turret (Stationary Defense).
    - [x] POIs (Rescue & Destroy Objectives).
    - [x] Boss: The Constructor (City Boss, 2 Phases).
    - [x] Grounding: All elements flush with ground (Y=0).
    - [x] Flight Fix: Removed environment collisions (Hills/Rocks/Trees) for smooth movement.

## 6. UI (Blueprint Sec 7)
- [x] **HUD**
    - [x] Health Bar.
    - [x] Resource Counter.
    - [x] Dash Cooldown.
    - [x] Objective Tracker (Count & Completion).
    - [ ] Minimap.
- [x] **Menus**
    - [x] Game Over Screen.
    - [ ] Main Menu / Pause / Settings.

## Next Steps (Gap Analysis)
1.  **Arsenal:** Implement Ultimate Ability (Orbital Strike or Drones).
2.  **UI:** Implement Minimap for spatial awareness.
3.  **Progression:** Implement Inter-level Upgrade shop (spending Scraps/Intel).
4.  **World:** Begin work on the Mountain Biome (Terrain & Storm mechanics).
