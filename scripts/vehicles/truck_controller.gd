extends CharacterBody3D
class_name TruckController

signal speed_changed(speed_kmh: float)

@export_group("Vehicle")
@export var max_forward_speed: float = 27.0
@export var max_reverse_speed: float = 7.0
@export var acceleration: float = 5.5
@export var service_brake: float = 13.0
@export var rolling_resistance: float = 0.65

@export_group("Steering")
@export var steering_rate: float = 1.8
@export var wheelbase: float = 4.2
@export var max_steering_angle: float = 0.48
@export_range(0.1, 1.0) var high_speed_steering_factor: float = 0.40

var _longitudinal_speed: float = 0.0
var _steering_input: float = 0.0
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
	var throttle: float = Input.get_action_strength("accelerate")
	var braking: float = Input.get_action_strength("brake")
	var reversing: bool = Input.is_action_pressed("reverse")
	var target_speed: float = max_reverse_speed if reversing else max_forward_speed
	var drive_direction: float = -1.0 if reversing else 1.0

	if throttle > 0.0:
		_longitudinal_speed = move_toward(
			_longitudinal_speed,
			target_speed * drive_direction,
			acceleration * throttle * delta
		)
	elif braking > 0.0:
		_longitudinal_speed = move_toward(
			_longitudinal_speed, 0.0, service_brake * braking * delta
		)
	else:
		_longitudinal_speed = move_toward(
			_longitudinal_speed, 0.0, rolling_resistance * delta
		)

	var steer_axis: float = Input.get_axis("steer_left", "steer_right")
	_steering_input = move_toward(_steering_input, steer_axis, steering_rate * delta)

func _apply_vehicle_motion(delta: float) -> void:
	# Modelo cinemático tipo bicicleta: el giro depende de la dirección,
	# la distancia entre ejes y la velocidad longitudinal del camión.
	var speed_ratio: float = clampf(
		absf(_longitudinal_speed) / max_forward_speed, 0.0, 1.0
	)
	var steering_factor: float = lerpf(
		1.0, high_speed_steering_factor, speed_ratio
	)
	# Input.get_axis devuelve negativo al girar a la izquierda.
	# Con el eje frontal local -Z, un ángulo positivo gira hacia la izquierda.
	var steering_angle: float = -_steering_input * max_steering_angle * steering_factor

	if absf(_longitudinal_speed) > 0.01 and wheelbase > 0.01:
		var yaw_rate: float = (
			_longitudinal_speed * tan(steering_angle) / wheelbase
		)
		rotate_y(yaw_rate * delta)

	var forward: Vector3 = -global_transform.basis.z
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
