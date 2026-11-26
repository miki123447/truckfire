extends CharacterBody3D
class_name TruckController

signal speed_changed(speed_kmh: float)

@export_group("Vehicle")
@export var max_forward_speed: float = 27.0
@export var max_reverse_speed: float = 7.0
@export var acceleration: float = 5.5
@export var service_brake: float = 13.0
@export var rolling_resistance: float = 0.65
@export var steering_rate: float = 0.72
@export var steering_sensitivity: float = 1.0
@export var max_steering_speed: float = 0.42

var _longitudinal_speed := 0.0
var _steering_input := 0.0
var _spawn_transform: Transform3D

func _ready() -> void:
	_spawn_transform = global_transform
	floor_snap_length = 0.45
	floor_max_angle = deg_to_rad(48.0)

func _physics_process(delta: float) -> void:
	_read_driver_inputs(delta)
	_apply_vehicle_motion(delta)
	move_and_slide()
	speed_changed.emit(absf(_longitudinal_speed) * 3.6)

func _read_driver_inputs(delta: float) -> void:
	var throttle := Input.get_action_strength("accelerate")
	var braking := Input.get_action_strength("brake")
	var reversing := Input.is_action_pressed("reverse")
	var target_speed := max_reverse_speed if reversing else max_forward_speed
	var drive_direction := -1.0 if reversing else 1.0

	if throttle > 0.0:
		_longitudinal_speed = move_toward(_longitudinal_speed, target_speed * drive_direction, acceleration * throttle * delta)
	elif braking > 0.0:
		_longitudinal_speed = move_toward(_longitudinal_speed, 0.0, service_brake * braking * delta)
	else:
		_longitudinal_speed = move_toward(_longitudinal_speed, 0.0, rolling_resistance * delta)

	var steer_axis := Input.get_axis("steer_left", "steer_right")
	_steering_input = move_toward(_steering_input, steer_axis, steering_rate * delta)

func _apply_vehicle_motion(delta: float) -> void:
	var speed_ratio := clampf(absf(_longitudinal_speed) / max_forward_speed, 0.0, 1.0)
	var steer_factor := lerpf(1.0, max_steering_speed, speed_ratio)
	var direction_factor := -1.0 if _longitudinal_speed < -0.1 else 1.0
	rotate_y(-_steering_input * steering_sensitivity * steer_factor * direction_factor * delta)

	var forward := -global_transform.basis.z
	velocity.x = forward.x * _longitudinal_speed
	velocity.z = forward.z * _longitudinal_speed
	if not is_on_floor():
		velocity.y -= 24.0 * delta
	else:
		velocity.y = -0.15

func reset_vehicle() -> void:
	global_transform = _spawn_transform
	velocity = Vector3.ZERO
	_longitudinal_speed = 0.0
	_steering_input = 0.0

func get_speed_kmh() -> float:
	return absf(_longitudinal_speed) * 3.6
