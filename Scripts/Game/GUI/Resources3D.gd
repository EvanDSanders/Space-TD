@tool
extends Node3D


@onready var StarShip: RigidBody3D = $"../../../../Friendlies/The Star Ship"
@onready var ResourcesMount: Node3D = $"../.."

@onready var Health : ShieldedDestructible = StarShip.get_node("Destructible")
@onready var Mana : ManaStore = StarShip.get_node("ManaStore")
@onready var Crystals : CrystalStore = StarShip.get_node("CrystalStore")

@onready var Health3D: MeshInstance3D = $"ShipResources Health"
@onready var Mana3D: MeshInstance3D = $"ShipResources Mana"
@onready var Mana3D2: MeshInstance3D = $"ShipResources Mana2"

@onready var HealthLED: MeshInstance3D = $"ShipResources Health LED"
@onready var ManaLED: MeshInstance3D = $"ShipResources Mana LED"

@onready var Control2D := $"../../../../GUI Mount/ShipResources"

var HTw : Tween
var STw : Tween
var MTw : Tween

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for I in $"../../..".find_children("*", "VisualInstance3D"):
		I.set_layer_mask_value(1, false)
		I.set_layer_mask_value(10, true)
		
	call_deferred("_ready2")

var CTw : Tween
@onready var lerpC : float = Crystals.Crystals

func _ready2():
	Crystals.CrystalsChange.connect(func(amt:int):
		if CTw: CTw.kill()
		CTw = create_tween();
		CTw.tween_property(self, 'lerpC', float(amt), 0.5); CTw.parallel()
		CTw.tween_method(Control2D.setCrystals, round(lerpC), amt, 0.5)
	)

var c:=0.;


enum ShieldMode {Delay, Gen, Off, Full}
enum ManaMode {Gen, Full}

@export var shieldMode : ShieldMode = ShieldMode.Full
@onready var shieldModePrior := shieldMode


var Rate := 4.
var Max  := 6.

@export var editorSetInstance : bool = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	if Engine.is_editor_hint() and editorSetInstance:
		editorSetInstance = false
		_ready()
	
	
	if not Engine.is_editor_hint():
		if Health.damageTime < 6:
			self.shieldMode = ShieldMode.Delay
		elif Health.Shield < Health.ShieldMax - 0.01:
			self.shieldMode = ShieldMode.Gen
		else: 
			self.shieldMode = ShieldMode.Full
			
			
			
		
	if shieldMode != shieldModePrior:
		shieldModePrior = shieldMode
		c = 0
		match shieldMode:
			ShieldMode.Delay:		Rate = 1; Max = 6
			ShieldMode.Gen:			Rate = 6; Max = 6
			ShieldMode.Off:			Rate = 0; Max = 0
			ShieldMode.Full:		Rate = 0; Max = 0
		
	var i : int = floor(c)
	
	match shieldMode:
		ShieldMode.Delay:
			if not Engine.is_editor_hint():
				c = Health.damageTime
			
			
			if c < 1:
				i = 10 if int(c * 5) % 2 else -10
			else:
				i = int( remap(c, 1, 6, 0, 6) )
			
			for led in range(6):
				var lit = i < led
				HealthLED.set_instance_shader_parameter("LED%d" % led, Color.RED if lit else Color.BLACK )
			
		ShieldMode.Gen:
			if not Engine.is_editor_hint():
				Rate = Health.wasGenerated * 5 * 10 * 2.5
			for led in range(6):
				var lit: bool = i == led or (i+3)%6 == led
				HealthLED.set_instance_shader_parameter("LED%d" % led, Color.DODGER_BLUE if lit else Color.BLACK )
			
		ShieldMode.Off:
			for led in range(6):
				var lit: bool = led == 1 or led == 4
				HealthLED.set_instance_shader_parameter("LED%d" % led, Color.DARK_RED if lit else Color.BLACK )
			
		ShieldMode.Full:
			for led in range(6):
				var lit: bool = led == 1 or led == 4
				HealthLED.set_instance_shader_parameter("LED%d" % led, Color.DARK_BLUE if lit else Color.BLACK )
		
	c += delta * Rate
	if c >= Max: c = 0;


var HS := 1.
var SS := 1.
var MS := 1.

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	ResourcesMount.global_transform = StarShip.global_transform
	#
	#Health3D.scale.y = G.remap(0, Health.HPMax, 0, 1, Health.HP)
	#Health3D.set_instance_shader_parameter( "Scaled", G.remap(0, Health.HPMax, 0, 1, Health.HP) )
	#
	#Mana3D2.scale.y = G.remap(0, Mana.ManaMax, 0, 1, Mana.Mana)
	#Mana3D2.set_instance_shader_parameter( "Scaled", G.remap(0, Mana.ManaMax, 0, 1, Mana.Mana) )
	
	#$RigidBody3D.global_transform = $Node3D.global_transform
	
	var h = G.remap(0, Health.HPMax, 0, 1, Health.HP)
	var m = G.remap(0, Mana.ManaMax, 0, 1, Mana.Mana)
	
	if HTw: HTw.kill(); 
	HTw = create_tween();
	HTw.tween_property(self, "HS", h, abs(.1))
	
	if MTw: MTw.kill(); 
	MTw = create_tween();
	MTw.tween_property(self, "MS", m, abs(.1))
	
	Health3D.scale.y = HS
	Health3D.set_instance_shader_parameter( "Scaled", HS )
	
	Mana3D.scale.y = MS
	Mana3D.set_instance_shader_parameter( "Scaled", MS )
	
	
