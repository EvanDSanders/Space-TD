extends Control


@onready var health: ProgressBar = $VBox/Bars/Health
@onready var mana: ProgressBar = $VBox/Bars/Mana
@onready var crystals: Label = $VBox/CrystalsBox/Crystals

@onready var StarShip = $"../Friendlies/The Star Ship"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	health.max_value = StarShip.HPMax
	mana.max_value = StarShip.ManaMax
	
	StarShip.CrystalsChange.connect(updateCrystals)
	StarShip.ManaChange.connect(updateMana)
	StarShip.HPChange.connect(updateHP)
	
	call_deferred("_ready2")

func _ready2():
	StarShip.pushMana(1000)
	StarShip._heal(1000)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



func updateCrystals(amt):
	crystals.value = amt

func updateHP(amt):
	health.value = amt

func updateMana(amt):
	mana.value = amt
