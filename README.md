# Clash 2D 🕹️

> A local multiplayer arcade game built for the Wisconsin Engineering Expo — inspired by Clash Royale, designed to run on a custom-built arcade cabinet with physical joystick and button controls.

![Godot](https://img.shields.io/badge/Godot_4.x-478CBF?style=flat-square&logo=godot-engine&logoColor=white)
![GDScript](https://img.shields.io/badge/GDScript-478CBF?style=flat-square&logo=godot-engine&logoColor=white)
![Local Multiplayer](https://img.shields.io/badge/Local%20Multiplayer-2%20Players-green?style=flat-square)
![Expo](https://img.shields.io/badge/Shown%20At-Wisconsin%20Engineering%20Expo-red?style=flat-square)

---

## What is this?

Clash 2D is a real-time strategy arcade game for two players on the same machine. Each player controls a side of the arena — spend elixir, play cards from your hand, and send troops marching toward your opponent's towers. First to destroy all 3 enemy towers wins.

Built from scratch in Godot 4 and demoed at the **Wisconsin Engineering Expo 2026** on a custom arcade cabinet with physical joystick and button hardware, built by the [Kappa Eta Kappa](https://khk.org) team at UW-Madison.

---

## Gameplay

```
[ Player 1 Towers ] ←——— Bridge ———→ [ Player 2 Towers ]
```

- Each player has **3 towers** to defend
- Elixir regenerates over time — spend it to play cards
- Cards spawn **troops** that automatically walk toward and attack the enemy side
- Troops fight each other and target towers in range
- **First to destroy all 3 enemy towers wins**

---

## Controls

| Action | Player 1 (Device 0) | Player 2 (Device 1) |
|---|---|---|
| Select card | Joystick left/right | Joystick left/right |
| Play card | Buttons 0–3 | Buttons 0–3 |

Designed for physical arcade cabinet buttons. Keyboard input is debug only.

---

## Built With

- **Godot 4.x** — game engine
- **GDScript** — all game logic
- **Custom arcade cabinet** — physical joystick + button hardware, NVIDIA Jetson edge module

---

## Project Structure

```
khk-expo-2026/
├── scripts/
│   ├── game_manager.gd      # central state, win condition, round lifecycle
│   ├── player_controller.gd # per-player input, card selection, placement
│   ├── deck.gd              # hand management, card cycling
│   ├── card_data.gd         # CardData resource (name, cost, troop scene, icon)
│   ├── tower.gd             # tower health, death detection
│   ├── troop_unit.gd        # movement, targeting, attack logic
│   └── field.gd             # spawn zones, bridge boundaries
├── game.tscn                # root gameplay scene
├── tower.tscn               # tower node (all 6 towers)
├── troop.tscn               # individual troop unit
├── assets/                  # sprites and textures
└── project.godot
```

---

## The Arcade Cabinet

This game was built specifically to run on a custom arcade cabinet designed and built by KHK at UW-Madison. The cabinet features:

- Physical joystick + button controls wired per player
- **NVIDIA Jetson** edge module for on-device processing
- Custom enclosure built for the Wisconsin Engineering Expo

---

## Team

Built by **Kappa Eta Kappa (KHK)** — the professional CS fraternity at UW-Madison — for the 2026 Wisconsin Engineering Expo.
