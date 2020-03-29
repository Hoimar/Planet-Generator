tool
extends Resource

class_name PlanetSettings

export(int) var seedValue: int = 0 setget setSeed
export(int, 2, 10000, 1) var resolution: int = 20 setget setResolution
export(float) var radius: float = 1 setget setRadius
export(Resource) var shapeGenerator

var planet: Spatial

func init(var _planet):
	self.planet = _planet
	shapeGenerator.init(_planet)

func onSettingsChanged():
	if !planet:
		return
	planet.generate()

func setSeed(var new: int):
	seedValue = new
	onSettingsChanged()

func setResolution(var new: int):
	resolution = new
	onSettingsChanged()

func setRadius(var new: float):
	radius = new
	onSettingsChanged()
