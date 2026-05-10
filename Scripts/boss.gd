extends CharacterBody2D

# ============================================================
# ENUMS
# ============================================================
enum BossState {
	idle_chase,
	melee_attack,
	throw_bottles,  # Exclusivo Fase 1
	charge_attack,  # Fase 2+
	hyper_beam,     # Fase 3
	dead
}

enum BossPhase {
	phase_1,
	phase_2,
	phase_3
}

# ============================================================
# SINAIS
# ============================================================
signal phase_changed(new_phase: BossPhase)
signal boss_died
signal vida_alterada(nova_vida: int)

# ============================================================
# REFERÊNCIAS AOS NÓS
# ============================================================
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var detection_area: Area2D = $DetectionArea
@onready var melee_hitbox: Area2D = $MeleeHitbox
@onready var wall_checker_left: RayCast2D = $WallCheckerLeft
@onready var wall_checker_right: RayCast2D = $WallCheckerRight

# Cenas a instanciar
const SHARD_SCENE      = preload("res://Entities/bottle_shard.tscn")
const BOTTLE_SCENE     = preload("res://Entities/bottle_projectile.tscn")
const SODA_JET_SCENE   = preload("res://Entities/soda_jet_bottle.tscn")
const FIRE_TRAIL_SCENE = preload("res://Entities/fire_trail.tscn")
const LASER_SCENE      = preload("res://Entities/hyper_beam_laser.tscn")

# ============================================================
# CONSTANTES DE CONFIGURAÇÃO
# ============================================================
# --- Sistema de Probabilidade ---
var chance_de_ataque: float = 0.0  # Começa em 0%
var acumulador_timer: float = 0.0
const INTERVALO_ACUMULAR = 1    # A cada 0.5s ganha +20% de chance

# --- Sistema de Anti-Repetição ---
var ultimo_ataque: String = ""
var repeticoes_ataque: int = 0

# --- Vida e Fases ---
const MAX_HEALTH        = 10
const PHASE_2_THRESHOLD = 0.60  # 60% de vida → Fase 2
const PHASE_3_THRESHOLD = 0.25  # 25% de vida → Fase 3

# --- Movimentação ---
const WALK_SPEED        = 80.0
const CHARGE_SPEED      = 380.0

# --- Distâncias de Decisão ---
const MELEE_RANGE       = 80.0   # Distância para usar ataque melee
const THROW_RANGE       = 100.0  # Distância mínima para arremessar
const CHARGE_RANGE      = 125.0  # Distância para iniciar a carga
const BEAM_RANGE        = 200.0  # Distância para usar o hyper beam

# --- Cooldowns de Ataque (em segundos) ---
const MELEE_COOLDOWN    = 1.8
const THROW_COOLDOWN    = 4.0
const CHARGE_COOLDOWN   = 5.0
const BEAM_COOLDOWN     = 7.0

# --- Rastro de Fogo ---
const FIRE_TRAIL_INTERVAL = 0.12  # Spawn de partícula a cada 0.12s

# ============================================================
# VARIÁVEIS DE ESTADO
# ============================================================
var state: BossState = BossState.idle_chase
var phase: BossPhase = BossPhase.phase_1
var health: int      = MAX_HEALTH
var is_dead: bool    = false

var player: Node2D   = null  # Referência ao player (preenchida no _ready)

# --- Timers de Cooldown ---
var melee_cooldown_timer:  float = 0.0
var throw_cooldown_timer:  float = 0.0
var charge_cooldown_timer: float = 0.0
var beam_cooldown_timer:   float = 0.0
# --- Controle de Carga (Charge Attack) ---
var charge_direction:      int   = 0    # -1 esquerda, 1 direita
var fire_trail_timer:      float = 0.0

# --- Controle do Hyper Beam ---
var beam_instance: Node2D  = null

# ============================================================
# _READY
# ============================================================
func _ready() -> void:
	add_to_group("enemy")
	melee_hitbox.monitoring = false
	player = get_tree().get_first_node_in_group("player")
	go_to_idle_chase()

