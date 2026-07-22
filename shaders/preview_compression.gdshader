shader_type canvas_item;

// JPEG quality: 1 = worst (max artifacts), 100 = best (no artifacts)
uniform int quality : hint_range(1, 100) = 85;

// Macroblock size for JPEG (must be even)
uniform int block_size : hint_range(2, 64, 2) = 8;

// Downscale: 0.0 = original resolution, 1.0 = max downscale
uniform float downscale : hint_range(0.0, 1.0) = 0.0;

// ---- Color space ----

vec3 rgb_to_ycbcr(vec3 c) {
	float y  = 0.299000 * c.r + 0.587000 * c.g + 0.114000 * c.b;
	float cb = -0.168736 * c.r - 0.331264 * c.g + 0.500000 * c.b + 0.5;
	float cr = 0.500000 * c.r - 0.418688 * c.g - 0.081312 * c.b + 0.5;
	return vec3(y, cb, cr);
}

vec3 ycbcr_to_rgb(vec3 c) {
	float y  = c.x;
	float cb = c.y - 0.5;
	float cr = c.z - 0.5;
	float r = y + 1.402000 * cr;
	float g = y - 0.344136 * cb - 0.714136 * cr;
	float b = y + 1.772000 * cb;
	return vec3(r, g, b);
}

// ---- Kawase-style downscale sampling ----
// Samples the texture at (uv_center) with a 5-tap Kawase kernel
// At downscale=0 it's just a single sample (fast path)
vec3 sample_downscaled(sampler2D tex, vec2 uv_center, vec2 tex_size, float ds) {
	if (ds <= 0.001) {
		return texture(tex, uv_center).rgb;
	}
	
	// Kawase offset scales with downscale strength
	float kawase_radius = ds * 1.5;
	vec2 o = vec2(kawase_radius) / tex_size;
	
	// 5-tap Kawase kernel: center x4 + 4 corners
	vec3 col = texture(tex, uv_center).rgb * 4.0;
	col += texture(tex, uv_center + vec2(-o.x, -o.y)).rgb;
	col += texture(tex, uv_center + vec2( o.x, -o.y)).rgb;
	col += texture(tex, uv_center + vec2(-o.x,  o.y)).rgb;
	col += texture(tex, uv_center + vec2( o.x,  o.y)).rgb;
	col /= 8.0;
	
	return col;
}

// ---- FRAGMENT ----

