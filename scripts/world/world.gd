extends Node3D

@export var truck_scene: PackedScene
@export var road_length: float = 520.0
@export var road_width: float = 12.0

var truck: TruckController
var follow_camera: Camera3D
var cockpit_camera: Camera3D
var speed_label: Label
var gear_label: Label
var _camera_mode := 0

const ASPHALT_DIR := "res://assets/textures/asphalt/"

func _ready() -> void:
	_build_environment()
	_build_terrain()
	_build_road()
	_build_guardrails()
	_spawn_truck()
	_build_hud()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _process(_delta: float) -> void:
	if truck == null:
		return
	if Input.is_action_just_pressed("reset_vehicle"):
		truck.reset_vehicle()
	if Input.is_action_just_pressed("camera_toggle"):
		_toggle_camera()
	if speed_label:
		speed_label.text = "%03d" % int(round(truck.get_speed_kmh()))
		gear_label.text = "R" if Input.is_action_pressed("reverse") else ("N" if truck.get_speed_kmh() < 1.0 else "D")

func _build_environment() -> void:
	var world_env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.20, 0.34, 0.49)
	sky_material.sky_horizon_color = Color(0.69, 0.76, 0.80)
	sky_material.ground_bottom_color = Color(0.18, 0.21, 0.17)
	sky_material.ground_horizon_color = Color(0.62, 0.66, 0.60)
	sky.sky_material = sky_material
	environment.sky = sky
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.65
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	world_env.environment = environment
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, -28.0, 0.0)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 180.0
	add_child(sun)

func _build_terrain() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var x_steps := 72
	var z_steps := 150
	var x_span := 180.0
	var z_span := road_length + 100.0
	var noise := FastNoiseLite.new()
	noise.seed = 2407
	noise.frequency = 0.008
	noise.fractal_octaves = 4
	for z_i in range(z_steps + 1):
		var z := -z_span * 0.5 + z_span * float(z_i) / z_steps
		for x_i in range(x_steps + 1):
			var x := -x_span * 0.5 + x_span * float(x_i) / x_steps
			var distance_from_road := absf(x)
			var hill := noise.get_noise_2d(x, z) * 5.5
			var verge_t := clampf(inverse_lerp(8.0, 30.0, distance_from_road), 0.0, 1.0)
			var verge_blend := verge_t * verge_t * (3.0 - 2.0 * verge_t)
			var height := hill * verge_blend - 0.12
			var shade := 0.88 + noise.get_noise_2d(x * 2.2, z * 2.2) * 0.08
			surface.set_color(Color(0.24 * shade, 0.31 * shade, 0.19 * shade, 1.0))
			surface.add_vertex(Vector3(x, height, z))
	for z_i in range(z_steps):
		for x_i in range(x_steps):
			var a := z_i * (x_steps + 1) + x_i
			var b := a + 1
			var c := a + x_steps + 1
			var d := c + 1
			surface.add_index(a); surface.add_index(c); surface.add_index(b)
			surface.add_index(b); surface.add_index(c); surface.add_index(d)
	surface.generate_normals()
	var terrain_mesh := surface.commit()
	var terrain_material := StandardMaterial3D.new()
	terrain_material.vertex_color_use_as_albedo = true
	terrain_material.roughness = 1.0
	terrain_mesh.surface_set_material(0, terrain_material)

	var terrain_body := StaticBody3D.new()
	terrain_body.name = "TerrainCollision"
	var terrain_collision := CollisionShape3D.new()
	terrain_collision.shape = terrain_mesh.create_trimesh_shape()
	terrain_body.add_child(terrain_collision)
	add_child(terrain_body)

	var terrain := MeshInstance3D.new()
	terrain.name = "TerrainVisual"
	terrain.mesh = terrain_mesh
	terrain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(terrain)

func _build_road() -> void:
	var road := StaticBody3D.new()
	road.name = "AsphaltRoad"
	var road_mesh := PlaneMesh.new()
	road_mesh.size = Vector2(road_width, road_length)
	road_mesh.subdivide_width = 2
	road_mesh.subdivide_depth = 2
	var road_surface := MeshInstance3D.new()
	road_surface.mesh = road_mesh
	road_surface.position.y = 0.015
	road_surface.material_override = _make_asphalt_material()
	road.add_child(road_surface)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(road_width, 0.3, road_length)
	collision.shape = shape
	collision.position.y = -0.15
	road.add_child(collision)
	add_child(road)

	for dash_index in range(52):
		var dash_z := -road_length * 0.5 + 5.0 + float(dash_index) * 10.0
		_add_road_marking(0.0, 0.035, Color(0.92, 0.88, 0.68), 5.0, dash_z)
	_add_road_marking(-road_width * 0.5 + 0.22, 0.018, Color(0.88, 0.88, 0.82), road_length)
	_add_road_marking(road_width * 0.5 - 0.22, 0.018, Color(0.88, 0.88, 0.82), road_length)

func _make_asphalt_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture = load(ASPHALT_DIR + "CityStreetAsphaltGenericClean001_COL_2K.jpg")
	material.normal_enabled = true
	material.normal_texture = load(ASPHALT_DIR + "CityStreetAsphaltGenericClean001_NRM_2K.jpg")
	material.ao_enabled = true
	material.ao_texture = load(ASPHALT_DIR + "CityStreetAsphaltGenericClean001_AO_2K.jpg")
	material.roughness = 0.92
	material.metallic = 0.0
	material.uv1_scale = Vector3(1.4, 48.0, 1.0)
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return material

