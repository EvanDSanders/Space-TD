vec3 _worley3dCellIDFunc(vec3 P, float _jitter_w3id) {
	float K = 0.142857142857;
	float Ko = 0.428571428571;
	float K2 = 0.020408163265306;
	float Kz = 0.166666666667;
	float Kzo = 0.416666666667;

	vec3 Pi = floor(P) - floor(floor(P) * (1.0 / 289.0)) * 289.0;
	vec3 Pf = fract(P) - 0.5;

	float d_min = 1.0e6;
	vec3 id_min = vec3(0.0);

	for (int zi = -1; zi <= 1; zi++) {
		for (int yi = -1; yi <= 1; yi++) {
			for (int xi = -1; xi <= 1; xi++) {
				vec3 offset = vec3(float(xi), float(yi), float(zi));
				vec3 cell = Pi + offset;

				float p = (34.0 * cell.x + 1.0) * cell.x;
				p = p - floor(p * (1.0 / 289.0)) * 289.0;
				p = (34.0 * (p + cell.y) + 1.0) * (p + cell.y);
				p = p - floor(p * (1.0 / 289.0)) * 289.0;
				p = (34.0 * (p + cell.z) + 1.0) * (p + cell.z);
				p = p - floor(p * (1.0 / 289.0)) * 289.0;

				vec3 o = vec3(
					fract(p * K) - Ko,
					(floor(p * K) - floor(floor(p * K) * (1.0 / 7.0)) * 7.0) * K - Ko,
					floor(p * K2) * Kz - Kzo
				);

				vec3 d = (Pf - offset) + _jitter_w3id * o;
				float dist = dot(d, d);
				if (dist < d_min) {
					d_min = dist;
					id_min = cell;
				}
			}
		}
	}

	return fract(sin(id_min * vec3(127.1, 311.7, 74.7) + id_min.yzx * vec3(269.5, 183.3, 246.1)) * 43758.5453123);
}
