@tool
extends VisualShaderNodeCustom
class_name VisualShaderNodeMusgrave3D


func _get_name():
	return "Musgrave3Df"


func _get_category():
	return "NoiseNodes"


func _get_description():
	return "3D Musgrave Fractal Noise (Multifractal / fBM / Hybrid / Ridged / Hetero Terrain)"


func _init():
	set_input_port_default_value(0, Vector3.ZERO)
	set_input_port_default_value(1, 0.0)
	set_input_port_default_value(2, 5.0)
	set_input_port_default_value(3, 2.0)
	set_input_port_default_value(4, 0.5)
	set_input_port_default_value(5, 2.0)
	set_input_port_default_value(6, 0.0)
	set_input_port_default_value(7, 1.0)


func _get_input_port_count():
	return 8


func _get_input_port_name(port):
	match port:
		0:
			return "Position"
		1:
			return "Type"
		2:
			return "Scale"
		3:
			return "Detail"
		4:
			return "Roughness"
		5:
			return "Lacunarity"
		6:
			return "Offset"
		7:
			return "Gain"
		_:
			push_error("Unknown port name: %d" % port)
			return ""
#	Type: 0 = Multifractal, 1 = fBM, 2 = Hybrid Multifractal,
#	3 = Ridged Multifractal, 4 = Hetero Terrain (matches Blender's
#	SHD_MUSGRAVE_* enum order).


func _get_input_port_type(port):
	match port:
		0:
			return VisualShaderNode.PORT_TYPE_VECTOR_3D
		1, 2, 3, 4, 5, 6, 7:
			return VisualShaderNode.PORT_TYPE_SCALAR
		_:
			push_error("Unknown port type: %d" % port)
			return VisualShaderNode.PORT_TYPE_MAX


func _get_output_port_count():
	return 1


func _get_output_port_name(_port):
	return "Fac"


func _get_output_port_type(_port):
	return VisualShaderNode.PORT_TYPE_SCALAR


func _get_global_code(_mode):
	return """
#ifndef ImportMusgrave3D
	#define ImportMusgrave3D
	#include "res://Shaders/Msic/Musgrave3D.gdshaderinc"
#endif
"""


func _get_code(input_vars, output_vars, _mode, _type):
	return output_vars[0] + " = Musgrave3Df( %s, %s, %s, %s, %s, %s, %s, %s );" % [
		input_vars[0], input_vars[1], input_vars[2], input_vars[3],
		input_vars[4], input_vars[5], input_vars[6], input_vars[7]
	]
