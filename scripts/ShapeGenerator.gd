tool
extends Resource

class_name ShapeGenerator

var planet
var terrainMinMax: MinMax   # Stores minimum and maximum elevation values.
var numLayers: int
export(Array) var noiseGenerators: Array


func init(var _planet):
	self.planet = _planet
	self.terrainMinMax = MinMax.new()
	for ng in noiseGenerators:
		ng.init(planet)
	numLayers = noiseGenerators.size()

func getUnscaledElevation(var pointOnUnitSphere: Vector3) -> float:
	var elevation: float
	var firstLayerValue: float
	if numLayers > 0:
		var ng: NoiseGenerator = noiseGenerators[0]
		firstLayerValue = ng.evaluate(pointOnUnitSphere)
		if ng.enabled:
			elevation = firstLayerValue;
	
	var values: Array = range(1, numLayers)
	for i in values:
		var ng: NoiseGenerator = noiseGenerators[i]
		if ng.enabled:
			var mask: float = firstLayerValue if ng.useFirstAsMask else 1.0
			elevation += ng.evaluate(pointOnUnitSphere) * mask
	terrainMinMax.addValue(elevation)
	return elevation

func getScaledElevation(var elevation: float) -> Vector3:
	return planet.settings.radius * (1.0 + elevation)

# intended for debug
func calculateMinMax():
	var value: float
	if noiseGenerators[0].enabled:
		value = noiseGenerators[0].strength
	var ngs: Array = range(1, numLayers)
	for i in ngs:
		var ng: NoiseGenerator = noiseGenerators[i]
		if ng.enabled:
			var mask: float = noiseGenerators[0].strength if ng.useFirstAsMask else 1.0
			value += ng.strength * mask
	terrainMinMax.minValue = -value
	terrainMinMax.maxValue = value