func _add_road_marking(x: float, width: float, color: Color, length: float, z_position: float = 0.0) -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(width, 0.012, length)
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = Vector3(x, 0.04, z_position)
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	instance.material_override = material
	add_child(instance)

func _build_guardrails() -> void:
	for side in [-1.0, 1.0]:
		var rail_body := StaticBody3D.new()
		rail_body.name = "GuardrailCollision"
		rail_body.position = Vector3(side * (road_width * 0.5 + 0.85), 0.72, 0.0)
		var rail := MeshInstance3D.new()
		rail.name = "Guardrail"
		rail.mesh = _make_guardrail_mesh()
		var metal := StandardMaterial3D.new()
		metal.albedo_color = Color(0.48, 0.52, 0.53)
		metal.metallic = 0.72
		metal.roughness = 0.36
		rail.material_override = metal
		rail_body.add_child(rail)
		var rail_collision := CollisionShape3D.new()
		var rail_shape := BoxShape3D.new()
		rail_shape.size = Vector3(0.24, 0.28, road_length)
		rail_collision.shape = rail_shape
		rail_collision.position.y = 0.0
		rail_body.add_child(rail_collision)
		add_child(rail_body)

func _make_guardrail_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var length := road_length
	var profile := [Vector2(-0.08, -0.06), Vector2(-0.08, 0.02), Vector2(-0.035, 0.075), Vector2(0.035, 0.075), Vector2(0.08, 0.02), Vector2(0.08, -0.06)]
	for i in range(profile.size()):
		var next := (i + 1) % profile.size()
		var p1 := profile[i]
		var p2 := profile[next]
		var v1 := Vector3(p1.x, p1.y, -length * 0.5)
		var v2 := Vector3(p2.x, p2.y, -length * 0.5)
		var v3 := Vector3(p1.x, p1.y, length * 0.5)
		var v4 := Vector3(p2.x, p2.y, length * 0.5)
		st.add_vertex(v1); st.add_vertex(v3); st.add_vertex(v2)
		st.add_vertex(v2); st.add_vertex(v3); st.add_vertex(v4)
	st.generate_normals()
	return st.commit()

func _spawn_truck() -> void:
	truck = truck_scene.instantiate() as TruckController
	truck.position = Vector3(0.0, 0.2, 120.0)
	add_child(truck)
	_build_cameras()

func _build_cameras() -> void:
	var pivot := Node3D.new()
	pivot.name = "CameraRig"
	pivot.position = Vector3(0.0, 2.6, 8.8)
	truck.add_child(pivot)
	follow_camera = Camera3D.new()
	follow_camera.position = Vector3(0.0, 1.0, 0.0)
	follow_camera.rotation_degrees = Vector3(-9.0, 0.0, 0.0)
	follow_camera.current = true
	follow_camera.fov = 72.0
	pivot.add_child(follow_camera)

	cockpit_camera = Camera3D.new()
	cockpit_camera.position = Vector3(0.0, 2.15, -0.65)
	cockpit_camera.rotation_degrees = Vector3(-2.0, 0.0, 0.0)
	cockpit_camera.fov = 78.0
	truck.add_child(cockpit_camera)

func _toggle_camera() -> void:
	_camera_mode = (_camera_mode + 1) % 2
	follow_camera.current = _camera_mode == 0
	cockpit_camera.current = _camera_mode == 1

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "HUD"
	add_child(layer)
	var panel := PanelContainer.new()
	panel.anchor_left = 1.0
	panel.anchor_top = 1.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -250.0
	panel.offset_top = -148.0
	panel.offset_right = -28.0
	panel.offset_bottom = -28.0
	layer.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	panel.add_child(column)
	var caption := Label.new()
	caption.text = "TRUCKFIRE  /  DRIVE"
	caption.add_theme_font_size_override("font_size", 12)
	caption.add_theme_color_override("font_color", Color(0.63, 0.69, 0.72))
	column.add_child(caption)
	var speed_row := HBoxContainer.new()
	column.add_child(speed_row)
	speed_label = Label.new()
	speed_label.text = "000"
	speed_label.add_theme_font_size_override("font_size", 48)
	speed_label.add_theme_color_override("font_color", Color(0.95, 0.96, 0.92))
	speed_row.add_child(speed_label)
	var units := Label.new()
	units.text = " km/h"
	units.add_theme_font_size_override("font_size", 15)
	units.add_theme_color_override("font_color", Color(0.72, 0.78, 0.80))
	units.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	speed_row.add_child(units)
	gear_label = Label.new()
	gear_label.text = "N"
	gear_label.add_theme_font_size_override("font_size", 18)
	gear_label.add_theme_color_override("font_color", Color(0.95, 0.72, 0.34))
	column.add_child(gear_label)
	var controls := Label.new()
	controls.text = "W/S Accelerar i frenar   A/D Girar\nR Marcha atrás   C Cambiar cámara   F Recolocar"
	controls.add_theme_font_size_override("font_size", 10)
	controls.add_theme_color_override("font_color", Color(0.72, 0.78, 0.80))
	column.add_child(controls)
