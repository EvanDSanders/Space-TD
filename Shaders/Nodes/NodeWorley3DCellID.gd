@tool
extends VisualShaderNodeCustom
class_name VisualShaderNodeWorley3DCellID


func _init():
	set_input_port_default_value(1, Vector3(0, 0, 0))
	set_input_port_default_value(2, 5.0)
	set_input_port_default_value(3, 1.0)
	set_input_port_default_value(4, 0.0)


func _get_name():
	return "WorleyNoise3DCellID"


func _get_category():
	return "NoiseNodes"


func _get_description():
	return "3D Worley/Voronoi noise colored by cell ID instead of edge distance. Shares the same feature-point math as WorleyNoise3D so cell borders line up."


func _get_return_icon_type():
	return VisualShaderNode.PORT_TYPE_VECTOR_3D


func _get_input_port_count():
	return 5


func _get_input_port_name(port):
	match port:
		0:
			return "uv"
		1:
			return "offset"
		2:
			return "scale"
		3:
			return "jitter"
		4:
			return "time"
		_:
			push_error("Unknown port name: %d" % port)
			return ""


func _get_input_port_type(port):
	match port:
		0:
			return VisualShaderNode.PORT_TYPE_VECTOR_3D
		1:
			return VisualShaderNode.PORT_TYPE_VECTOR_3D
		2, 3, 4:
			return VisualShaderNode.PORT_TYPE_SCALAR
		_:
			push_error("Unknown port type: %d" % port)
			return VisualShaderNode.PORT_TYPE_MAX


func _get_output_port_count():
	return 1


func _get_output_port_name(_port):
	return "id_color"


func _get_output_port_type(_port):
	return VisualShaderNode.PORT_TYPE_VECTOR_3D


func _get_global_code(_mode):
	return """
#ifndef ImportWorley3DCellID
	#define ImportWorley3DCellID
	#include "res://Shaders/Nodes/Worley3DCellID.gdshaderinc"
#endif
"""


func _get_code(input_vars, output_vars, _mode, _type):
	var uv: String = input_vars[0] if not input_vars[0].is_empty() else "(inverse(MODEL_MATRIX) * INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz"

	return "%s = _worley3dCellIDFunc((%s + %s) * %s + vec3(%s), min(max(%s, 0.0), 1.0));" % [
		output_vars[0],
		uv,
		input_vars[1],
		input_vars[2],
		input_vars[4],
		input_vars[3],
	]
