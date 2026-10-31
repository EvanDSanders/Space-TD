extends Camera2D


@export var ZoomMin: float = 0.2
@export var ZoomMax: float = 1.0


enum NavMode { NONE, PAN }
var _nav_mode: NavMode

var Position : Vector2:
	set(p):
		
		var half = get_viewport().size / 2
		var ll = limit_left + ( half.x * ( (1 - zoom.x) + 1 ) )
		var lt = limit_top + ( half.y * ( (1 - zoom.x) + 1 ) )
		var lr = limit_right - ( half.x * ( (1 - zoom.x) + 1 ) )
		var lb = limit_bottom - ( half.y * ( (1 - zoom.x) + 1 ) )
		
		
		position = p.clamp( Vector2(ll, lt), Vector2(lr, lb) )
		Position = position
		
	get: return position 

func _pan(relative: Vector2) -> void:
	Position -= relative / zoom

func _dolly(factor: float) -> void:
	var new_zoom = clamp(zoom.x - factor * 0.1, ZoomMin, ZoomMax)
	zoom = Vector2(new_zoom, new_zoom)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_MIDDLE:
				_nav_mode = NavMode.PAN if event.pressed else NavMode.NONE
				get_viewport().set_input_as_handled()
			MOUSE_BUTTON_WHEEL_UP:
				_dolly(-event.factor)
				get_viewport().set_input_as_handled()
			MOUSE_BUTTON_WHEEL_DOWN:
				_dolly(event.factor)
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _nav_mode != NavMode.NONE:
		match _nav_mode:
			NavMode.PAN:
				_pan(event.relative)
		get_viewport().set_input_as_handled()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	Position += Vector2(Input.get_axis("Left", "Right"), Input.get_axis("Forward", "Backward")) * 500 * delta / zoom.x * 2
		
