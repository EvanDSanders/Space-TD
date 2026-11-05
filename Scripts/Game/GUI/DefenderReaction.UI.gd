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
		"!!!!!!!",
		"Got it!",
		"Wooo!",
		"Take that!",
		"Ha!",
		"Haha!",
		"🎉",
	],
	exclaimType.HardHit: [
		"Ouch",
		"Ehhh",
		"Ooof",
		"...",
		"[----]",
	]
}

enum exclaimType {Reflect, HardHit}

static func exclaim(type: exclaimType, parent: Control):
	var txt = preload("res://Scenes/GUI/DefenderReaction.UI.tscn").instantiate()
	
	txt.text = Texts[type][ randi_range(0, Texts[type].size() - 1) ]
	
	if parent and parent.get('color'): txt.modulate = parent.get('color')
	txt.scale = Vector2.ONE * 0.01
	
	G.Main.add_child(txt)
	txt.global_position = parent.global_position
	
	var tw := txt.create_tween()
	var s = randf_range(-1, 1)
	tw.tween_property(txt, 'global_position', Vector2(s * 50, -120 + randf_range(0, -20)) + parent.global_position, 0.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(txt, 'rotation', s/2, 0.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(txt, 'scale', Vector2.ONE, 0.2).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.chain().tween_property(txt, 'scale', Vector2.ZERO, 0.2).set_delay(0.6)
	tw.tween_callback( txt.queue_free )
	
	
