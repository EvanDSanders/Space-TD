extends ManaStore
class_name ManaProxy

## A refrence to the [ManaStore] that this node is a proxy to.
## Must be set
@export var manaStore : ManaStore
@export var showLink := false

static var pos := 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void: # call_deferred("ready")
# func ready() -> void:
	assert( is_instance_valid(manaStore), "ManaProxy must have a ManaStore!\n" + str(get_stack()))

	Linker.Register(self)
	 
	G.schedule( Linker.ConnectDirect.bind(manaStore, self, showLink), 1 )

	ManaChange.connect(func(): Meter.value = Mana)
	tree_exiting.connect(Linker.Destroy.bind(self))
	
	DebugText = Pins.Register(Parent, Pins.Type.Text)
	DebugText.setColor(Color.LIGHT_BLUE, Color.DARK_BLUE)
	DebugText.text = "0"
	DebugText.textSize = 50


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void: pass



func pullMana(charge: float) -> float:
	return manaStore.pullMana(charge)

func pushMana(amt: float):
	return manaStore.pushMana(amt)
