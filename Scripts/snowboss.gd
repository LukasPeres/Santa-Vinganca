extends CharacterBody2D
@export var bola_neve_scene : PackedScene # Arraste o snowball_arc.tscn aqui no Inspetor
@export var raio_scene : PackedScene # Arraste o raio_boss.tscn aqui no Inspetor

# --- CONFIGURAÇÕES ---
const SPEED_DASH = 170.0 # Velocidade do deslize (bem maior que a perseguição)
const DURACAO_DASH = 0.6 # Quanto tempo ele fica deslizando

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
enum States { SEGUINDO, AFASTANDO_PARA_RAIO, EXECUTANDO_RAIO, DASH_MARTELADA, MARTELADA, TRANSICAO }
var current_state = States.SEGUINDO

func _ready():
	add_to_group("enemy")
	player = get_tree().get_first_node_in_group("player")
	if cabeca:
		remote_transform.remote_path = cabeca.get_path()

func _physics_process(delta):
	# Trava de Fase 2
	if health <= FASE2_THRESHOLD and current_state != States.TRANSICAO:
		change_state(States.TRANSICAO)
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
		States.DASH_MARTELADA:
			# Mantém a velocidade que definimos no início do dash
			velocity.x = direcao_atual * SPEED_DASH
		States.EXECUTANDO_RAIO, States.MARTELADA:
			velocity.x = 0

	# 3. SINCRONIA VISUAL
	if velocity.x != 0:
		var direcao_da_andada = sign(velocity.x)
		if corpo.has_method("atualizar_direcao"):
			corpo.atualizar_direcao(direcao_da_andada)

	apply_gravity(delta)
	move_and_slide()

func change_state(new_state):
	# --- SAÍDA DO ESTADO ANTERIOR ---
	match current_state:
		States.SEGUINDO:
			timer_sorteio = 0.0 # Reseta o tempo de sorteio ao parar de seguir
			velocity.x = 0

	# --- TROCA ---
	current_state = new_state

	# --- ENTRADA NO NOVO ESTADO (Onde você colocará as animações futuramente) ---
	match current_state:
		States.SEGUINDO:
			print("ENTRANDO: Seguindo")
			# aqui iria: animation_player.play("walk")
		States.AFASTANDO_PARA_RAIO:
			print("ENTRANDO: Fuga para Raio")
		States.EXECUTANDO_RAIO:
			velocity.x = 0
			print("ENTRANDO: Disparo")
		States.DASH_MARTELADA:
			print("ENTRANDO: Dash Deslizante!")
			# aqui iria: animation_player.play("dash_slide")
		States.MARTELADA:
			velocity.x = 0
			print("ENTRANDO: Martelada")
		States.TRANSICAO:
			transicao_fase_2()

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
	change_state(States.DASH_MARTELADA)
	
	if player:
		direcao_atual = sign(player.global_position.x - global_position.x)
	
	velocity.x = direcao_atual * SPEED_DASH
	await get_tree().create_timer(DURACAO_DASH).timeout
	
	# --- MOMENTO DO IMPACTO ---
	change_state(States.MARTELADA)
	
	if corpo.has_method("set_martelada_ativa"):
		corpo.set_martelada_ativa(true) 
	
	# ADICIONE ESTA LINHA AQUI:
	disparar_chuva_bolas()
	
	print("ATAQUE: POW! (Bolas disparadas)")
	
	await get_tree().create_timer(0.4).timeout 
	
	if corpo.has_method("set_martelada_ativa"):
		corpo.set_martelada_ativa(false) 
		
	await get_tree().create_timer(0.4).timeout 
	change_state(States.SEGUINDO)
	
func disparar_chuva_bolas():
	if not bola_neve_scene: return
	
	var ponto = $corpo/PontoImpacto
	var numero_de_bolas = 16 # Quantidade de bolas na chuva
	
	# Sorteia o início do Spot Safe (evitando as pontas extremas)
	# O buraco terá 2 bolas de largura para ser um "safe spot" real
	var spot_safe_inicio = randi_range(2, 7) 
	
	print("BOSS: Chuva vertical! Spot Safe no índice: ", spot_safe_inicio)
	
	for i in range(numero_de_bolas):
		# Cria o buraco removendo duas bolas vizinhas
		if i == spot_safe_inicio or i == spot_safe_inicio + 1:
			continue
			
		var bola = bola_neve_scene.instantiate()
		get_parent().add_child(bola)
		bola.global_position = ponto.global_position
		bola.z_index = 10
		
		# --- CÁLCULO PARA ARCO VOLTADO PARA CIMA ---
		# fracao vai de 0.0 a 1.0
		var fracao = float(i) / float(numero_de_bolas - 1)
		
		# Ajuste de Direção Horizontal (-1.0 esquerda, 1.0 direita)
		# Diminuímos o multiplicador (ex: 300) para o arco não abrir 180 graus
		var direcao_horizontal = lerp(-1.0, 1.0, fracao)
		var forca_x = direcao_horizontal * 350.0 # Valor menor = arco mais fechado
		
		# Ajuste de Força Vertical (Sempre para cima)
		# Aumentamos a base (-600) para elas subirem bem alto antes de cair
		var forca_y = -450.0 - (randf() * 150.0) 
		
		if "velocity" in bola:
			bola.velocity = Vector2(forca_x, forca_y)

func iniciar_sequencia_raio():
	change_state(States.AFASTANDO_PARA_RAIO)
	await get_tree().create_timer(1.5).timeout
	if player:
		var direcao_para_player = sign(player.global_position.x - global_position.x)
		corpo.atualizar_direcao(direcao_para_player)
	change_state(States.EXECUTANDO_RAIO)
	await get_tree().create_timer(1.0).timeout
	change_state(States.SEGUINDO)

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
