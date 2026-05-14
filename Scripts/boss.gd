extends CharacterBody2D

@onready var hitbox_soco: Area2D = $HitboxSoco

# --- ENUMS (Cérebro) ---
enum BossState { IDLE, ATTACKING, COOLDOWN, TRANSITION, DEAD }
enum Phase { PHASE_1, PHASE_2, PHASE_3 }

var ataque_timer: float = 0.0
var tempo_hitbox_ativa: float = 0.2 # Duração do soco "físico"

# --- VARIÁVEIS DE CONTROLE ---
var ultimo_ataque: String = ""
var contador_repeticao: int = 0

# --- CONFIGURAÇÕES DE VIDA ---
var max_health: float = 100.0
var health: float = 100.0
var current_phase: Phase = Phase.PHASE_1

# --- LÓGICA DE MOVIMENTAÇÃO (Músculos) ---
const SPEED_SEGUINDO = 100.0
const DELAY_REACAO = 0.2
var direcao_atual: float = 1.0
var timer_reacao: float = 0.0
var player: CharacterBody2D = null

# --- LÓGICA DE ATAQUE (Sorteio) ---
var status_atual: BossState = BossState.IDLE
var chance_ataque: float = 0.0
var timer_sorteio: float = 0.0
const INCREMENTO_CHANCE = 20.0
const INTERVALO_SORTEIO = 1.0
const TEMPO_COOLDOWN = 0.1

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	add_to_group("boss")
	player = get_tree().get_first_node_in_group("player")
	hitbox_soco.monitoring = false # Segurança extra
	go_to_andando_state()

# =========================================================
# MAESTRO (O Único lugar onde as funções são chamadas)
# =========================================================
func _physics_process(delta):
	apply_gravity(delta)
	update_state_logic(delta)    # Decide o que fazer (timers)
	update_movement_logic(delta) # Decide para onde ir (física)
	apply_final_physics()        # Executa o movimento

# =========================================================
# LÓGICA DE ESTADOS (O Cérebro)
# =========================================================
func update_state_logic(delta):
	match status_atual:
		BossState.IDLE:
			andando_state(delta) # <--- MUDAR AQUI (Chamando sua nova função organizada)
		BossState.ATTACKING:
			punch_state(delta)
		BossState.COOLDOWN:
			processar_cooldown(delta)
		BossState.TRANSITION:
			pass

func processar_timer_ataque(delta):
	timer_sorteio += delta
	if timer_sorteio >= INTERVALO_SORTEIO:
		timer_sorteio = 0.0
		chance_ataque += INCREMENTO_CHANCE
		if randf() * 100.0 < chance_ataque:
			decidir_ataque()

func processar_cooldown(delta):
	timer_sorteio -= delta
	if timer_sorteio <= 0:
		go_to_andando_state()

# =========================================================
# LÓGICA DE MOVIMENTAÇÃO (Os Músculos)
# =========================================================
func update_movement_logic(delta):
	match status_atual:
		BossState.IDLE, BossState.COOLDOWN:
			handle_follow_player_behavior(delta)
		BossState.ATTACKING:
			# Força a velocidade a ser zero para não deslizar no soco
			velocity.x = 0

func handle_follow_player_behavior(delta):
	if not player: return

	var direcao_alvo = sign(player.global_position.x - global_position.x)

	# Se o player mudou de lado, começa a contar o tempo de reação
	if direcao_alvo != direcao_atual and direcao_alvo != 0:
		timer_reacao += delta
		if timer_reacao >= DELAY_REACAO:
			direcao_atual = direcao_alvo
			timer_reacao = 0.0
	else:
		timer_reacao = 0.0

	velocity.x = direcao_atual * SPEED_SEGUINDO
	update_visual_direction()

func handle_stop_behavior(delta):
	# Para suavemente quando ataca ou muda de fase
	velocity.x = move_toward(velocity.x, 0, 15)

func update_visual_direction():
	# Se estiver andando, vira conforme a velocidade
	if velocity.x != 0:
		sprite.flip_h = (velocity.x < 0)
	# Se estiver parado (atacando), vira para onde o player está
	elif player:
		var direcao_para_player = sign(player.global_position.x - global_position.x)
		if direcao_para_player != 0:
			sprite.flip_h = (direcao_para_player < 0)

# =========================================================
# FÍSICA FINAL
# =========================================================
func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += 980 * delta

func apply_final_physics():
	move_and_slide()

# =========================================================
# TRANSIÇÕES E ATAQUES (Mesma lógica de antes)
# =========================================================
func decidir_ataque():
	chance_ataque = 0.0
	var ataques = []
	match current_phase:
		Phase.PHASE_1: ataques = ["soco", "garrafa", "maleta"]
		Phase.PHASE_2: ataques = ["soco", "dash_fogo"]
		Phase.PHASE_3: ataques = ["soco", "dash_fogo", "laser"]
	
	var escolha = ataques.pick_random()
	# REGRA: Não pode repetir o mesmo ataque 3 vezes seguidas
	if escolha == ultimo_ataque and contador_repeticao >= 2:
		# Sorteia de novo removendo a opção viciada
		ataques.erase(escolha)
		escolha = ataques.pick_random()
	
	# Atualiza o rastreador de repetição
	if escolha == ultimo_ataque:
		contador_repeticao += 1
	else:
		contador_repeticao = 1
		ultimo_ataque = escolha

	# Executa o ataque escolhido
	match escolha:
		"soco": go_to_punch_state()
		"garrafa": go_to_bottle_state()
		"maleta": go_to_briefcase_state()
		"dash_fogo": go_to_dash_state()
		"laser": go_to_laser_state()
