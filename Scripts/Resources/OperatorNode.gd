extends Node
class_name OperatorNode

var ready_: Callable
var proc_:  Callable
var phys_:  Callable

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if ready_: ready_.call()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if proc_: proc_.call(delta)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if phys_: phys_.call(delta)
	
static func _stub(): pass

static func BindOperator(
			_ready_: Callable = _stub, 
			_process_: Callable = _stub, 
			_physics_process_: Callable = _stub
		) -> void:
	var op := OperatorNode.new()
	if _ready_ != _stub:			op.ready_ = _ready_
	if _physics_process_ != _stub:	op.proc_  = _physics_process_
	if _process_ != _stub:			op.phys_  = _process_
	G.Main.add_child(op)
