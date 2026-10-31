@icon("res://EditorIcons/shipNavigator.svg")
extends Node3D
class_name ShipNavigator

@onready var TickID : int = randi_range(0, 20)
@export var TargType : E.TargetType = E.TargetType.Friend
@export var Parent : ShipBase
var Target : Vector3

@export var AI : ShipControllerBase
@export var UpRighter := ShipUpCorrector.new()
@export var Decorator : ShipDecorator

@onready var debug := DrawDebug.fabricate(self)

@export var Controllable := false
var ControlAI : ShipControllerBase


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	AI.Nav = self
	AI.Parent = Parent
	UpRighter.Nav = self
	UpRighter.Parent = Parent
	if Decorator:
		Decorator.Nav = self
		Decorator.Parent = Parent
	

var TurnRate : Vector3
var LinearRate : Vector3


func ControlStart():
	if not ControlAI:
		ControlAI = ShipOperatorControl.new()
		ControlAI.Nav = self
		ControlAI.Parent = Parent



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if not Parent.health.isAlive: debug.clear(); return
	
	debug.begin()
	
	debug.drawLine(self.global_position, Target)
	
	if (
		abs(Parent.linear_velocity.x) / 10 + 
		abs(Parent.linear_velocity.y) / 10 + 
		abs(Parent.linear_velocity.z) / 10 + 
		abs(Parent.angular_velocity.x) + 
		abs(Parent.angular_velocity.y) + 
		abs(Parent.angular_velocity.z) 
	) / 6 > 5:
		Parent.linear_velocity = Vector3.ZERO
		#Parent.global_rotation = Vector3.ZERO
		Parent.global_rotation.x = 0
		Parent.global_rotation.z = 0
		Parent.angular_velocity = Vector3.ZERO
		print("Instibility detected in %s! Motion reset." % Parent.name)
	
	var choise : ShipControllerBase.AIChoice
	
	if ControlAI and ( Parent.State == StationShip.SysState.Normal if Parent is StationShip else false ):
		choise = ControlAI.proc(delta)
	else:
		AI.target = Target
		choise = AI.proc(delta)
	choise = choise.add( UpRighter.proc(delta) )
	
	if Parent is StationShip and not Parent.usageImmune: Parent.energy.pullEnergy( choise.charge() )
	
	if Decorator: Decorator.proc(choise)
	
	debug.end()
