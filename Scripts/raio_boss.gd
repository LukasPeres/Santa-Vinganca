extends Area2D

@export var dano: int = 1
@export var comprimento_maximo: float = 2000.0

@onready var sprite_inicio = $Sprite_Inicio
@onready var sprite_meio = $Sprite_Meio
@onready var colisao = $CollisionShape2D

var e_apenas_aviso: bool = false

func _ready():
	# Timer para o raio sumir
	get_tree().create_timer(0.67).timeout.connect(func(): queue_free())

func configurar_como_aviso(direcao_x: float):
	e_apenas_aviso = true
	scale.x = direcao_x
	if colisao: colisao.disabled = true
	
	modulate = Color(1, 0, 0, 0.4) 
	scale.y = 0.1 
	
	# Aumente esse tempo se o aviso sumir antes do raio aparecer!
	# Experimente 0.4 ou 0.5 se a animação for lenta.
	get_tree().create_timer(0.4).timeout.connect(func(): queue_free())
	

func configurar_raio(direcao_x: float):
	e_apenas_aviso = false
	scale.x = direcao_x
	
	# GARANTE QUE O REAL DÁ DANO
	if colisao: 
		colisao.disabled = false
		var largura = colisao.shape.size.x
		colisao.position.x = largura / 2
	
	# Efeito de "Flash" branco ao disparar
	modulate = Color(2, 2, 2, 1) # Brilho intenso
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.2)
	
# --- FUNÇÃO DE DANO ---
func _on_body_entered(body: Node2D) -> void:
	# 1. Verifica se o que entrou é o Player
	if body.is_in_group("player"):
		# 2. Verifica se o Player tem a função de tomar dano
		if body.has_method("take_damage"):
			# Envia o valor do dano e a posição do raio para o Knockback
			body.take_damage(dano, global_position)
			print("RAIO: Player atingido!")
