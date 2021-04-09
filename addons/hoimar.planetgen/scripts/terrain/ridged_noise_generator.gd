tool
class_name RidgedNoiseGenerator
extends NoiseGenerator


func evaluate(var v: Vector3) -> float:
	var elevation: float = 1.0 - abs(_simplex.get_noise_3dv(center + v))
	return elevation * elevation * strength
