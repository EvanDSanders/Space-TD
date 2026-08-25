@tool
extends EditorScript





func _run() -> void:
	
	
	for x in range(2, 21):
		var mesh = IcoSphereMesh.new()
		mesh.edge_count = x
		mesh.update_mesh()
		ResourceSaver.save(mesh, "res://Objects/Meshes/Asteroids/e%d.tres" % x)
