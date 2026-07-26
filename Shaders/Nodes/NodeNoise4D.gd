@tool
extends VisualShaderNodeCustom
class_name VisualShaderNodeFMB4D


func _get_name():
	# This must be a valid identifier and should follow PascalCase naming conventions.
	# The name must start with a letter, and spaces in the name are *not* allowed.
	return "Noise4Df"


func _get_category():
	# This must be a valid identifier and should follow PascalCase naming conventions.
	# The category must start with a letter, and spaces in the category are *not* allowed.
	return "NoiseNodes"


func _get_description():
	return "4D Fbm Noise"


func _init():
	set_input_port_default_value(0, Vector3.ZERO)
	set_input_port_default_value(1, 0.0)
	set_input_port_default_value(2, 1.0)
	set_input_port_default_value(3, 2.0)
	set_input_port_default_value(4, 0.5)
	set_input_port_default_value(5, 0.0)


func _get_return_icon_type():
	return VisualShaderNode.PORT_TYPE_SCALAR


func _get_input_port_count():
	return 6


func _get_input_port_name(port):
	match port:
		0:
			return "Position"
		1:
			return "W"
		2:
			return "Scale"
		3:
			return "Detail"
		4:
			return "Roughness"
		5:
			return "Distortion"
		_:
			push_error("Unknown port name: %d" % port)
			return ""
#//	vec3 pos, float iTime, float scale, float detail, float roughness, float distortion


func _get_input_port_type(port):
	match port:
		0:
			return VisualShaderNode.PORT_TYPE_VECTOR_3D
		1,2,3,4,5:
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
#ifndef ImportNoise4D
	#define ImportNoise4D
	#include "res://Shaders/Msic/Noise4D.gdshaderinc"
#endif
"""


func _get_code(input_vars, output_vars, _mode, _type):
	#return output_vars[0] + " = cnoise(vec3((%s.xy + %s.xy) * %s, %s)) * 0.5 + 0.5;" % [input_vars[0], input_vars[1], input_vars[2], input_vars[3]]
	return output_vars[0] + " = Noise4Df( %s, %s, %s, %s, %s, %s );" % [ input_vars[0], input_vars[1], input_vars[2], input_vars[3], input_vars[4], input_vars[5] ]


# vec3 c = Noise4Dc(input0, 1., .5, 7., .6, 0.);
#output0 = c.x;
#output1 = c.y;
#output2 = c.z;
#//	vec3 pos, float iTime, float scale, float detail, float roughness, float distortion
#
#






















pass
