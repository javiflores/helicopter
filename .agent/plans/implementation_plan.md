# Implementation Plan
*Tracking progress against `game_skeleton.md` Blueprint*

## Phase 1: Core Loop & Hub (Blueprint Sec 1 & 3)
- [x] **Project Setup**
    - [x] Godot Project Init & Config.
    - [x] Game Manager & Global State.
- [ ] **Run Structure & Loop**
    - [x] Core Loop: Start Run -> Play -> Die/Win -> Reset.
    - [x] Dungeon Generation (Linear Room Chain).
    - [ ] **Retention Logic:** 50% Loot retention on Death, 100% on Success.
    - [ ] **Hub: Oil Rig** (Start/Return point).
    - [ ] **Safe Zones:** FOB Echo (between City/Mountain), Outpost Mirage (between Mountain/Desert).

## Phase 2: Player & Combat Refinement (Blueprint Sec 4)
- [x] **Controls**
    - [x] Twin Stick Scheme (WASD + Mouse).
    - [x] Dash (Spacebar) with I-Frames [0.3s].
    - [ ] **Ultimate Key:** Bind to 'F'.
- [x] **Physics & Health**
    - [x] Hybrid Arcade Movement (Accel=50, Decel=20 sync).
    - [ ] **Damage Tweak:** Wall collisions deal 5 damage.
    - [ ] **I-Frames:** 1.0s invulnerability after taking a hit.
- [ ] **Ultimates (Pending Implementations)**
    - [ ] Aegis Field (Shield) / System Overdrive (Buff).
    - [ ] Tactical: Orbital Strike / Squadron Call-In.
    - [ ] Utility: Nanite Cloud (Heal) / Thunderclap EMP (Stun).

## Phase 3: Economy & Arsenal (Blueprint Sec 2 & 6)
- [x] **Resources & Loot**
    - [x] Scraps & Intel collection.
    - [ ] **Balance:** Sync loot amounts (Mobs 1-5 scraps, POI 1-3 intel, Boss 300 scraps/4 intel).
- [ ] **Helicopters (Tier Progression)**
    - [x] H11 Starter (Military_Helicopter02 mesh).
    - [ ] H21/H22 Upgrades (Tier 1).
    - [ ] H31/H32/H33 Upgrades (Tier 2).
- [ ] **Weapons**
    - [x] Machine Gun (Bullet shape + Tracer).
    - [x] Rocket Launcher (AOE).
    - [ ] Laser (Beam/DOT) / Railgun (Hitscan/Pierce).

## Phase 4: World & Content (Blueprint Sec 5)
- [x] **City Biome (Completed)**
    - [x] Concrete canyons, Hunter-killer drones, Boss: The Constructor.
- [ ] **Mountain Biome**
    - [ ] Pine forest assets, Storm mechanics, Boss: Thunderhead Summit.
- [ ] **Desert Biome**
    - [ ] Sandstorm mechanics, Railgun enemies, Boss: Glass Cradle.
- [ ] **POIs**
    - [x] Rescue (Greenhouse) & Radar Sabotage.
    - [ ] **New:** Convoy Protection.

## Phase 5: UI & UX (Blueprint Sec 7)
- [x] **HUD**
    - [x] Health, Scraps, Intel, Dash, Objectives.
    - [ ] Minimap.
    - [ ] Weapon Info (Current weapon / Ammo status).
- [ ] **Menus**
    - [x] Game Over Screen.
    - [ ] Main Menu / Pause Menu / Settings.
    - [ ] **Upgrade Shop:** Spending resources in Hub/Safe Zones.

## Next Steps (Immediate Priorities)
1. **Hub Transition:** Create a basic Hub scene and implement the logic to return there with loot retention.
2. **Combat Polish:** Implement I-Frames on hit and Wall collision damage.
3. **Ultimates:** Implement the first Ultimate ability (Aegis Field or Overdrive).
4. **Mini-map:** Add spatial awareness to the HUD.
