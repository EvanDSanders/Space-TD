@tool # Needed so it runs in the editor.
extends EditorScenePostImport


func _post_import(scene):
	# Override Blender materials with Godot ones

	# Load the Engine material
	var FrameMetal : StandardMaterial3D = load("res://Materials/Friendlies/StarShip Frame.tres")
	var EngMetal : ShaderMaterial = load("res://Materials/Friendlies/StarShip Engine.tres")
	var EngCrystal : ShaderMaterial = load("res://Materials/Friendlies/StarShip Engine Crystal.tres")
	var DamageMaterial : ShaderMaterial = load("res://Materials/Common/DamageTexture.tres")


	for each: MeshInstance3D in scene.find_children("*", "MeshInstance3D"):
		#each.material_overlay = DamageMaterial

		# Get mesh from mesh instance
		var mesh: Mesh = each.mesh
		# For each mesh material:
		for x in range( mesh.get_surface_count() ):
			var mat = mesh.surface_get_material(x)
			if mat == null:
				continue
			if mat.resource_name == "Frame":
				mesh.surface_set_material(x, FrameMetal)
			if mat.resource_name == "Engine Metal":
				mesh.surface_set_material(x, EngMetal)
			if mat.resource_name == "Engine Crystal":
				mesh.surface_set_material(x, EngCrystal)
				
				


	return scene # remember to return the imported scene
