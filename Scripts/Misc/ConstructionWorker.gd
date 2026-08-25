
extends Node
class_name ConstructionWorker

@onready var Parent : Node3D = $".."

@onready var health : Destructible = Parent.health
@onready var mana : ManaStore = Parent.mana

@onready var oldManaMax : float
@onready var oldGenRate : float

var startHP : float = 0.1

var Meter : DialPin

func _ready() -> void:
	self.Parent.constructor = self
	health.HP = startHP
	oldManaMax = mana.ManaMax
	oldGenRate = mana.generationRate
	mana.ManaMax = 0
	mana.generationRate = 0
	
	Meter = Pins.Register(Parent, Pins.Type.Dial)
	Meter.max = health.HP
	Meter.value = 0
	Meter.setColor(Color.SANDY_BROWN)
	Meter.name = "MakerDialPin"
	

func _finished():
	mana.ManaMax = oldManaMax
	mana.Meter.max = oldManaMax
	mana.generationRate = oldGenRate
	Meter.queue_free()
	self.queue_free()

func _physics_process(delta: float) -> void:
	health.Heal( Linker.pullMana( clamp(abs(health.HP - health.HPMax), 0, 2*delta), self.mana )*20 )
	Meter.value = health.HP
	Meter.max = health.HPMax

	if is_equal_approx(health.HP, health.HPMax):
		_finished() 
