tool
class_name ShapeGenerator
extends Resource

const Const := preload("../constants.gd")

export(Array) var noise_generators: Array
var _planet
var mask: float
var ng_array: Array   # May help a tiny bit by preallocating instead of allocating for every call.
var min_max: MinMax
var min_max_mutex := Mutex.new()
var planet_radius: float   # Shorthand for faster access.

func init(var _planet):
	self._planet = _planet
	self.min_max = MinMax.new()
	for ng in noise_generators:
		ng.init(_planet)
	ng_array = range(1, noise_generators.size())
	planet_radius = _planet.settings.radius
	calculate_min_max()


# Get elevation of point on unit sphere from all noise generators.
# Contains a few micro-optimizations like branchless calculations.
func get_unscaled_elevation(var point_on_unit_sphere: Vector3) -> float:
	var first_ng: NoiseGenerator = noise_generators[0]
	var first_layer_value: float = first_ng.evaluate(point_on_unit_sphere)
	var elevation: float = first_layer_value * first_ng.enabled_int
	
	for i in ng_array:
		# Get elevation when ng is enabled and use first layer as mask if needed.
		var ng: NoiseGenerator = noise_generators[i]
		var use_first_as_mask := ng.use_first_as_mask_int
		elevation += ng.evaluate(point_on_unit_sphere) * ng.enabled_int \
				* (first_layer_value * use_first_as_mask + 1 - use_first_as_mask)
	return elevation


# Return previously retrieved elevation in proportion to the planet.
func get_scaled_elevationa(var elevation: float) -> float:
	return _planet.settings.radius * (1.0 + elevation)


# Return previously retrieved elevation in proportion to the planet.
func get_scaled_elevation(var elevation: float) -> float:
	return planet_radius * (1.0 + elevation)


# Approximates the theoretical minimal and maximal unscaled elevation.
func calculate_min_max():
	var elevation: float
	var first_layer_value: float = noise_generators[0].strength * Const.MIN_MAX_APPROXIMATION
	if noise_generators[0].enabled:
		elevation = first_layer_value
	
	for i in ng_array:
		var ng: NoiseGenerator = noise_generators[i]
		if ng.enabled:
			var mask: float = first_layer_value if ng.use_first_as_mask else 1.0
			elevation += ng.strength * mask * Const.MIN_MAX_APPROXIMATION
	min_max.min_value = -elevation
	min_max.max_value = elevation
