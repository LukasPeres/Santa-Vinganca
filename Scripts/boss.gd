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
	stagger,
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
const CHARGE_RANGE      = 150.0  # Distância para iniciar a carga
const BEAM_RANGE        = 200.0  # Distância para usar o hyper beam

# --- Cooldowns de Ataque (em segundos) ---
const MELEE_COOLDOWN    = 1.8
const THROW_COOLDOWN    = 4.0
const CHARGE_COOLDOWN   = 5.0
const BEAM_COOLDOWN     = 7.0
const STAGGER_DURATION  = 1.0

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
var stagger_timer:         float = 0.0

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
	melee_cooldown_timer  = max(0.0, melee_cooldown_timer  - delta)
	throw_cooldown_timer  = max(0.0, throw_cooldown_timer  - delta)
	charge_cooldown_timer = max(0.0, charge_cooldown_timer - delta)
	beam_cooldown_timer   = max(0.0, beam_cooldown_timer   - delta)
	if stagger_timer > 0:
		stagger_timer -= delta

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

	match new_phase:
		BossPhase.phase_2:
			# Animação de transformação — toca e espera terminar
			sprite.play("Transformacao_Fase2")
			await sprite.animation_finished
			go_to_idle_chase()

		BossPhase.phase_3:
			sprite.play("Transformacao_Fase3")
			await sprite.animation_finished
			go_to_idle_chase()

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
		BossState.stagger:      _state_stagger()
		BossState.dead:         pass

# ============================================================
# ESTADO: IDLE_CHASE
# Caminha em direção ao player e decide qual ataque usar.
# ============================================================
func _state_idle_chase() -> void:
	if not player:
		return

	var dist := global_position.distance_to(player.global_position)

	# --- PRIORIDADE DE ATAQUE (ordem importa) ---

	# 1. Hyper Beam (Fase 3, longa distância)
	if phase == BossPhase.phase_3 and dist >= BEAM_RANGE and beam_cooldown_timer <= 0:
		go_to_hyper_beam()
		return

	# 2. Carga / Investida (Fase 2+, média-longa distância)
	if phase != BossPhase.phase_1 and dist >= CHARGE_RANGE and charge_cooldown_timer <= 0:
		go_to_charge_attack()
		return

	# 3. Arremesso de Garrafas (apenas Fase 1, distância média)
	if phase == BossPhase.phase_1 and dist >= MELEE_RANGE and dist <= THROW_RANGE and throw_cooldown_timer <= 0:
		go_to_throw_bottles()
		return

	# 4. Melee (curto alcance, todas as fases)
	if dist <= MELEE_RANGE and melee_cooldown_timer <= 0:
		go_to_melee_attack()
		return

	# 5. Caminhar em direção ao player
	var dir: float = sign(player.global_position.x - global_position.x)
	velocity.x = dir * WALK_SPEED
	sprite.play("Andando1")

# ============================================================
# ESTADO: STAGGER
# Boss toma dano, para brevemente.
# ============================================================
func _state_stagger() -> void:
	velocity.x = 0
	if stagger_timer <= 0:
		go_to_idle_chase()

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
		go_to_stagger()  # Atordoa brevemente ao bater

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
	state = BossState.throw_bottles
	throw_cooldown_timer = THROW_COOLDOWN
	velocity.x = 0
	sprite.play("Arremessar")
	# O spawn ocorre via frame_changed para sincronia com a animação

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

func go_to_stagger() -> void:
	state = BossState.stagger
	stagger_timer = STAGGER_DURATION
	velocity.x = 0
	melee_hitbox.monitoring = false
	sprite.play("Stagger")

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
# SINAIS DA ANIMAÇÃO — Frame Changed
# Usado para sincronizar spawns com frames específicos
# ============================================================
func _on_animated_sprite_2d_animation_changed() -> void:
		# --- Sincroniza o spawn do projétil com o frame de lançamento ---
	if state == BossState.throw_bottles and sprite.frame == 4:
		_decide_throw_variant()

	# --- Ativa a hitbox no frame correto do Gancho ---
	if state == BossState.melee_attack:
		melee_hitbox.monitoring = (sprite.frame >= 2 and sprite.frame <= 4)

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
	if randf() < 0.6:
		_throw_shards()   # 60% de chance: Cacos
	else:
		_throw_soda_jet() # 40% de chance: Jato de Refri

func _throw_shards() -> void:
	# Arremessa 3 garrafas em arcos ligeiramente diferentes
	var dir := -1 if sprite.flip_h else 1
	var offsets := [-15.0, 0.0, 15.0]  # Ângulos em graus
	for angle_offset in offsets:
		var bottle = BOTTLE_SCENE.instantiate()
		bottle.global_position = global_position + Vector2(30 * dir, -40)
		bottle.setup(dir, angle_offset, true)  # true = é do tipo "cacos"
		get_parent().add_child(bottle)

func _throw_soda_jet() -> void:
	# Uma garrafa que para no ar e gira disparando jatos
	var dir := -1 if sprite.flip_h else 1
	var jet_bottle = SODA_JET_SCENE.instantiate()
	jet_bottle.global_position = global_position + Vector2(60 * dir, -60)
	get_parent().add_child(jet_bottle)

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

	if health <= 0:
		go_to_dead()
		return

	# Cancela estados ativos que devem ser interrompidos por dano
	if state == BossState.charge_attack:
		if is_instance_valid(beam_instance):
			beam_instance.queue_free()
		go_to_stagger()
		return

	go_to_stagger()

# ============================================================
# HITBOX DO ATAQUE MELEE ACERTOU O PLAYER
# ============================================================
func _on_melee_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(1, global_position)
