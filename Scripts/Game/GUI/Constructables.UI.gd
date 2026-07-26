extends Control

const CONSTRUCTABLES_PATH := "res://Scenes/Towers/Constructables.toml"

@onready var ButtonLoader = preload("res://Scenes/GUI/ConstructableButton.tscn")
@onready var TowerRow: HBoxContainer = $MarginContainer/HBoxContainer

@onready var Towers : Dictionary = TOML.parse_string(FileAccess.get_file_as_string(CONSTRUCTABLES_PATH))

@onready var Ranger : MeshInstance3D = G.Cursor.get_node('ScanRange')
@onready var Clearance : ShapeCast3D = Ranger.get_node('../Clearance')
@onready var MiningRange : ShapeCast3D = Ranger.get_node('../Miner')


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for TowerName in Towers:
		var T : Dictionary = Towers[TowerName]
		var B = ButtonLoader.instantiate()
		B.loadingScene = T["base"]
		B.buildingScene = T["scene"]
		B.data = T
		B.Parent = self
		TowerRow.add_child(B)
		var Tex : TextureRect = B.get_node("TextureRect")
		Tex.texture = DPITexture.create_from_string(FileAccess.get_file_as_string(T["icon"]))

		Ranger.set_instance_shader_parameter("isBuilding", true)
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



func _unhandled_input(event: InputEvent) -> void:
	if G.isBuilding:
		if event.is_action_pressed("LClick"):
			get_viewport().set_input_as_handled()
		elif event.is_action_released("LClick"):
			get_viewport().set_input_as_handled()
			
			if Clearance.is_colliding(): return
			
			if clickedButton.data["name"] == "Mining Laser":
				if not MiningRange.is_colliding(): return
			
			startBuild()
			
	


var clickedButton: ConstructableButton
var tower : Node3D

func _physics_process(delta: float) -> void:
	if G.isBuilding:
		Ranger.set_instance_shader_parameter("IsPlaceable", not Clearance.is_colliding())
		if clickedButton.data["name"] == "Mining Laser":
			Ranger.set_instance_shader_parameter("IsMinable", MiningRange.is_colliding())


func Build( caller: ConstructableButton ):
	Ranger.visible = true
	G.isBuilding = true
	clickedButton = caller
	
	Clearance.enabled = true
	
	var isMiner = clickedButton.data["name"] == "Mining Laser"
	MiningRange.enabled = isMiner
	Ranger.set_instance_shader_parameter("IsMiner", isMiner)
	
	Ranger.set_instance_shader_parameter("Range", clickedButton.data.trackRange)
	Ranger.set_instance_shader_parameter("LinkRange", clickedButton.data.linkRange)
	Ranger.set_instance_shader_parameter("SpaceRange", clickedButton.data.clearence)

	Clearance.shape.radius = clickedButton.data.clearence
	
	
	tower = load(caller.loadingScene).instantiate()
	
	G.Cursor.add_child(tower)


func startBuild():
	G.StarShip.crystal.pullCrystal(clickedButton.data["cost"])
	G.isBuilding = false
	tower.queue_free()
	Ranger.visible = false
	
	Clearance.enabled = false
	MiningRange.enabled = false
	
	var structure : Node3D = load(clickedButton.buildingScene).instantiate()
	
	G.Friendlies.add_child(structure)
	structure.global_position = G.Cursor.global_position
	
	structure.add_child( ConstructionWorker.new() )
	
	if Input.is_action_pressed("Boost"):
		Build
	
	
	
	
	
	
	
