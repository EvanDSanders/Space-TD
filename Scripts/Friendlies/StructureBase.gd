extends StaticBody3D
class_name StructureBase3D

@export var ViewerName: String

@onready var health: Destructible = find_child("Destructible")
@onready var mana: ManaStore = find_child("ManaStore")
@onready var crystal: CrystalStore = find_child("CrystalStore")
@onready var cursorDialogue: CursorDialogue = find_child("CursorDialogue")
var constructor: ConstructionWorker

var menu : StructureMenuPin

@export var hasMenu: bool = true
@export var hasUpgrades: bool = true

func createMenu():
	if not hasMenu: return
	menu = Pins.Register(self, Pins.Type.StructMenu)
	if hasUpgrades:
		menu.hasUpgrades()
	
func _ready() -> void:
	createMenu()

func destroy():
	G.spawnExplosionAndFree(G.ExplType.Magic, self)

## Mana filled per second
@export var manaFill : float = 0.0
func fillMana(delta):
	self.mana.pushMana(  Linker.pullMana( clamp(manaFill * delta, 0, mana.ManaMax - mana.Mana ), self.mana)  )


#func _unhandled_input(event: InputEvent) -> void:
func _input_event(camera: Camera3D, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if constructor: return
	if cursorDialogue:
		cursorDialogue._unhandled_input_pass(event)
