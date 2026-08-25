extends ScreenPin
class_name DialPin

var oldValue : float = -1

var value : float = 0.0:
	set(_value):
		value = _value
		if oldValue != value:
			oldValue = value
			doShow()
			queue_redraw()
		
var max   : float = 1.0:
	set(_max):
		max = _max
		value = value
		
var min   : float = 0.0:
	set(_min):
		min = _min
		value = value
		
var radius   : float = 100.0:
	set(_radius):
		radius = _radius
		value = value
		applySize()
		
func applySize(): 
	value = value
	queue_redraw()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	applySize()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	super(delta)

var Foreground : Color
var Background : Color

func _draw() -> void:
	var segmets : int = 5
	var arc : float
	arc = G.remap(min, max, 0, TAU, value)
		
	segmets += arc * 10
	draw_arc(Vector2.ZERO, 25, -PI/2, -PI/2 + arc, segmets, self.Foreground, 10)

# Color.CORNFLOWER_BLUE

func setColor(
		Foreground : Color,
		Background := Color.from_hsv(0.0, 0.0, 0.1, 1.0)
	):
	queue_redraw()
		
	self.Foreground = Foreground
	self.Background = Background