void fragment() {
	const int N = 8; // DCT block size (fixed)
	
	// Orthogonal DCT basis from https://patents.google.com/patent/CN100409693C/en
	const float dct[64] = float[64](
		0.353553,0.353553,0.353553,0.353553,0.353553,0.353553,0.353553,0.353553,
		0.490393,0.415735,0.277785,0.0975452,-0.0975452,-0.277785,-0.415735,-0.490393,
		0.46194,0.191342,-0.191342,-0.46194,-0.46194,-0.191342,0.191342,0.46194,
		0.415735,-0.0975452,-0.490393,-0.277785,0.277785,0.490393,0.0975452,-0.415735,
		0.353553,-0.353553,-0.353553,0.353553,0.353553,-0.353553,-0.353553,0.353553,
		0.277785,-0.490393,0.0975452,0.415735,-0.415735,-0.0975452,0.490393,-0.277785,
		0.191342,-0.46194,0.46194,-0.191342,-0.191342,0.46194,-0.46194,0.191342,
		0.0975452,-0.277785,0.415735,-0.490393,0.490393,-0.415735,0.277785,-0.0975452
	);
	
	// Flattened 8x8 buffers
	vec3 block[64];
	vec3 horiz[64];
	vec3 vert[64];
	vec3 inv_horiz[64];
	vec3 inv_block[64];
	
	// Texture size in pixels
	vec2 tex_size = 1.0 / TEXTURE_PIXEL_SIZE;
	
	// Pixel coordinates in the texture
	vec2 px_f = UV * tex_size;
	int px = int(floor(px_f.x));
	int py = int(floor(px_f.y));
	
	int bs = clamp(block_size, 1, 64);
	int block_origin_x = (px / bs) * bs;
	int block_origin_y = (py / bs) * bs;
	int lid_x = px - block_origin_x;
	int lid_y = py - block_origin_y;
	
	// Virtual resolution for downscale
	float virtual_scale = mix(1.0, 0.05, downscale);
	float inv_virtual = 1.0 / max(virtual_scale, 0.001);
	
	// ---- STEP 1: Sample + downscale the 8x8 block ----
	
	for (int y = 0; y < N; y++) {
		for (int x = 0; x < N; x++) {
			float fx = (float(x) + 0.5) / float(N);
			float fy = (float(y) + 0.5) / float(N);
			
			int sample_x = block_origin_x + int(floor(fx * float(bs)));
			int sample_y = block_origin_y + int(floor(fy * float(bs)));
			
			// Apply downscale: snap sample positions to a low-res grid
			if (downscale > 0.001) {
				float snapped_x = floor(float(sample_x) * virtual_scale) * inv_virtual;
				float snapped_y = floor(float(sample_y) * virtual_scale) * inv_virtual;
				sample_x = int(clamp(snapped_x, 0.0, tex_size.x - 1.0));
				sample_y = int(clamp(snapped_y, 0.0, tex_size.y - 1.0));
			} else {
				sample_x = clamp(sample_x, 0, int(tex_size.x) - 1);
				sample_y = clamp(sample_y, 0, int(tex_size.y) - 1);
			}
			
			vec2 sample_uv = (vec2(float(sample_x), float(sample_y)) + vec2(0.5)) / tex_size;
			
			// Use Kawase-style sampling for smooth downscale
			vec3 texc = sample_downscaled(TEXTURE, sample_uv, tex_size, downscale);
			
			block[y * N + x] = rgb_to_ycbcr(texc);
		}
	}
	
	// ---- STEP 2: Forward DCT (horizontal) ----
	
	for (int y = 0; y < N; y++) {
		for (int u = 0; u < N; u++) {
			vec3 sum = vec3(0.0);
			for (int x = 0; x < N; x++) {
				sum += block[y * N + x] * dct[u * N + x];
			}
			horiz[y * N + u] = sum;
		}
	}
	
	// ---- STEP 3: Forward DCT (vertical) + Quantization ----
	
	float qscale = max(1.0, float(quality));
	for (int v = 0; v < N; v++) {
		for (int u = 0; u < N; u++) {
			vec3 sum = vec3(0.0);
			for (int y = 0; y < N; y++) {
				sum += horiz[y * N + u] * dct[v * N + y];
			}
			// Quantization: lower quality = more rounding = more artifacts
			float q = qscale * float(u + v + 1);
			vert[v * N + u] = round(sum * 128.0 / q) * (q / 128.0);
		}
	}
	
	// ---- STEP 4: Inverse DCT (horizontal) ----
	
	for (int v = 0; v < N; v++) {
		for (int x = 0; x < N; x++) {
			vec3 sum = vec3(0.0);
			for (int u = 0; u < N; u++) {
				sum += vert[v * N + u] * dct[u * N + x];
			}
			inv_horiz[v * N + x] = sum;
		}
	}
	
	// ---- STEP 5: Inverse DCT (vertical) ----
	
	for (int y = 0; y < N; y++) {
		for (int x = 0; x < N; x++) {
			vec3 sum = vec3(0.0);
			for (int v = 0; v < N; v++) {
				sum += inv_horiz[v * N + x] * dct[v * N + y];
			}
			inv_block[y * N + x] = sum;
		}
	}
	
	// ---- STEP 6: Pick the pixel within the block ----
	
	int pick_x = int(float(lid_x) * float(N) / float(bs));
	int pick_y = int(float(lid_y) * float(N) / float(bs));
	pick_x = clamp(pick_x, 0, N - 1);
	pick_y = clamp(pick_y, 0, N - 1);
	
	vec3 out_ycbcr = inv_block[pick_y * N + pick_x];
	vec3 out_rgb = ycbcr_to_rgb(out_ycbcr);
	COLOR = vec4(clamp(out_rgb, 0.0, 1.0), 1.0);
}
