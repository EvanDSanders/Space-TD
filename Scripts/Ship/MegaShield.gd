extends StaticBody3D


@export  var maxShots :  int = 3
@onready var    Shots := maxShots

@onready var timer: Timer = $Timer

@onready var mount: Node3D = G.StarShip.MegaShieldMount
@onready var pivot: Node3D = mount.get_parent_node_3d()

var usable := true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	G.MegaSheild = self
	self.reparent(G.StarShip.MegaShieldMount, false)
	timer.timeout.connect(retract)
	retract()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	
	if not is_instance_valid(G.MegaLaser): return
	
	pivot.look_at(G.MegaLaser.global_position)
	pivot.rotation_degrees.x = 0
	pivot.rotation_degrees.z = 0
	
	if Input.is_action_just_pressed("Up") and timer.is_stopped():
		print(Shots)
		if Shots > 0:
			deploy()
		else:  
			failure()

func hit():
	Shots -= 1;
	timer.stop()
	retract()

func retract():
	$MegaShield.visible = false
	timer.stop()
	set_collision_layer_value(21, false)
	

func deploy():
	$MegaShield.visible = true
	set_collision_layer_value(21, true)
	timer.start()
	
	
func failure():
	$GPUParticles3D.restart()
	$AudioStreamPlayer3D.play()
