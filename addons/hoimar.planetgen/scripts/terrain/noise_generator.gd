tool
class_name NoiseGenerator
extends Resource

export var enabled: bool = true setget set_enabled
export var use_first_as_mask: bool setget set_use_first_as_mask   # Whether to use the first generator as mask.
export var seed_value: int setget set_seed_value
export var strength: float setget set_strength   # Amplitude of noise values.
export var octaves: int = 4 setget set_octaves
export var period: float = 0.03 setget set_period
export var persistence: float = 0.6 setget set_persistence
export var center: Vector3 setget set_center

# Micro-optimization to make generator functions branchless (no ifs).
var enabled_int: int
var use_first_as_mask_int: int

var _simplex: OpenSimplexNoise
var _planet: Spatial


func init(var _planet):
	self._planet = _planet
	enabled_int = enabled
	use_first_as_mask_int = use_first_as_mask


func update_settings():
	_simplex = OpenSimplexNoise.new()
	_simplex.seed = seed_value
	_simplex.octaves = octaves
	_simplex.period = period
	_simplex.persistence = persistence
	if _planet:
		_planet.generate()


func evaluate(var v: Vector3) -> float:
	return _simplex.get_noise_3dv(center + v) * strength


func set_enabled(var new):
	enabled = new
	update_settings()


func set_seed_value(var new):
	seed_value = new
	update_settings()


func set_strength(var new):
	strength = new
	update_settings()


func set_octaves(var new):
	octaves = new
	update_settings()


func set_period(var new):
	period = new
	update_settings()


func set_persistence(var new):
	persistence = new
	update_settings()


func set_use_first_as_mask(var new):
	use_first_as_mask = new
	update_settings()


func set_center(var new):
	center = new
	update_settings()
