# Battle Royale (Godot 4.7, Mobile)

Free Fire style battle royale starter for Android. Open the project folder in
Godot 4.7+ and press Play — everything is set up: 3D models, animations,
touch controls, bots, loot and a shrinking zone.

## What is inside

- `models/soldier.glb` — the character model (idle/walk/run/jump animations from the GLB)
- `models/ak47.glb`, `models/sniper.glb` — real weapon models (held in hand and lying on the ground as loot)
- `scripts/main.gd` — match logic: world, 9 bots, 14 loot spawns, shrinking zone (5 min), BOOYAH / ELIMINATED
- `scripts/player.gd` — third-person player: run, sprint, jump, crouch, aim, shoot, reload, punch
- `scripts/bot.gd` — AI bots: wander, chase, shoot, and punch when close
- `scripts/loot.gd` — weapons lying on the ground, spinning with a bob so they are easy to spot
- `scripts/hud.gd`, `joystick.gd`, `look_area.gd`, `minimap.gd` — Free Fire style mobile HUD:
  left joystick to move, drag anywhere else to look, FIRE / PUNCH / JUMP / CROUCH / SPRINT / RELOAD buttons
- `scripts/controls.gd` — input hub (also maps keyboard for desktop testing: WASD is not needed,
  use F or mouse to fire, Space jump, C crouch, Shift sprint, Q punch, R reload)

## Gameplay

- Walk over a gun on the ground to pick it up. It appears in the character's hand.
- FIRE shoots (hold for automatic fire with the AK), PUNCH deals 20 damage up close
  (hold PUNCH to keep punching), bots punch back when they get close.
- Punch damage is reduced by armor; the shrinking blue zone damages anyone outside it.
- Kill all 9 bots to win: BOOYAH!

## Build APK for Android

1. Open the project in Godot 4.7 (desktop).
2. Install the Android build template: Project > Install Android Build Template.
3. Install export templates (Editor > Manage Export Templates) and configure
   Editor Settings > Export > Android (SDK path, debug keystore).
4. Project > Export > Add > Android, set package name, then Export Project (APK).
5. Copy the APK to your phone and install it, or use "Deploy with one click" on a USB device.

The project already uses the Mobile renderer, landscape orientation and touch emulation,
so it is ready for phone testing.

## Notes for tuning

- Gun position in the hand: see `player.gd` > `_attach_gun` (rotation/position offsets).
- If your soldier GLB uses different bone names, the code auto-finds a bone
  containing "hand" (prefers the right hand).
- Bot difficulty: see the constants at the top of `scripts/bot.gd`.
