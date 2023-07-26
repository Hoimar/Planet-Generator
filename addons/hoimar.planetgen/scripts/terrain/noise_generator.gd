@tool
class_name NoiseGenerator
extends Resource

@export var enabled: bool = true: set = set_enabled
@export var use_first_as_mask: bool: set = set_use_first_as_mask
@export var seed_value: int: set = set_seed_value
@export var strength: float: set = set_strength
@export var fractal_octaves: int = 4: set = set_octaves
@export var period: float = 0.03: set = set_period
@export var frequency: float = 0.6: set = set_frequency
@export var center: Vector3: set = set_center

# Micro-optimization to make generator functions branchless (no ifs).
var enabled_int: int
var use_first_as_mask_int: int

var _simplex: FastNoiseLite
var _planet: Node3D


func init(_planet):
	self._planet = _planet
	enabled_int = enabled
	use_first_as_mask_int = use_first_as_mask


func update_settings():
	_simplex = FastNoiseLite.new()
	_simplex.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_simplex.seed = seed_value
	_simplex.fractal_octaves = fractal_octaves
	_simplex.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	_simplex.frequency = frequency
	if _planet:
		_planet.generate()


func evaluate(v: Vector3) -> float:
	return _simplex.get_noise_3dv(center + v) * strength


func set_enabled(new):
	enabled = new
	update_settings()


func set_seed_value(new):
	seed_value = new
	update_settings()


func set_strength(new):
	strength = new
	update_settings()


func set_octaves(new):
	fractal_octaves = new
	update_settings()


func set_period(new):
	period = new
	update_settings()


func set_frequency(new):
	frequency = new
	update_settings()


func set_use_first_as_mask(new):
	use_first_as_mask = new
	update_settings()


func set_center(new):
	center = new
	update_settings()
