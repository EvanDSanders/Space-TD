shader_type spatial;
//render_mode unshaded, cull_disabled, blend_mix, world_vertex_coords;


//varying vec3 coords;
//void vertex()
//{
  //coords = VERTEX.xyz;
//}

float fresnel(float amount, vec3 normal, vec3 view)
{
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0 )), amount);
}


float EaseIQuad(float x)
{
	return x * x * x;
}


//#include "res://Shaders/HSV.gdshaderinc"

float shield(float amount, vec3 normal, vec3 view) {
	//ALBEDO = color.rgb;

	float f = fresnel(amount, normal, view);
	float e = f * 0.4;
	if ( f > 0.4 ) { e = 1.; }
	
	return e * 5.;
}
