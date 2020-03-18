extends Spatial

class_name NoiseGenerator

var simplex: OpenSimplexNoise
var seed_value: int

# Called when the node enters the scene tree for the first time.
func _init(var seed_value: int, var octaves: int, var period:float, var persistence: float):
	self.seed_value = seed_value
	simplex = OpenSimplexNoise.new()
	simplex.seed = seed_value
	simplex.octaves = octaves
	simplex.period = period
	simplex.persistence = persistence

func get_value(var x: float, var y: float):
	return simplex.get_noise_2d(x, y)
