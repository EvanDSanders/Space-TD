@icon("res://EditorIcons/pinBoard.svg")
extends CanvasLayer
@onready var viewer_name: Label = $ViewerName


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


	
signal otherClicked

enum Type {Meter, Dial, Text, StructMenu}

const TypeDefs := [
	"res://Scenes/GUI/Pins/MeterPin.tscn",
	"res://Scenes/GUI/Pins/DialPin.tscn",
	"res://Scenes/GUI/Pins/TextPin.tscn",
	"res://Scenes/GUI/Pins/StructureMenuPin.tscn",
]

var FocusMouse : Node3D

var Meters : Dictionary[Node3D, Array]

var Focusing : Node3D
var priorFocus : Node3D
var FocusWidgits : Array[ScreenPin]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if G.Camera and G.Camera.toFollow:
		Focusing = G.Camera.toFollow
	elif FocusMouse:
		Focusing = FocusMouse
	else: 
		Focusing = null
	
	if Focusing != priorFocus:
		priorFocus = Focusing
		
		for each in FocusWidgits: if each: each.queue_free()
		FocusWidgits.clear()

		if Focusing and Meters.has(Focusing):
			var offset := Vector2(200, 50)
			for p : ScreenPin in Meters[Focusing]:
				if not is_instance_valid(p): continue
				if p is StructureMenuPin: continue

				var pin : ScreenPin = p.duplicate()
				self.add_child(pin)
				pin.parent = p.parent
				FocusWidgits.append(pin)
				pin.isPinBoard = true
				pin.offset = offset
				pin.set_meta("origin", p)
				offset.y += pin.size.y + 30
				if pin is MeterPin:
					pin.width = 250
					pin.height = 6
		

	viewer_name.visible = is_instance_valid(Focusing) and Focusing.get("ViewerName")
	if viewer_name.visible:
		viewer_name.text = "    " + Focusing.ViewerName
	if Focusing:
		for each in FocusWidgits:
			if not each.get("TrackableProps"): continue
			for prop in each.TrackableProps:
				#each.set(prop, each.get_meta("origin").get(prop))
				each.set_indexed(prop, each.get_meta("origin").get_indexed(prop))

func Clear():
	Meters.clear()
	FocusWidgits.clear()
	for each in get_children():
		if viewer_name == each: continue
		each.queue_free()
	

func Register(parent:Node3D, type := Type.Meter) -> ScreenPin:
	var pin := load(TypeDefs[type]).instantiate() as ScreenPin
	pin.parent = parent
	self.add_child(pin)
	if not Meters.has(parent):
		Meters[parent] = [pin]
	else:
		Meters[parent].append(pin)
		
		
	if pin is StructureMenuPin: otherClicked.connect(pin.dismis)
	
	return pin
