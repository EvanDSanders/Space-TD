@icon ("res://EditorIcons/destructible.svg")
extends Node
class_name Destructible

@onready var Parent = $".."
@onready var Meter : MeterPin  # = preload("res://Scenes/GUI/Waypoint.tscn").instantiate()

signal HPChange(float)
signal onDeath()

@export var isAlive : bool = true

@export var HPMax := 400.
@onready var HP := HPMax
@onready var HPPrior := HPMax

@export var color := Color.PALE_GREEN
@export var showMeter := true

var STw : Tween

@export var TargetType : E.TargetType = E.Friend

func debug():
	$"../Label".text = """HP: %f
""" % [HP]

var fireLoader := preload("res://Scenes/Misc/Fire.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void: # call_deferred("ready")
# func ready() -> void:
	Meter = Pins.Register(Parent, Pins.Type.Meter)
	Meter.max = HPMax
	Meter.value = HP
	Meter.setColor(Color.GREEN)
	Meter.VOffset = 10
	Meter.name = "HPMeterPin"

	if Parent.has_node("CursorDialogue"):
		Parent.get_node("CursorDialogue").attachMeter(Meter)
	
	E.Register(Parent, TargetType)
	onDeath.connect(E.UnRegister.bind(Parent, TargetType))
	
	

func Hit(damage: float, impulse := Vector3.ZERO, ignoreSheild := false) -> void:
	HP -= damage
	if not ignoreSheild:
		_flashShield()
	_afterHit(impulse)
	if Meter and showMeter: Meter.value = HP
	if Parent.has_method("writeShader"):
		Parent.writeShader( Color.BLACK, "StarShipShieldC" )


# Flashes the shield-hit shader effect. Shared with ShieldedDestructible, which
# also flashes on every non-ignored hit regardless of whether the shield absorbed it.
func _flashShield() -> void:
	if Parent.has_method("writeShader"):
		if STw: STw.kill()
		STw = create_tween()
		STw.tween_method(Parent.writeShader.bind("StarShipShieldF"), 1., 0., 0.25)


# Shared HP/impulse/meter/death bookkeeping used by Hit() overrides.
func _afterHit(impulse: Vector3) -> void:
	HPChange.emit(HP)
	if Parent.has_method("apply_impulse"): Parent.apply_impulse(impulse)

	if HP <= 0 and self.isAlive:
		self.isAlive = false
		onDeath.emit()
		Meter.doHide()
		var fire = fireLoader.instantiate()
		Parent.add_child(fire)
		if Parent.has_method("destroy"):
			Parent.destroy()

	if HP > 0 and showMeter and Meter:
		Meter.doShow()


func Heal(amt: float):
	HP += amt
	HPChange.emit(HP)
	HP = clampf(HP, 0, HPMax)
	if Meter and showMeter: Meter.value = HP
	if showMeter and Meter:
		Meter.doShow()
