# Generates a plain sphere shape.
tool
extends ShapeGenerator

class_name PlainShapeGenerator


func getUnscaledElevation(var pointOnUnitSphere: Vector3) -> float:
	return 0.0
