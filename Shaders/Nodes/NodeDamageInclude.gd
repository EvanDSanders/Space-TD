@tool
extends VisualShaderNodeCustom
class_name VisualShaderNodeDamage


func _get_name():
	# This must be a valid identifier and should follow PascalCase naming conventions.
	# The name must start with a letter, and spaces in the name are *not* allowed.
	return "DamageTextureOverlay"


func _get_category():
	# This must be a valid identifier and should follow PascalCase naming conventions.
	# The category must start with a letter, and spaces in the category are *not* allowed.
	return "MyShaderNodes"


func _get_description():
	return "Classic Perlin-Noise-3D function (by Curly-Brace)"


func _init():
	set_input_port_default_value(2, 0.0)


func _get_return_icon_type():
	return VisualShaderNode.PORT_TYPE_SCALAR


func _get_input_port_count():
	return 2


func _get_input_port_name(port):
	match port:
		0:
			return "pos"
		1:
			return "scale"
		_:
			push_error("Unknown port name: %d" % port)
			return ""


func _get_input_port_type(port):
	match port:
		0:
			return VisualShaderNode.PORT_TYPE_VECTOR_3D
		1:
			return VisualShaderNode.PORT_TYPE_SCALAR
		_:
			push_error("Unknown port type: %d" % port)
			return VisualShaderNode.PORT_TYPE_MAX


func _get_output_port_count():
	return 1


func _get_output_port_name(_port):
	return "result"


func _get_output_port_type(_port):
	return VisualShaderNode.PORT_TYPE_SCALAR


func _get_global_code(_mode):
	return """
	"""


func _get_code(input_vars, output_vars, _mode, _type):
	#return output_vars[0] + " = cnoise(vec3((%s.xy + %s.xy) * %s, %s)) * 0.5 + 0.5;" % [input_vars[0], input_vars[1], input_vars[2], input_vars[3]]
	return output_vars[0] + " = ;" % [input_vars[0], input_vars[1]]



























pass
