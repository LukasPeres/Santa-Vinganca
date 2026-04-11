extends Node2D

@onready var raycast = $RayCast2D
@onready var line = $Line2D

var comprimento_maximo = 1000.0 # O quão longe o raio chega
var esta_ativo = false

func _ready():
	# 1. Configuração inicial: O raio começa "encolhido"
	line.points[1] = Vector2.ZERO 
	raycast.target_position = Vector2.ZERO
	
	# === O SEU AWAIT DE AVISO ===
	# Aqui o player vê o Boss preparando, mas nada acontece ainda
	await get_tree().create_timer(1.0).timeout 
	
	# 2. DISPARAR O RAIO
	ativar_raio()

func _physics_process(delta):
	if esta_ativo:
		# Fazemos o raio "crescer" ou se manter esticado até a parede
		atualizar_raio()

func ativar_raio():
	esta_ativo = true
	# Define a direção (ex: para a direita)
	# Você pode passar a direção do Boss para cá depois
	var direcao = Vector2(comprimento_maximo, 0) 
	raycast.target_position = direcao
	
	# O Timer de quanto tempo o raio fica na tela
	await get_tree().create_timer(0.5).timeout
	queue_free()

func atualizar_raio():
	# Forçamos o RayCast a atualizar a colisão agora
	raycast.force_raycast_update()
	
	var ponto_final = raycast.target_position
	
	if raycast.is_colliding():
		# Se bater em algo (parede ou player), o ponto final é onde bateu
		# transformamos a posição global de batida em posição local para o Line2D
		ponto_final = to_local(raycast.get_collision_point())
		
		# CHECAGEM DE DANO
		var objeto = raycast.get_collider()
		if objeto.is_in_group("player"):
			dar_dano_no_player(objeto)
	
	# Estica o desenho do Line2D até o ponto de impacto
	line.points[1] = ponto_final

func dar_dano_no_player(player_node):
	if player_node.has_method("take_damage"):
		player_node.take_damage(1)
		# Dica: adicione um pequeno timer aqui para o raio não dar 
		# dano em todos os frames (60 vezes por segundo)
