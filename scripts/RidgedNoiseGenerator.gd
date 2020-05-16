tool
extends NoiseGenerator

class_name RidgedNoiseGenerator

func evaluate(var v: Vector3) -> float:
	var elevation: float = 1.0 - abs(simplex.get_noise_3dv(center + v))
	return elevation * elevation * strength
