extends ReferenceRect


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	return
	if mouseDown: queue_redraw()

func _draw() -> void:
	return
	var pos = get_viewport().get_mouse_position()
	if Input.is_action_pressed("LClick"):
		draw_line(pos - Vector2(5, 5), pos - Vector2(20, 30), Color.DODGER_BLUE, 2, true)
		
	if Input.is_action_pressed("RClick"):
		draw_line(pos - Vector2(-5, 5), pos - Vector2(-20, 30), Color.ORANGE, 2, true)
		
	if Input.is_action_pressed("MClick"):
		draw_circle(pos, 15, Color.GREEN, false, 2, true)


var mouseDown : bool = false


func _input(event: InputEvent) -> void:
	return
	if 	(  Input.is_action_pressed("LClick")
		or Input.is_action_pressed("RClick")
		or Input.is_action_pressed("MClick") 
	):
		mouseDown = true

	if   event.is_action_pressed("LClick"): queue_redraw()
	elif event.is_action_released("LClick"): queue_redraw()
	elif event.is_action_pressed("MClick"): queue_redraw()
	elif event.is_action_released("MClick"): queue_redraw()
	elif event.is_action_pressed("RClick"): queue_redraw()
	elif event.is_action_released("RClick"): queue_redraw()
		
		
		