# ============================================================
# _PHYSICS_PROCESS
# ============================================================
func _physics_process(delta: float) -> void:
	if is_dead:
		return

	_update_cooldowns(delta)
	_apply_gravity(delta)
	_check_phase_transition()
	_update_state(delta)
	_update_flip()
	move_and_slide()

# ============================================================
# GRAVIDADE
# ============================================================
func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

# ============================================================
# ATUALIZAÇÃO DE COOLDOWNS
# ============================================================
func _update_cooldowns(delta: float) -> void:
	if state == BossState.idle_chase:
		acumulador_timer += delta
		if acumulador_timer >= INTERVALO_ACUMULAR:
			acumulador_timer = 0.0
			chance_de_ataque = min(100.0, chance_de_ataque + 20.0)
			print("Medidor de Chance: ", chance_de_ataque, "%")
			
			# O segredo está aqui: Ele só tenta a sorte UMA VEZ 
			# a cada 0.5s (ou o tempo que você definiu)
			if randf() * 100.0 < chance_de_ataque:
				decidir_ataque()

# ============================================================
# TRANSIÇÃO DE FASE (por sinal)
# ============================================================
func _check_phase_transition() -> void:
	var pct := float(health) / float(MAX_HEALTH)

	if phase == BossPhase.phase_1 and pct <= PHASE_2_THRESHOLD:
		_enter_phase(BossPhase.phase_2)
	elif phase == BossPhase.phase_2 and pct <= PHASE_3_THRESHOLD:
		_enter_phase(BossPhase.phase_3)

func _enter_phase(new_phase: BossPhase) -> void:
	phase = new_phase
	phase_changed.emit(new_phase)
	# Removido o match com as animações de transformação e o await
	print("Fase alterada para: ", new_phase)

# ============================================================
# STATE MACHINE — DESPACHO CENTRAL
# ============================================================
func _update_state(delta: float) -> void:
	match state:
		BossState.idle_chase:   _state_idle_chase()
		BossState.melee_attack: pass  # Gerenciado por sinais da animação
		BossState.throw_bottles:pass  # Gerenciado por sinais da animação
		BossState.charge_attack:_state_charge(delta)
		BossState.hyper_beam:   pass  # Gerenciado por sinais
		BossState.dead:         pass

# ============================================================
# ESTADO: IDLE_CHASE
# Caminha em direção ao player e decide qual ataque usar.
# ============================================================
func _state_idle_chase() -> void:
	if not player or state != BossState.idle_chase:
		return
	
	# Remova o randf() daqui de dentro! 
	# Agora o _state_idle_chase serve APENAS para mover o Boss.
	_mover_em_direcao_ao_player()

func decidir_ataque():
	chance_de_ataque = 0.0
	
	var dist := global_position.distance_to(player.global_position)
	var ataques_possiveis = []

	# --- ATAQUES SEMPRE DISPONÍVEIS (RANDOMIZADOS) ---
	# O soco e as garrafas agora podem ser sorteados de qualquer lugar
	ataques_possiveis.append("melee")
	
	if phase == BossPhase.phase_1:
		ataques_possiveis.append("throw")

	if phase == BossPhase.phase_3:
		ataques_possiveis.append("beam")

	# --- ATAQUES COM VERIFICAÇÃO (APENAS O CHARGE) ---
	# A carga só entra no sorteio se ele estiver longe o suficiente
	if phase != BossPhase.phase_1 and dist >= CHARGE_RANGE:
		ataques_possiveis.append("charge")

	if ataques_possiveis.size() == 0:
		return

	# 1. Sorteio inicial
	var escolha = ataques_possiveis[randi() % ataques_possiveis.size()]

	# 2. Verificação de Repetição (Máximo 2 vezes)
	if escolha == ultimo_ataque and repeticoes_ataque >= 2:
		ataques_possiveis.erase(escolha)
		
		if ataques_possiveis.size() > 0:
			escolha = ataques_possiveis[randi() % ataques_possiveis.size()]
		else:
			return # Se não houver outra opção, ele espera o próximo ciclo

	# 3. Atualização da memória de repetição
	if escolha == ultimo_ataque:
		repeticoes_ataque += 1
	else:
		ultimo_ataque = escolha
		repeticoes_ataque = 1

	# 4. Execução
	print("BOSS: Sorteio puramente aleatório escolheu: ", escolha)
	_executar_ataque_sorteado(escolha)

