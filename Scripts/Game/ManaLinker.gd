@icon("res://EditorIcons/manaLink.svg")
extends Node
#class_name ManaLinker

signal ManaChange(float)


@onready var StarShip: RigidBody3D = $"/root/Main/Friendlies/The Star Ship"
@onready var mana : ManaStore = StarShip.get_node("ManaStore")

func pullMana(charge: float) -> float:
	charge = clampf(charge, 0, mana.Mana)
	mana.Mana -= charge
	return charge


func pushMana(amt: float):
	mana.Mana += amt
	mana.Mana = clampf(mana.Mana, 0, mana.ManaMax)
	
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
