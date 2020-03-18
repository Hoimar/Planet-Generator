extends Spatial

var noise: OpenSimplexNoise

onready var planet = $Planet
onready var org_mesh: Mesh = planet.mesh.duplicate(true)
onready var spn_seed = $gui/PanelContainer/GridContainer/spn_seed
onready var spn_water = $gui/PanelContainer/GridContainer/spn_water
onready var spn_influence = $gui/PanelContainer/GridContainer/spn_influence

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	spn_seed.value = randi()
	generate()

func generate():
	noise = OpenSimplexNoise.new()
	noise.seed = spn_seed.value
	noise.octaves = 4.0
	noise.period = .3
	noise.persistence = 0.8

	var surf: MeshDataTool = MeshDataTool.new()
	var array_mesh = ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, org_mesh.get_mesh_arrays())
	var result: int = surf.create_from_surface(array_mesh, 0)
	if result != OK:
		print("Error while creating MeshDataTool, exiting. Error: %d" % [result])
		return
	
	var influence = org_mesh.radius*spn_influence.value/100
	var water_level = spn_water.value
	
	for i in range(0, surf.get_vertex_count()):
		var v: Vector3 = surf.get_vertex(i)
		
		var value = noise.get_noise_3dv(v)
		if value > water_level:
			v += v.normalized() * value * influence
		else:
			pass #v += v.normalized() * influence
		surf.set_vertex(i, v)
	
	var min_dist = 0.9 #radius-1/radius
	var max_dist = 1.1 #radius+1/radius
	
	for i in range(surf.get_vertex_count()):
		var v = surf.get_vertex(i)
		var dist = v.length() 
		var dist_normalized = range_lerp(dist, min_dist, max_dist, 0, 1) # bring dist to 0..1 range
		
		var uv = Vector2(dist_normalized, 0)
		surf.set_vertex_uv(i, uv)
		
	# recalculate face normals (TODO smooth them!)
	for i in range(surf.get_face_count()):
		
		var v1i = surf.get_face_vertex(i,0)
		var v2i = surf.get_face_vertex(i,1)
		var v3i = surf.get_face_vertex(i,2)
		
		var v1 = surf.get_vertex(v1i)
		var v2 = surf.get_vertex(v2i)
		var v3 = surf.get_vertex(v3i)
		
		# calculate normal for this face
		var norm = -(v2 - v1).normalized().cross((v3 - v1).normalized()).normalized()
		
		surf.set_vertex_normal(v1i, norm)
		surf.set_vertex_normal(v2i, norm)
		surf.set_vertex_normal(v3i, norm)
	
	# commit the mesh
	var mmesh = ArrayMesh.new() 
	surf.commit_to_surface(mmesh)
	planet.mesh = mmesh
	planet.mesh.surface_set_material(0, org_mesh.surface_get_material(0))
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	planet.rotation.y += PI / (360*2)

func _on_btn_generate_pressed():
	generate()
