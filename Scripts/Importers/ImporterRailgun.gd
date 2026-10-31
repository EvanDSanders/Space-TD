@tool # Needed so it runs in the editor.
extends EditorScenePostImport



func _post_import(scene):
	
	for x in range(21):
		var part : Node3D = preload("res://Objects/Friendlies/Railgun Segment.glb").instantiate()
		scene.add_child(part)
		part.owner = scene
		part.global_position.z = remap(x, 0, 20, -10, 10)
		
		print(x)
		
	return preload("res://Scripts/Importers/ImporterGeneric.gd").new()._post_import(scene)
