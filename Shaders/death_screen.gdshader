shader_type canvas_item;

// Aumentamos o range de 5 para 10 para um blur muito mais forte
uniform float blur_amount : hint_range(0, 5) = 2.5; 

// O escurecimento já vai de 0 a 1. 
// Para começar mais escuro por padrão, diminua o valor inicial (ex: 0.3)
uniform float escurecimento : hint_range(0, 1) = 0.5; 

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
    // O resto do código permanece igual
    vec4 color = textureLod(SCREEN_TEXTURE, SCREEN_UV, blur_amount);
    color.rgb *= escurecimento;
    COLOR = color;
}