func _mover_em_direcao_ao_player() -> void:
	var dir: float = sign(player.global_position.x - global_position.x)
	velocity.x = dir * WALK_SPEED
	sprite.play("Andando1")

func _executar_ataque_sorteado(tipo: String) -> void:
	match tipo:
		"melee": go_to_melee_attack()
		"throw": go_to_throw_bottles()
		"charge": go_to_charge_attack()
		"beam": go_to_hyper_beam()

# ============================================================
# ESTADO: CHARGE ATTACK
# Avança em linha reta até bater na parede, gerando rastro de fogo.
# ============================================================
func _state_charge(delta: float) -> void:
	velocity.x = charge_direction * CHARGE_SPEED
	velocity.y = 0  # Mantém no chão durante a carga

	# --- Rastro de Fogo ---
	fire_trail_timer -= delta
	if fire_trail_timer <= 0:
		fire_trail_timer = FIRE_TRAIL_INTERVAL
		_spawn_fire_trail()

	# --- Condição de Parada: colidiu com parede ---
	var hit_wall := (charge_direction > 0 and wall_checker_right.is_colliding()) or \
				   (charge_direction < 0 and wall_checker_left.is_colliding())

	if hit_wall:
		velocity.x = 0
		go_to_idle_chase()

# ============================================================
# FUNÇÕES GO_TO_STATE
# ============================================================
func go_to_idle_chase() -> void:
	state = BossState.idle_chase
	melee_hitbox.monitoring = false

func go_to_melee_attack() -> void:
	state = BossState.melee_attack
	melee_cooldown_timer = MELEE_COOLDOWN
	velocity.x = 0
	melee_hitbox.monitoring = true
	sprite.play("Gancho1")
	# A saída do estado ocorre em _on_sprite_animation_finished

func go_to_throw_bottles() -> void:
	print("LOG: Entrou no estado de Arremessar")
	state = BossState.throw_bottles
	velocity.x = 0
	sprite.play("Arremessar")

func go_to_charge_attack() -> void:
	if not player:
		return
	state = BossState.charge_attack
	charge_cooldown_timer = CHARGE_COOLDOWN
	charge_direction = sign(player.global_position.x - global_position.x)
	fire_trail_timer = 0.0  # Spawna o primeiro rastro imediatamente
	sprite.play("Carga2")

func go_to_hyper_beam() -> void:
	state = BossState.hyper_beam
	beam_cooldown_timer = BEAM_COOLDOWN
	velocity.x = 0
	sprite.play("Hiper_Beam_Inicio")
	# O laser é instanciado em _on_sprite_animation_finished

func go_to_dead() -> void:
	state = BossState.dead
	is_dead = true
	melee_hitbox.monitoring = false
	velocity = Vector2.ZERO
	sprite.play("Morte")
	boss_died.emit()
	# A cena é removida em _on_sprite_animation_finished

# ============================================================
# FLIP DO SPRITE (olha sempre para o player)
# Só atualiza se não estiver em carga (direção travada)
# ============================================================
func _update_flip() -> void:
	if state == BossState.charge_attack:
		sprite.flip_h = (charge_direction < 0)
		return
	if player and state == BossState.idle_chase:
		sprite.flip_h = (player.global_position.x < global_position.x)
	
# ============================================================
# SINAIS DA ANIMAÇÃO — Animation Finished
# ============================================================
func _on_animated_sprite_2d_animation_finished() -> void:
	match state:
		BossState.melee_attack:
			melee_hitbox.monitoring = false
			go_to_idle_chase()

		BossState.throw_bottles:
			go_to_idle_chase()

		BossState.hyper_beam:
			# "Hiper_Beam_Inicio" terminou → dispara o laser
			if sprite.animation == "Hiper_Beam_Inicio":
				_fire_hyper_beam()
				sprite.play("Hiper_Beam_Loop")  # Toca enquanto o laser existe

		BossState.dead:
			queue_free()
	
	

