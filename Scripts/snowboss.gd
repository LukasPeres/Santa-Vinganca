extends Node2D

# --- CONFIGURAÇÕES ---
@export var vida_fase_1 = 20.0
@export var speed_dash = 400.0
@export var raio_range = 300.0

# Estados da Fase 1
enum BossState { IDLE, PREPARAR_MARTELO, DASH, MARTELADA, RAIO, TRANSICAO }
var state = BossState.IDLE

# Referências
@onready var corpo = $Corpo
@onready var cabeca = $Cabeca
@onready var remote_transform = $Corpo/PontoCabeca/RemoteTransform2D
@onready var timer_estado = $TimerEstado

var player = null

func _ready():
	add_to_group("boss")
	player = get_tree().get_first_node_in_group("player")
	escolher_proximo_ataque()

func _physics_process(delta):
	match state:
		BossState.IDLE:
			velocity.x = move_toward(velocity.x, 0, 10)
		BossState.DASH:
			# O corpo avança rapidamente
			move_and_slide()
		BossState.RAIO:
			# Lógica de girar para o player enquanto atira
			olhar_para_player()

	apply_gravity(delta)
	move_and_slide()

# =========================================================
# LÓGICA DE DANOS E TRANSIÇÃO
# =========================================================
func take_damage(amount):
	vida_fase_1 -= amount
	if vida_fase_1 <= 0 and state != BossState.TRANSICAO:
		iniciar_separacao()

func iniciar_separacao():
	state = BossState.TRANSICAO
	print("!!! DIVISÃO !!!")
	
	# 1. Desligamos o RemoteTransform para a cabeça parar de seguir o corpo
	remote_transform.update_position = false
	remote_transform.update_rotation = false
	
	# 2. Chamamos o método que você já criou nos filhos
	corpo.iniciar_fase_2()
	cabeca.iniciar_fase_2()
	
	# 3. Tornamos eles independentes na árvore (Reparent)
	# Assim, se o "Pai" (SnowBoss) sumir, eles continuam na arena
	var arena = get_parent()
	corpo.reparent(arena)
	cabeca.reparent(arena)
	
	queue_free() # O nó pai "SnowBoss" deixa de existir

# =========================================================
# ATAQUES (FASE 1)
# =========================================================

func ataque_martelada():
	state = BossState.PREPARAR_MARTELO
	# Toca animação de "carregar" no corpo
	await get_tree().create_timer(0.5).timeout
	
	# Dash em direção ao player
	var dir = sign(player.global_position.x - global_position.x)
	velocity.x = dir * speed_dash
	state = BossState.DASH
	
	# Espera chegar perto ou um tempo fixo
	await get_tree().create_timer(0.6).timeout
	impacto_martelo()

func impacto_martelo():
	velocity.x = 0
	state = BossState.MARTELADA
	# Aqui você instancia as bolas de neve em arco
	# corpo.animar_martelada()
	await get_tree().create_timer(1.0).timeout
	escolher_proximo_ataque()

func olhar_para_player():
	if player:
		var dir = sign(player.global_position.x - global_position.x)
		# Inverte o conjunto (Pai controla a escala do grupo)
		scale.x = abs(scale.x) * dir

func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += 900 * delta

func escolher_proximo_ataque():
	# Lógica simples de sorteio entre Raio e Martelada
	var sorteio = randi() % 2
	if sorteio == 0:
		ataque_martelada()
	else:
		# ataque_raio()
		pass
