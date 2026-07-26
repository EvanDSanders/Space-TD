
extends Node
class_name ConstructionWorker

@onready var Parent : Node3D = $".."

@onready var health : Destructible = Parent.health
@onready var mana : ManaStore = Parent.mana

@onready var oldManaMax : float
@onready var oldGenRate : float

func _ready() -> void:
	self.Parent.health.HP = 0.1
	self.Parent.constructor = self
	oldManaMax = mana.ManaMax
	oldGenRate = mana.generationRate
	mana.ManaMax = 0
	mana.generationRate = 0
	call_deferred('_ready2')
	
func _ready2():
	health.Meter.setBuilding(true)

func _finished():
	health.Meter.setBuilding(false)
	mana.ManaMax = oldManaMax
	mana.Meter.Meter.max_value = oldManaMax
	mana.generationRate = oldGenRate
	self.queue_free()

func _physics_process(delta: float) -> void:
	health.Heal( Linker.pullMana( clamp(abs(health.HP - health.HPMax), 0, 2*delta) )*20 )

	if is_equal_approx(health.HP, health.HPMax):
		_finished() 
