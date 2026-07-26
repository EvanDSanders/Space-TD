@icon ("res://EditorIcons/destructibleShield.svg")
extends Destructible
class_name ShieldedDestructible

signal ShieldChange(float)

@export var ShieldMax := 0.
@onready var Shield := ShieldMax
@onready var ShieldPrior := ShieldMax
@export var ShieldColors : Gradient

var damageTime : float = 100
var wasGenerated := 0.


func debug():
	$"../Label".text = """HP: %f
Sh: %f
""" % [HP, Shield]


func Hit(damage: float, impulse := Vector3.ZERO, ignoreSheild := false) -> void:
	damageTime = 0
	if not ignoreSheild:
		Shield -= damage
		if Shield < 0:
			HP -= abs(Shield)
			Shield = 0
		_flashShield()
	else:
		HP -= damage

	_afterHit(impulse)

	if ShieldMax >= 0.2 and not is_equal_approx(Shield, ShieldPrior):
		ShieldPrior = Shield
		ShieldChange.emit(Shield)
		Parent.writeShader( ShieldColors.sample(G.remap(0, ShieldMax, 0, 1, Shield)), "StarShipShieldC" )

	if Parent.has_method("writeShader") and is_zero_approx(Shield):
		Parent.writeShader( Color.BLACK, "StarShipShieldC" )


func Generate(amt: float):
	Shield += amt
	Shield = clampf(Shield, 0, ShieldMax)

	if not is_equal_approx(Shield, ShieldPrior):
		ShieldPrior = Shield
		ShieldChange.emit(Shield)
		if Parent.has_method("writeShader"):
			Parent.writeShader( ShieldColors.sample(G.remap(0, ShieldMax, 0, 1, Shield)), "StarShipShieldC" )

	if is_zero_approx(Shield):
		Parent.writeShader( Color.BLACK, "StarShipShieldC" )


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if Parent.has_node("ManaStore") and isAlive and ShieldMax >= 0.2 and damageTime >= 6:
		wasGenerated = delta * 5 * Parent.mana.pullMana( 0.8 * clamp(abs(Shield - ShieldMax), 0, 0.5) )*2
		Generate(wasGenerated)
	damageTime += delta
