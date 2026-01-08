# Project Status & Implementation Checklist

> [!NOTE]
> This document tracks the current state of the project against [game_skeleton.json](file:///c:/Users/egazi/OneDrive/Belgeler/GitHub/helicopter/game_skeleton.json) and defines the implementation priority.

## 1. Implementation Priority
We will follow this order to ensure a stable gameplay loop before adding content variety.

1.  **Core Gameplay Rework (Current Focus)**
    *   Input Remapping (Primary/Secondary/Skill/Block)
    *   Weapon System Rework (Attack Slots vs Upgrades)
    *   Player Mechanics (Dodge, Block, Skills)
2.  **Weapon Content**
    *   Implement Laser, Grinder using new system
3.  **Enemy Variety**
    *   Sniper Drone, Stun Drone
4.  **Biome Distinction**
    *   Visual differentiation for City, Mountains, Desert
5.  **Bosses & Elites**
    *   Storm Bird, Mirage Core, Elite Variants

## 2. Feature Checklist

### Core Systems
| Feature | Status | Notes |
| :--- | :---: | :--- |
| **Input System** | 🟢 Implemented | `GameManager` remapped. New slots: Primary, Secondary, Skill, Block/Parry. |
| **Player Controller** | 🟢 Implemented | Movement, Dodge, Directional Block/Parry, and Skill Slots active. |
| **Skills** | 🟢 Implemented | **Static Discharge** (Stun Ring) implemented and integrated. |
| **Dungeon Generation** | 🟢 Implemented | [DungeonGenerator.gd](file:///c:/Users/egazi/OneDrive/Belgeler/GitHub/helicopter/scripts/DungeonGenerator.gd) handles room spawning. |
| **Biome Logic** | 🔴 Pending | Generator is generic; needs specific logic for localized enemies/visuals. |

### Weapons
| Weapon | Status | Notes |
| :--- | :---: | :--- |
| **System Architecture** | 🟢 Implemented | `WeaponFactory` supports Primary/Secondary/Skill slots. |
| **Machine Gun** | 🟢 Implemented | Primary: Rapid Fire. Secondary: **Heavy Slug** (Piercing). Visuals polished. |
| **Auto Shotgun** | 🟢 Implemented | Primary: Buckshot. Secondary: **Concussive Blast** (Knockback). Visuals polished. |
| **Rocket Launcher** | 🟢 Implemented | Primary: High-Ex Missile. Secondary: **Homing Swarm**. Visuals polished. |
| **Laser Gun** | 🔴 Pending | Needs Beam mechanic. |
| **Shockwave** | ⚫ Removed | Removed from game. |
| **Grinder** | 🔴 Pending | Needs Melee/Physics mechanic. |

### Enemies (Mobs)
| Unit | Status | Notes |
| :--- | :---: | :--- |
| **Drone: Scout** | 🟢 Implemented | [MobDroneScout.gd](file:///c:/Users/egazi/OneDrive/Belgeler/GitHub/helicopter/scripts/MobDroneScout.gd) (Supports Knockback/Stun) |
| **Drone: Tank** | 🟢 Implemented | [MobDroneTank.gd](file:///c:/Users/egazi/OneDrive/Belgeler/GitHub/helicopter/scripts/MobDroneTank.gd) (Supports Knockback/Stun) |
| **Drone: Support** | 🟢 Implemented | [MobDroneSupport.gd](file:///c:/Users/egazi/OneDrive/Belgeler/GitHub/helicopter/scripts/MobDroneSupport.gd) (Supports Knockback/Stun) |
| **Drone: Sniper** | 🔴 Pending | |
| **Drone: Stun** | 🔴 Pending | |
| **Elites (All)** | 🔴 Pending | Hunter, Mirage, Nemesis |

### Bosses
| Boss | Status | Notes |
| :--- | :---: | :--- |
| **The Constructor** | 🟢 Implemented | [BossConstructor.gd](file:///c:/Users/egazi/OneDrive/Belgeler/GitHub/helicopter/scripts/BossConstructor.gd). Phase logic active. Height fixed. |
| **Storm Bird** | 🔴 Pending | |
| **Mirage Core** | 🔴 Pending | |

### Points of Interest (POIs)
| POI | Status | Notes |
| :--- | :---: | :--- |
| **Rescue** | 🟢 Implemented | [POIRescue.gd](file:///c:/Users/egazi/OneDrive/Belgeler/GitHub/helicopter/scripts/POIRescue.gd) |
| **Destroy (Radar)** | 🟢 Implemented | [POIDestroy.gd](file:///c:/Users/egazi/OneDrive/Belgeler/GitHub/helicopter/scripts/POIDestroy.gd) |
| **Convoy Defend** | 🟢 Implemented | [POIConvoyDefend.gd](file:///c:/Users/egazi/OneDrive/Belgeler/GitHub/helicopter/scripts/POIConvoyDefend.gd) |

### UI
| Element | Status | Notes |
| :--- | :---: | :--- |
| **HUD** | 🟢 Implemented | Complete vertical stack layout (Health/Scrap/Dash/Weapons/Skill/Time) with cooldown bars. |
| **Menus** | ⚪ Unknown | Basic [Main.tscn](file:///c:/Users/egazi/OneDrive/Belgeler/GitHub/helicopter/scenes/Main.tscn) exists. |
