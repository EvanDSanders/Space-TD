@tool
extends Control
class_name Waypoint

## Some margin to keep the marker away from the screen's corners.
const MARGIN = 8

## If `true`, the waypoint sticks to the viewport's edges when moving off-screen.
@export var sticky: bool = true

@onready var camera := get_viewport().get_camera_3d()
@onready var Meter: ProgressBar = $ProgressBar
var isBuilding := false

var parent: Node3D
var Hide := true
var isForcedToShow := false

func setTimeout(time: float):
	$Timer.wait_time = time

func _ready() -> void:
	visible = false
	if parent == null:
		parent = get_parent() as Node3D
	assert(parent is Node3D, "The waypoint's parent node must inherit from Node3D.")
	
	$Timer.timeout.connect(doHide)
	

func doHide():
	if isForcedToShow: return
	self.Hide = true
	
func doShow(_discard = null):
	if isForcedToShow: return
	self.Hide = false
	$Timer.start()

func forceShow(isEnabled): 
	isForcedToShow = isEnabled
	if isEnabled and not $Timer.is_stopped():
		$Timer.stop()
	if not isEnabled: doShow()


func setBuilding(isItBuilding: bool = false):
	isBuilding = isItBuilding
	queue_redraw()
	#if isBuilding:
		#Meter.value_changed.connect(queue_redraw)
	#else: 
		#Meter.value_changed.disconnect(queue_redraw)

func _draw() -> void:
	if not Engine.is_editor_hint():
		if not isBuilding: return
		
	var segmets : int = 5
	var arc : float
	if not Engine.is_editor_hint():
		arc = G.remap(0, Meter.max_value, 0, TAU, Meter.value)
	else:
		arc = remap(.5, 0, 1, 0, TAU)
		
	segmets += arc * 10
	draw_arc(Vector2.ZERO, 25, -PI/2, -PI/2 + arc, segmets, Color.CORNFLOWER_BLUE, 10)
		

func _editorProc():
	queue_redraw()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint(): _editorProc(); return;
	if isBuilding: queue_redraw()
	
	if not parent: queue_free(); return;
	if not camera or not camera.current:
		# If the camera we have isn't the current one, get the current camera.
		camera = get_viewport().get_camera_3d()

	var parent_position: Vector3 = parent.global_transform.origin
	var camera_transform := camera.global_transform
	var camera_position := camera_transform.origin

	# We would use "camera.is_position_behind(parent_position)", except
	# that it also accounts for the near clip plane, which we don't want.
	var is_behind := camera_transform.basis.z.dot(parent_position - camera_position) > 0

	# Fade the waypoint when the camera gets close.
	var distance := camera_position.distance_to(parent_position)
	modulate.a = clamp(remap(distance, 0, 2, 0, 1), 0, 1 )

	var unprojected_position := camera.unproject_position(parent_position)
	# `get_size_override()` will return a valid size only if the stretch mode is `2d`.
	# Otherwise, the viewport size is used directly.
	var viewport_base_size: Vector2i = (
			get_viewport().content_scale_size if get_viewport().content_scale_size > Vector2i(0, 0)
			else get_viewport().size
		)
		
	#if visible:
		#self.offset_transform_position = Vector2(0, -G.remap(20, 600, 150, 10, distance))
		#var Sc = 1 # G.remap(100, 600, 1, .5, distance)
		#self.offset_transform_scale = Vector2(Sc, Sc)
		#$Label.text = str(distance) + "\n" + str(Sc)
		
	if not sticky:
		# For non-sticky waypoints, we don't need to clamp and calculate
		# the position if the waypoint goes off screen.
		position = unprojected_position
		visible = not is_behind and (not Hide or isForcedToShow)
		#visible = true
		return
		
	else: 
		visible = not Hide or isForcedToShow
		#visible = true
		

	# We need to handle the axes differently.
	# For the screen's X axis, the projected position is useful to us,
	# but we need to force it to the side if it's also behind.
	if is_behind:
		if unprojected_position.x < viewport_base_size.x / 2:
			unprojected_position.x = viewport_base_size.x - MARGIN
		else:
			unprojected_position.x = MARGIN

	# For the screen's Y axis, the projected position is NOT useful to us
	# because we don't want to indicate to the user that they need to look
	# up or down to see something behind them. Instead, here we approximate
	# the correct position using difference of the X axis Euler angles
	# (up/down rotation) and the ratio of that with the camera's FOV.
	# This will be slightly off from the theoretical "ideal" position.
	if is_behind or unprojected_position.x < MARGIN or \
			unprojected_position.x > viewport_base_size.x - MARGIN:
		var look := camera_transform.looking_at(parent_position, Vector3.UP)
		var diff := angle_difference(look.basis.get_euler().x, camera_transform.basis.get_euler().x)
		unprojected_position.y = viewport_base_size.y * (0.5 + (diff / deg_to_rad(camera.fov)))

	position = Vector2(
			clamp(unprojected_position.x, MARGIN, viewport_base_size.x - MARGIN),
			clamp(unprojected_position.y, MARGIN, viewport_base_size.y - MARGIN)
		)

	rotation = 0
	# Used to display a diagonal arrow when the waypoint is displayed in
	# one of the screen corners.
	var overflow := 0

	if position.x <= MARGIN:
		# Left overflow.
		overflow = int(-TAU / 8.0)
		rotation = TAU / 4.0
	elif position.x >= viewport_base_size.x - MARGIN:
		# Right overflow.
		overflow = int(TAU / 8.0)
		rotation = TAU * 3.0 / 4.0

	if position.y <= MARGIN:
		# Top overflow.
		rotation = TAU / 2.0 + overflow
	elif position.y >= viewport_base_size.y - MARGIN:
		# Bottom overflow.
		rotation = -overflow