#===========================
func andando_state(delta):
	# 1. Movimento: Ele tenta alcançar o player com aquele delay de reação
	handle_follow_player_behavior(delta)
	
	# 2. Sorteio: Enquanto anda, a barra de 20% vai enchendo
	timer_sorteio += delta
	if timer_sorteio >= INTERVALO_SORTEIO:
		timer_sorteio = 0.0
		chance_ataque += INCREMENTO_CHANCE
		
		# 3. Decisão: Se o "desejo" de atacar for satisfeito, ele sai deste estado
		if randf() * 100.0 < chance_ataque:
			decidir_ataque() # Chama go_to_soco, go_to_garrafa, etc.

func punch_state(delta):
	ataque_timer -= delta
	
	# Hitbox ativa quase instantaneamente (no frame 2 da anim)
	if ataque_timer <= 0.2 and ataque_timer > 0.1:
		set_hitbox_soco_active(true)
	else:
		set_hitbox_soco_active(false)
		
	if ataque_timer <= 0:
		go_to_cooldown_state()
#=============
func go_to_andando_state():
	status_atual = BossState.IDLE # Mantemos o Enum IDLE internamente ou mudamos para ANDANDO
	chance_ataque = 0.0
	timer_sorteio = 0.0
	modulate = Color.WHITE
	sprite.play("andar") # A animação de caminhada dele
	print("BOSS: Iniciando perseguição e sorteio...")

func go_to_cooldown_state():
	status_atual = BossState.COOLDOWN
	timer_sorteio = TEMPO_COOLDOWN
	modulate = Color(0.5, 0.5, 0.5)

# Funções de ataque permanecem com os Prints por enquanto
func go_to_punch_state():
	status_atual = BossState.ATTACKING
	ataque_timer = 0.3 
	velocity.x = 0
	update_visual_direction()
	sprite.play("soco")
	modulate = Color.RED

func go_to_bottle_state():
	status_atual = BossState.ATTACKING
	modulate = Color.GREEN
	print("BOSS: [ATAQUE] Arremessando Garrafa!")
	await get_tree().create_timer(1.2).timeout
	go_to_cooldown_state()

func go_to_briefcase_state():
	status_atual = BossState.ATTACKING
	modulate = Color.YELLOW
	print("BOSS: [ATAQUE] Maleta Giratória!")
	await get_tree().create_timer(2.5).timeout
	go_to_cooldown_state()

func go_to_dash_state():
	status_atual = BossState.ATTACKING
	modulate = Color.ORANGE
	print("BOSS: [ATAQUE] Dash de Fogo!")
	await get_tree().create_timer(0.8).timeout
	go_to_cooldown_state()

func go_to_laser_state():
	status_atual = BossState.ATTACKING
	modulate = Color.CYAN
	print("BOSS: [ATAQUE] Hyper Beam Laser!")
	await get_tree().create_timer(3.0).timeout
	go_to_cooldown_state()

# Função auxiliar para ligar/desligar a hitbox com segurança
func set_hitbox_soco_active(active: bool):
	hitbox_soco.monitoring = active
	# Se você quiser que o soco mude de lado com o Boss:
	if active:
		# Garante que a hitbox acompanhe o lado que o boss está olhando
		hitbox_soco.scale.x = -1 if sprite.flip_h else 1

func take_damage(amount: float, from_position: Vector2 = Vector2.ZERO, _direction: Vector2 = Vector2.ZERO, _is_projectile: bool = false):
	health -= amount
	# Feedback visual de dano
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(10, 10, 10), 0.05)
	tween.tween_property(self, "modulate", Color.WHITE, 0.05)

	if current_phase == Phase.PHASE_1 and health <= 50.0:
		trigger_phase_transition(Phase.PHASE_2)
	elif current_phase == Phase.PHASE_2 and health <= 25.0:
		trigger_phase_transition(Phase.PHASE_3)
	elif health <= 0:
		die()

func trigger_phase_transition(nova_fase: Phase):
	current_phase = nova_fase
	status_atual = BossState.TRANSITION
	print("BOSS: Transição para a FASE ", current_phase)
	await get_tree().create_timer(2.0).timeout
	go_to_andando_state()

func die():
	status_atual = BossState.DEAD
	queue_free()


func _on_hitbox_soco_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("BOSS: Player atingido pelo soco!")
		# Se seu player tiver a função take_damage:
		if body.has_method("take_damage"):
			body.take_damage(15, global_position, Vector2.ZERO)
