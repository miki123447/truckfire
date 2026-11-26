# Truckfire — Prototype 0.1

## Included
- Godot 4.7 project using Forward Plus and Jolt Physics.
- Imported Mercedes truck model, centered on the vehicle origin.
- Asphalt color, normal and AO maps supplied for CityStreetAsphaltGenericClean001; the material uses a fixed roughness value.
- Procedural 520 m test road, rolling terrain with static collision, road markings and metal guardrails.
- Basic keyboard driving, follow camera, cockpit camera and speed HUD.

## Start
- Extract the complete ZIP into a folder.
- Double-click `INICIAR_TRUCKFIRE.bat` (requires Godot 4.7 for Windows). The first launch imports the project assets before starting the game.

## Controls
- W / Up: accelerate
- S / Down: brake
- A / Left: steer left
- D / Right: steer right
- R: reverse direction
- C: switch camera
- F: reset vehicle

## Notes
This is an initial playable driving prototype, not a finished vehicle simulation. The current controller is a simplified longitudinal/steering model. Suspension, wheel-by-wheel physics, gearbox, traffic, delivery gameplay, and a detailed roadside asset library are planned for later iterations.

The asphalt uses the supplied color, normal and AO maps with fixed roughness. The terrain collision allows the truck to remain supported if it leaves the asphalt.
