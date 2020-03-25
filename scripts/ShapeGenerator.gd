tool
extends Resource

class_name ShapeGenerator

var planet
export(float, -1, 1) var baseLevel: float setget setBaseLevel
export(Array) var noiseGenerators: Array

func getPointOnPlanet(var pointOnUnitSphere: Vector3) -> Vector3:
	var v: Vector3 = pointOnUnitSphere * planet.settings.radius
	var array = range(0, noiseGenerators.size())
	for i in array:
		if noiseGenerators[i].useFirstAsMask:
			pass
		var noise = noiseGenerators[i].evaluate(pointOnUnitSphere)
		if noise > baseLevel * noiseGenerators[i].strength:
			v += pointOnUnitSphere * noise
	return v

func setBaseLevel(var new):
	baseLevel = new
	if planet:
		planet.generate()
