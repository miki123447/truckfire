# Truckfire — Prototype 0.1

## Included
- Godot 4.7 project using Forward Plus and Jolt Physics.
- Imported Mercedes truck model (assets/models/mercedes_truck.glb).
- Asphalt PBR maps supplied for CityStreetAsphaltGenericClean001.
- Procedural 520 m test road, natural rolling terrain, road markings and metal guardrails.
- Basic keyboard driving, follow camera, cockpit camera and speed HUD.

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

The model's GLB has embedded image textures. The separate texture archive is retained in the source upload but is not required by this prototype. The asphalt gloss map is inverted to generate a roughness map for Godot's StandardMaterial3D workflow.
