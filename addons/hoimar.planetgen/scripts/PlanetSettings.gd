tool
class_name PlanetSettings
extends Resource

export(int, 3, 9999) var resolution: int = 21 setget setResolution
export(float) var radius: float = 1 setget setRadius
export(bool) var hasWater = true setget setHasWater
export(bool) var hasAtmosphere = true setget setHasAtmosphere
export(float, 1, 10000) var atmosphereThickness: float = 1.15 setget setAtmosphereThickness
export(Resource) var shapeGenerator

var planet: Spatial


func init(var _planet):
	self.planet = _planet
	shapeGenerator.init(_planet)


func onSettingsChanged():
	if !planet:
		return
	planet.generate()


func setResolution(var new: int):
	resolution = new
	onSettingsChanged()


func setRadius(var new: float):
	radius = new
	onSettingsChanged()


func setHasWater(var new: bool):
	hasWater = new
	onSettingsChanged()


func setHasAtmosphere(var new: bool):
	hasAtmosphere = new
	onSettingsChanged()


func setAtmosphereThickness(var new: float):
	atmosphereThickness = new
	onSettingsChanged()
