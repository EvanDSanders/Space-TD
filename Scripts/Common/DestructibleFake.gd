@icon ("res://EditorIcons/destructible.svg")
extends Destructible
class_name DestructibleFake


func debug(): pass


# Called when the node enters the scene tree for the first time.
func _ready() -> void: # call_deferred("ready")
	pass
	
	

func Hit(damage: float, impulse := Vector3.ZERO, ignoreSheild := false) -> void:
	$"..".onHit(damage)


# Flashes the shield-hit shader effect. Shared with ShieldedDestructible, which
# also flashes on every non-ignored hit regardless of whether the shield absorbed it.
func _flashShield() -> void:
	pass


# Shared HP/impulse/meter/death bookkeeping used by Hit() overrides.
func _afterHit(impulse: Vector3) -> void:
	pass


func Heal(amt: float):
	pass
