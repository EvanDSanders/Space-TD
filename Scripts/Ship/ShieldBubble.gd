extends CharacterBody3D
class_name ShieldBubble

var isDeflecting = true
 
@onready var defender: MagicUserMeter = $"../../GUI Mount/Defender"

func _ready() -> void:
	disable_mode = CollisionObject3D.DISABLE_MODE_REMOVE

#func _physics_process(delta: float) -> void:
	

func onHit(damage): # hitter: CollisionObject3D):
	defender.useEnergy(0.5 + damage * 0.01)


func onParry():
	defender.Boost(10, 25)
	G.setGameSpeed(0.2)
	G.Main.create_tween().tween_method( G.setGameSpeed , 0.1, 1.0, 0.3 ).set_delay(0.2)


func _on_defender_on_activate(on: bool) -> void:
	if on:
		process_mode = Node.PROCESS_MODE_INHERIT
	else:
		process_mode = Node.PROCESS_MODE_DISABLED
