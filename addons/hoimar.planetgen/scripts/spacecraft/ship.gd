extends RigidBody3D

const Constants := preload("../constants.gd")
const MAXVELOCITY := 50.0
const ROTATIONSPEED := 0.5
const SPEED_INCREMENT := 0.0005
const SPEED_SCALE_MAX := 0.2

signal speed_scale_changed(value)

var impulse := Vector3.ZERO
var rotation_basis := transform.basis
var apply_rotation := false
var speed_scale := 0.0005: get = get_speed_scale, set = set_speed_scale

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _physics_process(delta: float):
	calculate_gravity(delta)
	apply_central_impulse(impulse)
	impulse = Vector3.ZERO

func _integrate_forces(state: PhysicsDirectBodyState3D):
	state.transform.basis = rotation_basis

func apply_thrust(v: Vector3) -> bool:
	if linear_velocity.length() > MAXVELOCITY:
		return false
	impulse += global_transform.basis * v * speed_scale
	return true

func rotate(axis: Vector3, degrees: float):
	rotation_basis = rotation_basis.rotated(axis, deg_to_rad(degrees))

func calculate_gravity(delta: float):
	var bodies = get_tree().get_nodes_in_group("planets")
	for body in bodies:
		var radius : float = body.global_transform.origin.distance_to(global_transform.origin)
		var direction : Vector3 = (body.global_transform.origin - global_transform.origin).normalized()
		var accel = direction * Constants.GRAVITY * body.mass / (radius * radius) * delta
		impulse += accel

func set_speed_scale(new: float):
	speed_scale = new
	clamp(speed_scale, SPEED_INCREMENT, SPEED_SCALE_MAX)
	emit_signal("speed_scale_changed", new)

func get_speed_scale():
	return speed_scale
