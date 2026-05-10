shader_type canvas_item;

uniform bool active = false;

void fragment() {
	vec4 tint_color = texture(TEXTURE, UV);
	if (active) {
		// Substitui as cores do sprite por branco, mantendo a transparência
		tint_color.rgb = vec3(1.0, 1.0, 1.0);
	}
	COLOR = tint_color;
}