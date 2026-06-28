@tool # Needed so it runs in the editor.
extends EditorScenePostImport


func _post_import(scene):
	# Override Blender materials with Godot ones

	var ScoutMat : StandardMaterial3D = load("res://Materials/Evil/Scout.tres")

	for each: MeshInstance3D in scene.find_children("*", "MeshInstance3D"):
		#each.material_overlay = DamageMaterial

		# Get mesh from mesh instance
		var mesh: Mesh = each.mesh
		# For each mesh material:
		for x in range( mesh.get_surface_count() ):
			var mat = mesh.surface_get_material(x)
			if mat == null:
				continue
			if mat.resource_name == "Scout Frame":
				mesh.surface_set_material(x, ScoutMat)
		
		
	return scene # remember to return the imported scene
