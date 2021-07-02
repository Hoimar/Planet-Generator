tool
class_name TerrainCache

var cache : Dictionary
signal visit

func _init():
	pass

func save_patch(data:ArrayMesh, center : Vector3):
	cache[center] = data

func get_cached(center : Vector3):
	
	if cache.has(center):
		return cache[center]
