shader_type canvas_item;

// Define a intensidade do blur (0 a 5)
uniform float blur_amount : hint_range(0, 5) = 2.5;

// Define o quanto vai escurecer (1.0 = cor original, 0.0 = preto total)
// Um valor entre 0.4 e 0.6 geralmente fica bom.
uniform float escurecimento : hint_range(0, 1) = 0.5;

// Pega a textura do que está atrás do ColorRect
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	// 1. Lê a cor da tela borrada
	vec4 color = textureLod(SCREEN_TEXTURE, SCREEN_UV, blur_amount);
	
	// 2. Aplica o escurecimento multiplicando RGB pelos canais RGB do escurecimento.
	// Mantemos o Alpha (color.a) original para não dar erro de transparência.
	color.rgb *= escurecimento;
	
	// 3. Define a cor final
	COLOR = color;
}