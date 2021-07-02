tool
class_name TerrainCache

var cache : Dictionary # { ArrayMesh : PoolIntArray([ dir: x,y,z  + offset: x,y ])  }
signal visit

func _init():
	pass#cache = {}

func save_patch(data:ArrayMesh, center : Vector3):
	cache[center] = data

func get_cached(center : Vector3):
	
	if cache.has(center):
		return cache[center]
