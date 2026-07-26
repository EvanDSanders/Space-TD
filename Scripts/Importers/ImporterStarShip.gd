@tool # Needed so it runs in the editor.
extends EditorScenePostImport



func _post_import(scene):
	# Override Blender materials with Godot ones

	var EnginePostRegEx : RegEx = RegEx.create_from_string("(Engine.[A-D].[LR])|(Engine.A.I.[LR])")
	#var EnginePostRegEx : RegEx = RegEx.create_from_string("Engine.A.I.[LR]") # Engine.A.I.L

	var EngineTrailLoader = preload("res://Scenes/Ship/StarShipEngineTrail.tscn")
	
	
	
	var Bones = scene.find_child("Skeleton3D")
	for x in range(Bones.get_bone_count()):
		var BName : String = Bones.get_bone_name( x )

		if EnginePostRegEx.search(BName):
			print(BName)
			# And add mesh trails to them
			var trail: BoneAttachment3D = EngineTrailLoader.instantiate()
			Bones.add_child(trail)
			trail.owner = scene
			trail.bone_idx = x
				


	# Load the Engine material
	var FrameMetal : Material = load("res://Materials/Friendlies/StarShip Frame.tres")
	var EngMetal : Material = load("res://Materials/Friendlies/StarShip Engine.tres")
	var EngCrystal : Material = load("res://Materials/Friendlies/StarShip Engine Crystal.tres")
	var DamageMaterial : Material = load("res://Materials/Common/DamageTexture.tres")
	var ShieldMat : Material = load("res://Materials/Shield.tres")
	var EngTrail : Material = ShaderMaterial.new()
	
	EngTrail.shader = load("res://Scenes/Ship/StarShipEngineTrail.tres")

	for each: MeshInstance3D in scene.find_children("*", "MeshInstance3D"):
		if each.name != "Circle 019":
			each.material_overlay = ShieldMat

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
			if mat.resource_name == "_trail":
				mesh.surface_set_material(x, EngTrail)
				


	return scene # remember to return the imported scene
