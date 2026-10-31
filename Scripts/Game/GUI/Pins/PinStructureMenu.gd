@icon("res://EditorIcons/pinMenu.svg")
extends ScreenPin
class_name StructureMenuPin

@onready var sell: Button = $Bar/Sell
@onready var upgrade: Button = $Bar/Upgrade

func _ready() -> void:
	super()
	upgrade.visible = false
	exitScreen.connect(dismis)


func forceShow(_null): pass

func clicked():
	print('Menu Clicked')
	forceShown = true
	

func dismis():
	print('Menu Dismissed')
	forceShown = false


func hasUpgrades():
	upgrade.visible = true
