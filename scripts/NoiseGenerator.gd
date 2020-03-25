tool
extends Resource

class_name NoiseGenerator

export var useFirstAsMask: bool setget setUseFirstAsMask
export var seedValue: int setget setSeedValue
export var strength: float setget setStrength   # Scale of the noise values
export var octaves: int = 4 setget setOctaves
export(float) var period: float = 0.03 setget setPeriod
export var persistence: float = 0.6 setget setPersistence

var simplex: OpenSimplexNoise
var planet: Spatial

func updateSettings():
	simplex = OpenSimplexNoise.new()
	simplex.seed = seedValue
	simplex.octaves = octaves
	simplex.period = period
	simplex.persistence = persistence
	if planet:
		planet.generate()

func evaluate(var v: Vector3):
	return simplex.get_noise_3dv(v) * strength

func setSeedValue(var new):
	seedValue = new
	updateSettings()

func setStrength(var new):
	strength = new
	updateSettings()

func setOctaves(var new):
	octaves = new
	updateSettings()

func setPeriod(var new):
	period = new
	updateSettings()

func setPersistence(var new):
	persistence = new
	updateSettings()

func setUseFirstAsMask(var new):
	useFirstAsMask = new
	updateSettings()
