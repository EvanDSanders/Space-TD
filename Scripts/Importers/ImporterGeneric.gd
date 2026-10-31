@tool # Needed so it runs in the editor.
extends EditorScenePostImport
class_name GenericImporter

var loadedMats = {}


var materials = {
	  "Scout Frame": "res://Materials/Evil/Scout.tres"
	, "ShipResources.Health": "res://Materials/GUI/Health.UI.tres"
	, "ShipResources.Mana": "res://Materials/GUI/Mana.UI.tres"
	, "ShipResources.Shield": "res://Materials/GUI/Shield.UI.tres"
	, "ShipResources.LED": "res://Materials/GUI/ResourcesLED.UI.tres"
	, "WarpShieldMat": "res://Materials/Friendlies/StationWarpShield.tres"
	, "Engine Crystal": "res://Materials/Friendlies/StarShip Engine Crystal.tres"
	#, "Prospector.Frame": "res://Materials/Common/DamagedMetal.tres"
	#, "Prospector.Frame": 
	, "Prospector.WarpGlass": "res://Materials/Friendlies/ProspectorGlass.tres"
	, "MegaShield": "res://Materials/Friendlies/Ship/MegaShield.tres"
	, "Fighter Thrust": "res://Materials/Friendlies/StationShip/Fighter Thrust.tres"
	, "Fighter Frame": "res://Materials/Friendlies/StationShip/SyntheticHull.tres"
}



func materialLoader(materialName:String) -> Material:
	if not materials.has(materialName): return null
		
	var mat = load(materials[materialName])
	loadedMats[materialName] = mat
	
	return mat


func _post_import(scene):
	print("Importing! ", scene.name)
	# Override Blender materials with Godot ones
	if scene.find_child("Origin ShipResources"):
		for I in scene.find_children("*", "VisualInstance3D"):
			I.set_layer_mask_value(1, false)
			I.set_layer_mask_value(10, true)
			
	
	for each: MeshInstance3D in scene.find_children("*", "MeshInstance3D"):
		#each.material_overlay = DamageMaterial
		print(each.name)
		# Get mesh from mesh instance
		var mesh: Mesh = each.mesh
		# For each mesh material:
		for x in range( mesh.get_surface_count() ):
			var mat = mesh.surface_get_material(x)
			if mat == null:
				continue
			
			var _mat := materialLoader(mat.resource_name)
			if  _mat:
				mesh.surface_set_material( x, _mat )
	
	
	for each: Node3D in scene.find_children("*"):
		print(each.name)
		
		if each.has_meta("extras"):
			print(each.name, " Has Extras ", each.get_meta("extras"))

			var meta : Dictionary = each.get_meta("extras")
			if meta.has("StationShip Engine") and meta["StationShip Engine"]:
				
				print(each.name, " Has StationShip Engine ", meta["StationShip Engine"])
				var engine := preload("res://Scenes/StationShips/StationShip Engine.tscn").instantiate()
				engine.transform = Transform3D.IDENTITY
				#each.get_parent_node_3d().add_child(engine)
				each.add_child(engine)
				engine.owner = scene
				#var name = each.name
				#each.name += ".old"
				#engine.name = name
				#engine.global_transform = each.global_transform
				#each.queue_free()
		
	return scene # remember to return the imported scene
