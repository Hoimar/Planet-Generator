tool
class_name NoiseGenerator
extends Resource

export var enabled: bool = true setget setEnabled
export var useFirstAsMask: bool setget setUseFirstAsMask
export var seedValue: int setget setSeedValue
export var strength: float setget setStrength   # Scale of the noise values
export var octaves: int = 4 setget setOctaves
export var period: float = 0.03 setget setPeriod
export var persistence: float = 0.6 setget setPersistence
export var center: Vector3 setget setCenter

var simplex: OpenSimplexNoise
var planet: Spatial


func init(var _planet):
	self.planet = _planet


func updateSettings():
	simplex = OpenSimplexNoise.new()
	simplex.seed = seedValue
	simplex.octaves = octaves
	simplex.period = period
	simplex.persistence = persistence
	if planet:
		planet.generate()


func evaluate(var v: Vector3) -> float:
	return simplex.get_noise_3dv(center + v) * strength


func setEnabled(var new):
	enabled = new
	updateSettings()


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


func setCenter(var new):
	center = new
	updateSettings()
