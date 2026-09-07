# Velocity Rivals

An original Roblox arcade kart-racing starter game. It generates its track, checkpoints, boost pads, item boxes, karts and HUD automatically at runtime.

## Included

- Multiplayer races for up to 8 players
- 3-lap checkpoint-validated circuit
- Arcade acceleration, steering and reversing
- Hold Shift while turning to charge a drift mini-turbo
- Random Turbo, Shockwave and Barrier pickups
- Boost pads, respawning, countdown, speedometer and finish places
- Keyboard and basic mobile controls

## Open in Roblox Studio

### Recommended: Rojo

1. Install the free Rojo plugin in Roblox Studio and the Rojo CLI.
2. Open this folder in VS Code.
3. Run `rojo serve` in the folder.
4. In a blank Roblox place, connect the Rojo plugin to `localhost:34872`.
5. Press Play.

### Without Rojo

Create scripts in Roblox Studio matching the `src` folder structure, paste in the Lua source, then press Play. `Main.server.lua` belongs in `ServerScriptService`; `RaceClient.client.lua` belongs in `StarterPlayerScripts`; `Config.lua` belongs in `ReplicatedStorage/Shared` as a ModuleScript.

## Controls

- W/S or Up/Down: accelerate/reverse
- A/D or Left/Right: steer
- Shift: drift
- E: use item
- R: reset to the most recent checkpoint

## Next upgrades

The project is deliberately self-contained and asset-free. In Studio, replace the generated block karts and circuit with your own models while preserving the kart model's `Chassis` and `DriverSeat` names and the checkpoint order.
