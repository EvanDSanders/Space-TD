extends Label
class_name DefenderReaction

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



static var Texts = {
	exclaimType.Reflect: [
		"Yeah!",
		"!!!!!",
		"Got it!",
		"Wooo!",
		"Take that!",
		"Ha!",
	],
	exclaimType.HardHit: [
		"Ouch",
		"Ehhh",
		"Ooof",
		"...",
	]
}

enum exclaimType {Reflect, HardHit}

static func exclaim(type: exclaimType, parent: Control):
	var txt = DefenderReaction.new()
	
	txt.text = Texts[type][ randi_range(0, Texts[type].size() - 1) ]
	
	G.Main.add_child(txt)
	txt.global_position = parent.global_position
	
	var tw := txt.create_tween()
	tw.tween_property(txt, 'global_position', Vector2(0, -50) + parent.global_position, 0.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	
