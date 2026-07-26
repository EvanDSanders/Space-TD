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
}



func materialLoader(materialName:String) -> Material:
	if not materials.has(materialName): return null
		
	var mat = load(materials[materialName])
	loadedMats[materialName] = mat
	
	return mat


func _post_import(scene):
	# Override Blender materials with Godot ones
	if scene.find_child("Origin ShipResources"):
		for I in scene.find_children("*", "VisualInstance3D"):
			I.set_layer_mask_value(1, false)
			I.set_layer_mask_value(10, true)
			

	for each: MeshInstance3D in scene.find_children("*", "MeshInstance3D"):
		#each.material_overlay = DamageMaterial

		# Get mesh from mesh instance
		var mesh: Mesh = each.mesh
		# For each mesh material:
		for x in range( mesh.get_surface_count() ):
			var mat = mesh.surface_get_material(x)
			if mat == null:
				continue
			#if mat.resource_name == "Scout Frame":
				#mesh.surface_set_material(x, ScoutMat)
				
			#mesh.surface_set_material(x, WarpShieldMat)
			
			var _mat := materialLoader(mat.resource_name)
			if  _mat:
				mesh.surface_set_material( x, _mat )
				
			
		
		
	return scene # remember to return the imported scene
