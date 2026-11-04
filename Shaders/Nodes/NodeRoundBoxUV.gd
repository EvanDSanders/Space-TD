@tool
extends VisualShaderNodeCustom
class_name VisualShaderNodeRoundBoxUV


func _init():
	set_input_port_default_value(1, Vector2(0.1, 0.1))
	set_input_port_default_value(2, Vector2(0.9, 0.9))
	set_input_port_default_value(3, Vector2(1, 1))
	set_input_port_default_value(4, Vector4(0.1, 0.1, 0.1, 1))
	set_input_port_default_value(5, Vector4(1, 1, 1, 1))
	set_input_port_default_value(6, 0.02)
	set_input_port_default_value(7, 0.1)


func _get_name():
	return "RoundBoxUV"


func _get_category():
	return "UINodes"


func _get_description():
	return "Rounded UV box defined by start/end corners, with fill and border colors. Outputs color and alpha."


func _get_return_icon_type():
	return VisualShaderNode.PORT_TYPE_VECTOR_3D


func _get_input_port_count():
	return 8


func _get_input_port_name(port):
	match port:
		0: return "uv"
		1: return "uv_start"
		2: return "uv_end"
		3: return "border_uv_scale"
		4: return "fill_color"
		5: return "border_color"
		6: return "border_size"
		7: return "radius"
		_: return ""


func _get_input_port_type(port):
	match port:
		0, 1, 2, 3:
			return VisualShaderNode.PORT_TYPE_VECTOR_2D
		4, 5:
			return VisualShaderNode.PORT_TYPE_VECTOR_4D
		_:
			return VisualShaderNode.PORT_TYPE_SCALAR


func _get_output_port_count():
	return 2


func _get_output_port_name(port):
	return "color" if port == 0 else "alpha"


func _get_output_port_type(port):
	return VisualShaderNode.PORT_TYPE_VECTOR_3D if port == 0 else VisualShaderNode.PORT_TYPE_SCALAR


func _get_global_code(_mode):
	return """
#ifndef ImportRoundBoxUV
	#define ImportRoundBoxUV
	#include "res://Shaders/UI/RoundBoxUV.gdshaderinc"
#endif
"""


func _get_code(input_vars, output_vars, _mode, _type):
	var uv: String = input_vars[0] if not input_vars[0].is_empty() else "UV"
	return """{
	vec4 _rb = RoundBoxUV(%s, %s, %s, %s, %s, %s, %s, %s);
	%s = _rb.rgb;
	%s = _rb.a;
}""" % [
		uv,
		input_vars[1], input_vars[2], input_vars[3],
		input_vars[4], input_vars[5], input_vars[6], input_vars[7],
		output_vars[0], output_vars[1],
	]
