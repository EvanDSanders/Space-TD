@tool # Needed so it runs in the editor.
extends EditorScenePostImport


func _post_import(scene):
	# Override Blender materials with Godot ones
	
	# Load the Engine material
	var material : ShaderMaterial = load("res://Materials/StarShip Engine.tres")
	
	for each: MeshInstance3D in scene.find_children("*", "MeshInstance3D"):
		
		# Get mesh from mesh instance
		var mesh: Mesh = each.mesh
		# For each mesh material:
		for x in range( mesh.get_surface_count() ):
			# If material is engine material "Material.002"
			if mesh.surface_get_material(x).resource_name == "Material.002":
				# Then set it to this engine material.
				mesh.surface_set_material(x, material)
	
	
	return scene # remember to return the imported scene
