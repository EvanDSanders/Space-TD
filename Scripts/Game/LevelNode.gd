@tool
extends Sprite2D
class_name CampaignMapNode 
@onready var Center: Sprite2D = $Center

enum Icons {Locked, Next, Complete, BonusLocked, BonusOpen, BonusComplete}

var targScale : float = 0.6
@export var Icon : Icons = Icons.Locked:
	set(i):
		Icon = i
		self.texture = load({
				Icons.Locked: "res://Vectors/Game/Level Locked.svg",
				Icons.Next: "res://Vectors/Game/Level Next.svg",
				Icons.Complete: "res://Vectors/Game/Level Complete.svg",
				Icons.BonusLocked: "res://Vectors/Game/Bonus Locked.svg",
				Icons.BonusOpen: "res://Vectors/Game/Bonus Next.svg",
				Icons.BonusComplete: "res://Vectors/Game/Bonus Complete.svg",
			}[i])

		self.modulate = {
				Icons.Locked: Color.from_hsv(0.647, 0.612, 0.748, 0.729),
				Icons.Next: Color.from_hsv(0.56, 0.726, 0.949, 1.0),
				Icons.Complete: Color.from_hsv(0.396, 0.717, 0.897, 1.0),
				Icons.BonusLocked: Color.from_hsv(0.597, 0.74, 0.77, 0.604),
				Icons.BonusOpen: Color.from_hsv(0.561, 0.73, 0.95, 0.659),
				Icons.BonusComplete: Color.from_hsv(0.397, 0.72, 0.9, 0.667),
			}[i]
		self.targScale = {
				Icons.Locked: 0.54,
				Icons.Next: 0.65,
				Icons.Complete: 0.6,
				Icons.BonusLocked: 0.54,
				Icons.BonusOpen: 0.65,
				Icons.BonusComplete: 0.6,
			}[i]

		match i:
			Icons.Locked, Icons.Next, Icons.Complete:
				if Center: Center.visible = true
			Icons.BonusLocked, Icons.BonusOpen, Icons.BonusComplete:
				if Center: Center.visible = false


@export var level : GameLevelResource

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Callable(func(): Icon = Icon).call_deferred()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	Center.rotation_degrees -= delta * 60
	if Center.rotation < -TAU:
		Center.rotation += TAU * 2

var Tw : Tween

func Scale(s:float):
	if Tw: Tw.kill()
	Tw = create_tween()
	Tw.tween_property(self, 'scale', Vector2(s, s), 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)

func _on_control_mouse_entered() -> void:
	Scale(targScale)


func _on_control_mouse_exited() -> void:
	Scale(0.5)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if level: Loader.Load(level)
