extends Control
class_name DrawDebug

var camera : Camera3D
var list : Array[Callable]
var parent: Node3D
var isDrawing := false

static func fabricate(_parent:Node3D) -> DrawDebug:
	var db = DrawDebug.new()
	db.parent = _parent
	_parent.add_child(db)
	return db

func pos(p:Vector3): return camera.unproject_position(p)


func drawPoint(a:Vector3, c := Color.WHITE_SMOKE):
	if not isDrawing: return
	list.append_array([
		#draw_line.bind(pos(a), pos(b), Color.WHITE_SMOKE),
		#draw_string.bind(get_theme_default_font(), pos(a*.5+b*.5), "%dm" % a.distance_to(b))
		draw_circle.bind(pos(a), 10, c, false, 2)
	])

func drawLine(a:Vector3, b:Vector3, c := Color.WHITE_SMOKE, thick := -1, text := true):
	if not isDrawing: return
	list.append(
		draw_line.bind(pos(a), pos(b), c, thick),
	)
	if text:
		list.append(
			draw_string.bind(get_theme_default_font(), pos(a*.5+b*.5), "%dm" % a.distance_to(b))
		)
	
func drawVector(origin:Vector3, vec:Vector3, c := Color.WHITE_SMOKE):
	if not isDrawing: return
	list.append_array([
		draw_line.bind(pos(origin), pos(vec), c),
		draw_string.bind(get_theme_default_font(), pos(origin*.5+vec*.5), "%d" % origin.distance_to(vec), 0, -1, 10, c * 0.5 + Color.WHITE_SMOKE * 0.5)
	])

func drawString(origin:Vector3, offset:Vector2, text:String, c := Color.WHITE_SMOKE):
	if not isDrawing: return
	list.append(
		draw_string.bind(get_theme_default_font(), pos(origin) + offset, text, 0, -1, 18, c * 0.5 + Color.WHITE_SMOKE * 0.5)
	)


func begin(): 
	isDrawing = true
	list.clear()
	camera = get_viewport().get_camera_3d()
	
func end(): 
	isDrawing = false
	self.queue_redraw()

func clear():
	list.clear()
	queue_redraw()

func _draw() -> void:
	for each in list:
		each.call()
