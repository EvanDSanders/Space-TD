// Returns vec4(color, alpha). Alpha is 0 outside the box.
// BorderUVScale: per-axis divisor to make the border/radius uniform (e.g. vec2(1.0, aspect)).
vec4 RoundBoxUV(vec2 uv_in, vec2 UVStart, vec2 UVEnd, vec2 BorderUVScale, vec4 FillColor, vec4 BorderColor, float BorderSize, float Radius) {
	vec2 scale = max(abs(BorderUVScale), vec2(1.0e-6));
	vec2 center = (UVStart + UVEnd) * 0.5;
	vec2 half_size = abs(UVEnd - UVStart) * 0.5 / scale;
	vec2 q = (uv_in - center) / scale;

	float r = clamp(Radius, 0.0, min(half_size.x, half_size.y));
	vec2 k = abs(q) - half_size + r;
	float d = length(max(k, 0.0)) + min(max(k.x, k.y), 0.0) - r;

	float aa = max(fwidth(d), 1.0e-6);
	float alpha = 1.0 - smoothstep(-aa, aa, d);
	float border_mix = smoothstep(-BorderSize - aa, -BorderSize + aa, d);

	vec4 c = mix(FillColor, BorderColor, border_mix);
	return vec4(c.rgb, c.a * alpha);
}

vec4 RoundBoxUV(vec2 uv_in, vec2 UVStart, vec2 UVEnd, vec2 BorderUVScale, vec3 FillColor, vec3 BorderColor, float BorderSize, float Radius) {
	return RoundBoxUV(uv_in, UVStart, UVEnd, BorderUVScale, vec4(FillColor, 1.0), vec4(BorderColor, 1.0), BorderSize, Radius);
}
