extends ScreenPin
class_name TextPin

@onready var label: Label = $Label

var text : String:
	set(t):
		label.text = t
	get():
		return label.text

func setColor(
		Foreground : Color,
		Background := Color.TRANSPARENT
	):
		label.add_theme_color_override("font_color", Foreground)
		label.add_theme_color_override("font_outline_color", Background)
		if Background != Color.TRANSPARENT:
			label.add_theme_constant_override("outline_size", 2)
		else:
			label.add_theme_constant_override("outline_size", 0)


var textSize : int :
	set(s): label.add_theme_font_size_override('font_size', s)
