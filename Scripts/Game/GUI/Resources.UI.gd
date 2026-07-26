extends Control


@onready var StarShip = $"../../Friendlies/The Star Ship"
@onready var crystalCounter: Label = $"Label"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	call_deferred("_ready2")

func _ready2():
	StarShip.mana.pushMana(1000)
	StarShip.health.Heal(1000)


func setCrystals(amt:int): 
	# print("setC:", amt)
	crystalCounter.text = "%d" % amt

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
