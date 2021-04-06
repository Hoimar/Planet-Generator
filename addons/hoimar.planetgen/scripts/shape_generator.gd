tool
class_name ShapeGenerator
extends Resource

var _planet
var terrain_min_max: MinMax   # Stores minimum and maximum elevation values.
var mask: float
var ng_array: Array   # May help a tiny bit by preallocating instead of allocating for every call.
export(Array) var noise_generators: Array


func init(var _planet):
	self._planet = _planet
	self.terrain_min_max = MinMax.new()
	for ng in noise_generators:
		ng.init(_planet)
	ng_array = range(1, noise_generators.size())


func get_unscaled_elevation(var point_on_unit_sphere: Vector3) -> float:
	var elevation: float = 0.0
	var first_layer_value: float = noise_generators[0].evaluate(point_on_unit_sphere)
	if noise_generators[0].enabled:
		elevation += first_layer_value
	
	for i in ng_array:
		var ng: NoiseGenerator = noise_generators[i]
		if ng.enabled:
			var mask: float = first_layer_value if ng.use_first_as_mask else 1.0
			elevation += ng.evaluate(point_on_unit_sphere) * mask
	terrain_min_max.add_value(elevation)
	return elevation


func get_scaled_elevation(var elevation: float) -> Vector3:
	return _planet.settings.radius * (1.0 + elevation)


# Intended for debugging purposes.
func calculate_min_max():
	var value: float
	if noise_generators[0].enabled:
		value = noise_generators[0].strength
	var ngs: Array = range(1, noise_generators.size())
	for i in ngs:
		var ng: NoiseGenerator = noise_generators[i]
		if ng.enabled:
			var mask: float = noise_generators[0].strength if ng.useFirstAsMask else 1.0
			value += ng.strength * mask
	terrain_min_max._min_value = -value
	terrain_min_max._max_value = value
