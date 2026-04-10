extends CharacterBody2D

# --- CONFIGURAÇÕES ---


var timer_sorteio : float = 0.0 # Nova variável no topo do script
var chance_de_ataque : float = 0.0
var incremento_por_segundo : float = 10.0

var delay_reacao = 0.2
var timer_reacao = 0.0
var direcao_atual = 1.0

var health = 20.0
const FASE2_THRESHOLD = 10.0
const SPEED_ATROPELAMENTO = 80.0

# Referências
@onready var corpo = $corpo
@onready var cabeca = $cabeca
@onready var remote_transform = $corpo/RemoteTransform2D

# IA e Estados
var player = null
enum States { SEGUINDO, AFASTANDO_PARA_RAIO, EXECUTANDO_RAIO, MARTELADA, TRANSICAO }
var current_state = States.SEGUINDO

func _ready():
	add_to_group("enemy")
	player = get_tree().get_first_node_in_group("player")
	if cabeca:
		remote_transform.remote_path = cabeca.get_path()

func _physics_process(delta):
	# Trava de Fase 2
	if health <= FASE2_THRESHOLD and current_state != States.TRANSICAO:
		mudar_estado(States.TRANSICAO)
		return
		
	if current_state == States.TRANSICAO: return

	# 1. LÓGICA DO MEDIDOR
	if current_state == States.SEGUINDO:
		timer_sorteio += delta
		
		if timer_sorteio >= 1.0: # Passou 1 segundo?
			timer_sorteio = 0.0 # Reseta o relógio do sorteio
			chance_de_ataque += incremento_por_segundo # Sobe 10%
			
			print("Medidor: ", chance_de_ataque, "% - Sorteando...")
			
			if randf() * 100.0 < chance_de_ataque:
				decidir_qual_ataque()

	# 2. LÓGICA DE MOVIMENTO
	match current_state:
		States.SEGUINDO:
			perseguir_player(delta)
		States.AFASTANDO_PARA_RAIO:
			fugir_do_player()
		States.EXECUTANDO_RAIO, States.MARTELADA:
			velocity.x = 0 

	# 3. SINCRONIA VISUAL
	if velocity.x != 0:
		var direcao_da_andada = sign(velocity.x)
		if corpo.has_method("atualizar_direcao"):
			corpo.atualizar_direcao(direcao_da_andada)

	apply_gravity(delta)
	move_and_slide()

# =========================================================
# MOVIMENTAÇÃO
# =========================================================

func perseguir_player(delta):
	if player:
		var direcao_alvo = sign(player.global_position.x - global_position.x)
		if direcao_alvo != direcao_atual:
			timer_reacao += delta
			if timer_reacao >= delay_reacao:
				direcao_atual = direcao_alvo
				timer_reacao = 0.0
		else:
			timer_reacao = 0.0
		velocity.x = direcao_atual * SPEED_ATROPELAMENTO

func fugir_do_player():
	if player:
		var direcao_fuga = sign(global_position.x - player.global_position.x)
		velocity.x = direcao_fuga * SPEED_ATROPELAMENTO

func mudar_estado(novo_estado):
	current_state = novo_estado
	if novo_estado == States.TRANSICAO:
		transicao_fase_2()

# =========================================================
# COMBATE
# =========================================================

func decidir_qual_ataque():
	print("Sorteando ataque... Chance era: ", int(chance_de_ataque), "%")
	chance_de_ataque = 0.0 
	var tipo = randi() % 2 
	
	if tipo == 0:
		iniciar_sequencia_raio()
	else:
		iniciar_sequencia_martelada()

func iniciar_sequencia_martelada():
	print("BOSS: MARTELADA!")
	current_state = States.MARTELADA
	# Aqui você pode chamar o spawn das bolas de neve futuramente
	await get_tree().create_timer(0.8).timeout
	current_state = States.SEGUINDO

func iniciar_sequencia_raio():
	print("BOSS: Preparando Raio (Fugindo...)")
	current_state = States.AFASTANDO_PARA_RAIO
	
	# Espera o tempo de fuga (1.5s)
	await get_tree().create_timer(1.5).timeout
	
	# --- AJUSTE AQUI: Vira para o player antes de atirar ---
	if player:
		var direcao_para_player = sign(player.global_position.x - global_position.x)
		if corpo.has_method("atualizar_direcao"):
			corpo.atualizar_direcao(direcao_para_player)
	
	current_state = States.EXECUTANDO_RAIO
	print("ATAQUE: Disparando Raio! (Agora olhando para o Player)")
	
	await get_tree().create_timer(1.0).timeout
	current_state = States.SEGUINDO

# =========================================================
# SISTEMA
# =========================================================

func take_damage(amount, _from_pos = Vector2.ZERO, _is_projectile = false):
	health -= amount
	if corpo.has_method("flash_damage"): corpo.flash_damage()
	if cabeca.has_method("flash_damage"): cabeca.flash_damage()
	print("HP Boss: ", health)

func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += 900 * delta

func transicao_fase_2():
	print("!!! FASE 2 !!!")
	remote_transform.update_position = false
	corpo.get_node("CollisionShape2D").disabled = false
	cabeca.get_node("CollisionShape2D").disabled = false
	corpo.iniciar_fase_2()
	cabeca.iniciar_fase_2()
	
	var arena = get_parent()
	corpo.reparent(arena)
	cabeca.reparent(arena)
	queue_free()
