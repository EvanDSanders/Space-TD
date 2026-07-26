@tool
extends VisualShaderNodeCustom
class_name VisualShaderNodeBump


func _get_name():
	return "Bump"


func _get_category():
	return "VectorNodes"


func _get_description():
	return "Perturbs a normal using a height field derivative (Blender Bump node equivalent)."


func _init():
	set_input_port_default_value(0, false)
	set_input_port_default_value(1, 1.0)
	set_input_port_default_value(2, 1.0)
	set_input_port_default_value(3, 0.0)
	set_input_port_default_value(4, Vector3(0.0, 0.0, 1.0))
	set_input_port_default_value(5, Vector3(1.0, 0.0, 0.0))


func _get_input_port_count():
	return 6


func _get_input_port_name(port):
	match port:
		0:
			return "Invert"
		1:
			return "Strength"
		2:
			return "Distance"
		3:
			return "Height"
		4:
			return "Normal"
		5:
			return "Tangent"
		_:
			push_error("Unknown port name: %d" % port)
			return ""


func _get_input_port_type(port):
	match port:
		0:
			return VisualShaderNode.PORT_TYPE_BOOLEAN
		1, 2, 3:
			return VisualShaderNode.PORT_TYPE_SCALAR
		4, 5:
			return VisualShaderNode.PORT_TYPE_VECTOR_3D
		_:
			push_error("Unknown port type: %d" % port)
			return VisualShaderNode.PORT_TYPE_MAX


func _get_output_port_count():
	return 1


func _get_output_port_name(_port):
	return "Normal"


func _get_output_port_type(_port):
	return VisualShaderNode.PORT_TYPE_VECTOR_3D


func _get_global_code(_mode):
	return ""


func _get_code(input_vars, output_vars, _mode, _type):
	var invert = input_vars[0]
	var strength = input_vars[1]
	var distance = input_vars[2]
	var height = input_vars[3]
	var normal_in = input_vars[4]
	var tangent = input_vars[5]
	var normal_out = output_vars[0]

	var code = ""
	code += "vec3 bitangent = cross(%s, %s);\n" % [normal_in, tangent]
	code += "float dHdx = dFdx(%s) * %s;\n" % [height, distance]
	code += "float dHdy = dFdy(%s) * %s;\n" % [height, distance]
	code += "float dir = %s ? -1.0 : 1.0;\n" % invert
	code += "vec3 surface_normal = normalize(%s + dir * (dHdx * %s + dHdy * bitangent));\n" % [normal_in, tangent]
	code += "%s = normalize(mix(%s, surface_normal, clamp(%s, 0.0, 1.0)));\n" % [normal_out, normal_in, strength]

	return code
