extends CharacterBody3D
class_name ShieldBubble

var isDeflecting = true
@onready var shield: MeshInstance3D = $"../Shield"

@onready var defender: MagicUserMeter = $"../../GUI Mount/Defender"
var Tw : Tween

var killBossMode := false

func _ready() -> void:
	disable_mode = CollisionObject3D.DISABLE_MODE_REMOVE
	process_mode = Node.PROCESS_MODE_INHERIT
	

#func _physics_process(delta: float) -> void:
	

func onHit(damage): # hitter: CollisionObject3D):
	defender.useEnergy(0.5 + damage * 0.01)


func onParry(pos: Vector3 = Vector3.ZERO):
	
	G.spawnExplosion(G.ExplType.Magic, self, self, 1.0, pos, true)
	if killBossMode:
		$"../FinalShield".visible = false
	
	defender.Boost(10, 25)
	G.setGameSpeed(0.2)
	G.Main.create_tween().tween_method( G.setGameSpeed , 0.1, 1.0, 0.3 ).set_delay(0.2)


var Brightness := 0.0:
	set(v): 
		Brightness = v
		shield.get_active_material(0).set_shader_parameter('Brightness', v)
		
var DeflectPow := 0.0:
	set(v): 
		DeflectPow = v
		shield.get_active_material(0).set_shader_parameter('DeflectPow', v)
		#ShaderMaterial.new().set_shader_parameter()

var state := false
func _on_defender_on_activate(on: bool) -> void:
	if state == on: return
	
	state = on
	
	if on:
		if killBossMode: KillBossMove(); return
		$CollisionShape3D.debug_color = Color.ANTIQUE_WHITE
		DeflectPow = 1.0
		Brightness = 0.0
		isDeflecting = false
		if Tw: Tw.kill()
		print('ON')
		Tw = G.Main.create_tween()
		Tw.tween_property(self, 'Brightness', 10.0, 0.2)
		Tw.parallel().tween_callback(func():
			$CollisionShape3D.debug_color = Color.YELLOW
			process_mode = Node.PROCESS_MODE_INHERIT
			#(func(): $CollisionShape3D.disabled = false).call_deferred()
			isDeflecting = true
		).set_delay(0.1)
		Tw.chain().tween_property(self, 'Brightness', 5.0, 0.3).set_delay(0.1)
		Tw.parallel().tween_property(self, 'DeflectPow', 0.0, 0.03).set_delay(0.1)
		Tw.chain().tween_callback(func():
			isDeflecting = false
		)
		
		
	else:
		print('OFF')
		
		process_mode = Node.PROCESS_MODE_DISABLED
		#(func(): $CollisionShape3D.disabled = true).call_deferred()
		$CollisionShape3D.debug_color = Color.RED
		isDeflecting = false
		
		if Tw: Tw.kill()
		Tw = G.Main.create_tween()
		Tw.tween_property(self, 'Brightness', 0.0, 0.15)
		

func KillBossMove():
	isDeflecting = true
	$"../FinalShield".visible = true
	$CollisionShape3D.debug_color = Color.YELLOW
	process_mode = Node.PROCESS_MODE_INHERIT
