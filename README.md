# Truckfire

Truckfire is a road-transport simulator project built from scratch in Godot 4.7.

## Prototype 0.1
Extract the complete project ZIP and double-click `INICIAR_TRUCKFIRE.bat`. The launcher imports the assets on first run and starts the game. Godot 4.7 for Windows must be installed. See [docs/PROTOTYPE_0.1.md](docs/PROTOTYPE_0.1.md) for controls and current scope.

The complete local project package includes the Mercedes GLB, CityStreetAsphaltGenericClean001 PBR maps, and guardrail source assets. Binary source assets are distributed in the project ZIP rather than duplicated in this source-only branch.

## Notes
The asphalt material uses the supplied color, normal and ambient-occlusion maps, with a fixed roughness value so the project does not depend on a missing roughness image. The procedural roadside terrain has static collision, and the Mercedes model is aligned to the vehicle's physics origin.
