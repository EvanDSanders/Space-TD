#include "res://Shaders/UI/RoundBoxUV.gdshaderinc"

vec4 RoundBoxUVCenter(vec2 uv_in, vec2 UVCenter, vec2 UVSize, vec2 BorderUVScale, vec4 FillColor, vec4 BorderColor, float BorderSize, float Radius) {
	vec2 half_size = UVSize * 0.5;
	return RoundBoxUV(uv_in, UVCenter - half_size, UVCenter + half_size, BorderUVScale, FillColor, BorderColor, BorderSize, Radius);
}

vec4 RoundBoxUVCenter(vec2 uv_in, vec2 UVCenter, vec2 UVSize, vec2 BorderUVScale, vec3 FillColor, vec3 BorderColor, float BorderSize, float Radius) {
	return RoundBoxUVCenter(uv_in, UVCenter, UVSize, BorderUVScale, vec4(FillColor, 1.0), vec4(BorderColor, 1.0), BorderSize, Radius);
}