# ============================================================
# LÓGICA DE ARREMESSO — FASE 1
# Escolhe aleatoriamente entre Cacos ou Jato de Refri
# ============================================================
func _decide_throw_variant() -> void:
	# Print para debug - se isso não aparecer no console, o sinal está errado
	print("BOSS: Tentando spawnar garrafa...")
	
	if randf() < 0.6:
		_throw_shards()
	else:
		_throw_soda_jet()

func _throw_shards() -> void:
	var bottle = BOTTLE_SCENE.instantiate()
	get_parent().add_child(bottle)
	bottle.global_position = global_position + Vector2(30, -20)
	# Setup: Direção, Ângulo, modo_soda = false
	bottle.setup(1, 0, false) 

func _throw_soda_jet() -> void:
	var bottle = BOTTLE_SCENE.instantiate()
	get_parent().add_child(bottle)
	bottle.global_position = global_position + Vector2(30, -20)
	# Setup: Direção, Ângulo, modo_soda = true
	bottle.setup(1, 0, true)

# ============================================================
# FUNÇÃO MODULAR — SPAWN DO RASTRO DE FOGO
# ============================================================
func _spawn_fire_trail() -> void:
	var trail = FIRE_TRAIL_SCENE.instantiate()
	# Posiciona no chão sob o boss
	trail.global_position = global_position + Vector2(0, 8)
	get_parent().add_child(trail)

# ============================================================
# FUNÇÃO MODULAR — HYPER BEAM
# ============================================================
func _fire_hyper_beam() -> void:
	if beam_instance and is_instance_valid(beam_instance):
		beam_instance.queue_free()

	beam_instance = LASER_SCENE.instantiate()
	var dir := -1 if sprite.flip_h else 1
	beam_instance.global_position = global_position + Vector2(20 * dir, -50)
	beam_instance.direction = dir
	get_parent().add_child(beam_instance)

	# O laser se destrói sozinho (via timer interno no laser.tscn)
	# Mas garantimos a saída do estado aqui também
	await get_tree().create_timer(3.5).timeout
	if is_instance_valid(beam_instance):
		beam_instance.queue_free()
	if state == BossState.hyper_beam:
		go_to_idle_chase()

# ============================================================
# SISTEMA DE DANO (chamado pelo player)
# ============================================================
func take_damage(amount: int, from_position: Vector2, _direction: Vector2 = Vector2.ZERO) -> void:
	if is_dead:
		return

	health = max(0, health - amount)
	vida_alterada.emit(health)

	# --- Efeito Visual de Flash ---
	# --- Efeito Visual de Flash ---
	var tween = create_tween()
	# Liga o shader (fica todo branco)
	tween.tween_property(sprite.material, "shader_parameter/active", true, 0.0)
	# Espera 0.1 segundos
	tween.tween_interval(0.1)
	# Desliga o shader (volta ao normal)
	tween.tween_property(sprite.material, "shader_parameter/active", false, 0.0)

	if health <= 0:
		go_to_dead()
		return
	
	# O Boss continua o que estava fazendo, apenas brilha por 0.2s

# ============================================================
# HITBOX DO ATAQUE MELEE ACERTOU O PLAYER
# ============================================================
func _on_melee_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(1, global_position)


# MUITO IMPORTANTE: Verifique se o nome da animação no Sprite é exatamente "Arremessar"
func _on_animated_sprite_2d_frame_changed() -> void:
	# Este print vai disparar CADA VEZ que o boss mudar de frame
	# Se ele não aparecer no console, o sinal não está conectado!
	# print("Frame atual: ", sprite.frame, " na animação: ", sprite.animation)

	if state == BossState.throw_bottles:
		if sprite.frame == 1:
			print("LOG: Frame 1 atingido! Chamando spawn...")
			_decide_throw_variant()

func _ataque_cruz_de_soda() -> void:
	for i in 4:
		var jet = SODA_JET_SCENE.instantiate()
		# Define o ângulo de cada braço da cruz (0, 90, 180, 270 graus)
		jet.angle_offset = (PI / 2.0) * i 
		jet.global_position = global_position # Nasce no Boss
		# jet.center_point = global_position # Se precisar seguir o Boss
		get_parent().add_child(jet)
