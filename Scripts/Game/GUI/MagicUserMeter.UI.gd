@tool
extends MarginContainer
class_name MagicUserMeter

signal onActivate(bool)

@onready var meter: Panel = $Meter
@onready var texture_rect: TextureRect = $MarginContainer/PanelContainer/TextureRect
@onready var arrow: Control = $Control/Control
@onready var status: Control = $Control/Status
var Tw : Tween
var CollapseTw : Tween
var _nodes_on := false
var isCollapsed := false

@export var showNodes: Array[NodePath]

@export var image: Texture2D:
	set(v):
		image = v
		_apply_image()

@export_group("Image Transform")
@export_custom(PROPERTY_HINT_LINK, "") var image_scale := Vector2.ONE:
	set(v):
		image_scale = v
		_apply_image_transform()

## Offset in pixels, added after the container lays out the image.
@export var image_offset := Vector2.ZERO:
	set(v):
		image_offset = v
		_apply_image_transform()
@export_group("")

@export var fuel := 100.0:
	set(v):
		fuel = clampf(v, 0.0, maxf(max_fuel, 0.0))
		_update_meter()

@export var max_fuel := 100.0:
	set(v):
		max_fuel = clampf( v, 0.0, 100.0 )
		fuel = fuel
		_update_meter()

@export var tired_cooldown := 2.0

@export_range(0.0, 1.0) var hue := 0.167:
	set(v):
		hue = v
		_update_hue()

@export_range(0.0, 1.0) var hue_max := 0.167:
	set(v):
		hue_max = v
		_update_hue()

@export var useRate := 0.8
@export var regenRate := 0.3
@export_range(0.0, 1.0) var tireRateMult := 0.2
@export_range(0.0, 1.0) var tireRecoverFac := 0.033

## When max fuel is below this and fuel hits zero, max fuel collapses to 0 and regen stops.
@export var collapse_threshold := 20.0
@export var collapse_time := 1.0

@export var button : StringName = 'Up'

const TIRED_HUE := 0.0

var isTired := false:
	set(v):
		isTired = v
		_update_hue()

var Fac := 1.0:
	set(v):
		Fac = v
		_apply_fac()

var FacMax := 1.0:
	set(v):
		FacMax = v
		_set_param('FacMax', v)
		_apply_fac()

var coolDown := 0.0

func _ready() -> void:
	var p := texture_rect.get_parent() as Container
	if p and not p.sort_children.is_connected(_apply_image_transform):
		p.sort_children.connect(_apply_image_transform)
	_apply_image()
	_apply_image_transform()
	_update_meter()
	_update_hue()
	_set_nodes_visible(false)


func _set_nodes_visible(on: bool) -> void:
	
	onActivate.emit(on)
	
	if on == _nodes_on:
		return
	_nodes_on = on
	if Tw: Tw.kill()
	if is_instance_valid(arrow):
		Tw = create_tween()
		if on:
			Tw.tween_property(arrow, ^'offset_transform_scale:x', 1.0, 0.05)
			Tw.set_loops()
			Tw.tween_interval(0.3)
			Tw.tween_property(arrow, ^'offset_transform_position:y', -50., 0.1)
			Tw.tween_property(arrow, ^'offset_transform_position:y', 0.0, 0.1)
		else:
			Tw.tween_property(arrow, ^'offset_transform_scale:x', 0.0, 0.05)
			Tw.tween_property(arrow, ^'offset_transform_position:y', 0.0, 0.0)

	for path in showNodes:
		var n := get_node_or_null(path) as Node3D
		if n:
			n.visible = on


func _apply_image_transform() -> void:
	if not is_node_ready() or not is_instance_valid(texture_rect):
		return
	texture_rect.pivot_offset = texture_rect.size * 0.5
	texture_rect.scale = image_scale
	var parent := texture_rect.get_parent() as Container
	if parent:
		texture_rect.position = _container_slot_position(parent) + image_offset


func _container_slot_position(parent: Container) -> Vector2:
	var m := parent as MarginContainer
	if m:
		return Vector2(
			m.get_theme_constant("margin_left"),
			m.get_theme_constant("margin_top"))
	return Vector2.ZERO


func _apply_image() -> void:
	if is_node_ready() and is_instance_valid(texture_rect):
		texture_rect.texture = image


func _set_param(param: StringName, value: Variant) -> void:
	if not is_node_ready() or not is_instance_valid(meter):
		return
	meter.set_instance_shader_parameter(param, value)


func _apply_fac() -> void:
	_set_param('Fac', Fac / FacMax if FacMax > 0.0 else 0.0)


func _update_hue() -> void:
	_set_param('Hue', TIRED_HUE if isTired else hue)
	_set_param('HueMax', TIRED_HUE if isTired else hue_max)
	if arrow: arrow.modulate = Color.from_hsv(TIRED_HUE if isTired else hue, 0.6, 1)


func _update_meter() -> void:
	if not is_node_ready():
		return
	Fac = fuel / 100.0
	FacMax = max_fuel / 100.0


func useEnergy(amt: float, tireFac: float = 0.2) -> float:
	var output: float = clamp(amt, 0, fuel)
	fuel -= output
	max_fuel -= output * clampf(tireFac, 0.0, 1.0)
	if fuel <= 0.0:
		isTired = true
		coolDown = tired_cooldown
		if max_fuel < collapse_threshold:
			_collapse()
	return output


func Boost(amt: float, boost: float) -> void:
	if isCollapsed:
		return
	max_fuel += boost
	fuel += amt


func _collapse() -> void:
	if isCollapsed:
		return
	status.visible = true
	isCollapsed = true
	isTired = true
	if CollapseTw: CollapseTw.kill()
	CollapseTw = create_tween()
	CollapseTw.tween_property(self, ^'max_fuel', 0.0, collapse_time)


func regenEnergy(amt: float, tireFac: float = 0.033) -> float:
	if isCollapsed:
		return 0.0
	var output: float = clamp(amt, 0, max_fuel - fuel)
	fuel += output
	max_fuel += output * clampf(tireFac, 0.0, 1.0)
	return output


func revive(tireFac: float = 0.5) -> void:
	isTired = false
	isCollapsed = false
	if CollapseTw: CollapseTw.kill()
	coolDown = 0.0
	max_fuel = 100.0 * clampf(tireFac, 0.0, 1.0)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if isTired:
		_set_nodes_visible(false)
		coolDown -= delta
		if coolDown <= 0.0:
			isTired = false
		return
		
	if Input.get_action_strength(button):
		useEnergy( useRate, tireRateMult )
		coolDown = 1.0
		_set_nodes_visible(not isTired)
	else:
		_set_nodes_visible(false)
		coolDown -= delta
		if coolDown < 0 and not isCollapsed:
			regenEnergy( regenRate, tireRecoverFac )
