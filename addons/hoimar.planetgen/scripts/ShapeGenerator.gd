tool
class_name ShapeGenerator
extends Resource

var planet
var terrainMinMax: MinMax   # Stores minimum and maximum elevation values.
var mask: float
var ng_array: Array   # May help a tiny bit by preallocating instead of allocating for every call.
export(Array) var noiseGenerators: Array


func init(var _planet):
	self.planet = _planet
	self.terrainMinMax = MinMax.new()
	for ng in noiseGenerators:
		ng.init(planet)
	ng_array = range(1, noiseGenerators.size())


func getUnscaledElevation(var pointOnUnitSphere: Vector3) -> float:
	var elevation: float = 0.0
	var firstLayerValue: float = noiseGenerators[0].evaluate(pointOnUnitSphere)
	if noiseGenerators[0].enabled:
		elevation += firstLayerValue
	
	for i in ng_array:
		var ng: NoiseGenerator = noiseGenerators[i]
		if ng.enabled:
			var mask: float = firstLayerValue if ng.useFirstAsMask else 1.0
			elevation += ng.evaluate(pointOnUnitSphere) * mask
	terrainMinMax.addValue(elevation)
	return elevation


func getScaledElevation(var elevation: float) -> Vector3:
	return planet.settings.radius * (1.0 + elevation)


# Intended for debugging purposes.
func calculateMinMax():
	var value: float
	if noiseGenerators[0].enabled:
		value = noiseGenerators[0].strength
	var ngs: Array = range(1, noiseGenerators.size())
	for i in ngs:
		var ng: NoiseGenerator = noiseGenerators[i]
		if ng.enabled:
			var mask: float = noiseGenerators[0].strength if ng.useFirstAsMask else 1.0
			value += ng.strength * mask
	terrainMinMax.minValue = -value
	terrainMinMax.maxValue = value
