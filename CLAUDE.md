# Project: Clash 2D (Working Title)
Godot 4.x, 2D side-scrolling, 1280x720
Local multiplayer arcade game inspired by Clash Royale.
Two players on the same machine, each with a joystick + 4 buttons.

---

## Game Overview
- Layout: Player1 towers | bridge | Player2 towers (left to right)
- Players spend elixir to play cards from a 4-card hand
- Cards spawn troops on the player's side of the field
- Troops walk toward the enemy side and attack automatically
- First to destroy all 3 enemy towers wins

---

## Build Layers (do not skip ahead)
1. Field scene — static layout, placeholder towers, bridge
2. Troop spawning — button spawns unit, unit walks toward enemy base
3. Combat — troops attack each other and towers in range
4. Elixir + card system — elixir ticks, cards have costs, hand cycles
5. Input — map gamepad joystick/buttons to card select + placement
6. Win condition — detect tower destruction, trigger end screen
7. Custom cards + polish — only after layers 1-6 are solid

**Never work on a layer until the previous one runs without errors.**

---

## Scene Map
- game.tscn — root gameplay scene
- field.tscn — the arena (towers, bridge, spawn zones)
- troop.tscn — individual troop unit
- tower.tscn — tower node (used for all 6 towers)
- ui/hud.tscn — full HUD root
- ui/card_slot.tscn — single card slot in hand
- ui/elixir_bar.tscn — elixir display widget
- ui/hand.tscn — 4-card hand container

## Script Map
- scripts/game_manager.gd — central game state, win condition, round lifecycle
- scripts/player_controller.gd — per-player input handling, card selection, placement
- scripts/deck.gd — deck/hand management, card cycling
- scripts/card_data.gd — CardData Resource class (name, cost, troop_scene, icon)
- scripts/tower.gd — tower health, death detection, signals to game_manager
- scripts/troop_unit.gd — movement, target acquisition, attack logic
- scripts/field.gd — spawn zone references, bridge boundaries
- ui/hud.gd — HUD root, connects to game_manager signals
- ui/card_slot.gd — card slot display, highlight on selection
- ui/elixir_bar.gd — elixir tick and visual fill

---

## Node Naming Conventions
- Scenes: PascalCase (e.g. CardSlot, TroopUnit)
- Script variables: snake_case
- Signals: snake_case, past tense verb (e.g. tower_destroyed, troop_died)
- Constants: UPPER_SNAKE_CASE
- Groups: lowercase string (e.g. "troops", "towers", "player1_troops")

## Autoloads
- GameManager — scripts/game_manager.gd (singleton, added once layer 3 begins)
- No other autoloads without explicit confirmation

---

## Input Map (Gamepad)
- Player 1: device 0 — joy_left/right for card select, buttons 0-3 for card play
- Player 2: device 1 — same mapping
- Do not use keyboard input as primary — keyboard is debug only

---

## Hard Rules
- Never modify project.godot without confirmation
- Never rename existing nodes in .tscn files without updating ALL references in scripts
- Never add autoloads without confirmation
- Never use Python idioms in GDScript (no list comprehensions, no walrus operator, no f-strings)
- Never use _ready() for game logic that depends on other nodes being ready — use call_deferred() or signals
- Always set owner on programmatically created nodes or they will silently vanish on save
- @onready vars must reference nodes that actually exist in the same scene tree

## After Every Code Change
1. State which nodes you assumed exist and their exact paths (e.g. $HUD/Hand/CardSlot1)
2. Verify those paths exist in the corresponding .tscn file
3. Run: godot --headless --check-only res://[modified_scene].tscn
4. Report any errors before declaring done

---

## Current Status
Fresh start. Nothing is implemented yet. Begin at Layer 1.# CLAUDE.md
