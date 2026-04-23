extends CharacterBody2D

# Referências aos Nós
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
# Escolha no Inspetor do Godot: 0 para Boy, 1 para Girl
@export_enum("Boy", "Girl") var gender: int = 0
var gender_suffix: String = ""

# --- CONFIGURAÇÕES (CONSTANTES) ---
const FLOAT_AMPLITUDE = 8.0     # Balanço visual (pixels)
const FLOAT_SPEED = 2.0         # Velocidade do balanço
const DETECT_RANGE = 160.0      # Visão do fantasma
const DASH_DISTANCE = 150.0     # Distância máxima do bote
const DASH_SPEED = 250.0        # Velocidade do bote (mais rápido agora)
const PREPARA_TIME = 0.4        # Tempo de aviso (diminuído a seu pedido)
const ATTACK_COOLDOWN = 1.5     # Tempo de espera entre ataques
const RETURN_SPEED = 70.0       # Velocidade voltando ao spawn

# --- ESTADOS DO INIMIGO ---
enum State { IDLE, PREPARING, DASHING, COOLDOWN, RETURN }

# --- VARIÁVEIS DE ATRIBUTOS ---
var current_state = State.IDLE
var health = 2
var spawn_position = Vector2.ZERO
var player = null

# --- VARIÁVEIS DE CONTROLE DE TEMPO E MOVIMENTO ---
var time_passed = 0.0           # Controle do seno (flutuar)
var attack_timer = 0.0          # Cronômetro para preparo/cooldown
var dash_direction = Vector2.ZERO # Direção travada do ataque
var dash_start_pos = Vector2.ZERO # Onde o ataque começou para medir distância

# =========================================================
# Função chamada quando o inimigo entra na cena
# Responsabilidade: Configuração inicial e grupos
# =========================================================
func _ready():
	add_to_group("enemy")
	spawn_position = global_position
	player = get_tree().get_first_node_in_group("player")
	
	# Define o sufixo baseado na escolha do editor
	gender_suffix = "_Boy" if gender == 0 else "_Girl"
	go_to_idle() # Começa com a animação correta

# =========================================================
# Loop principal da física
# Responsabilidade: Orquestrar estados e efeitos visuais
# =========================================================
func _physics_process(delta):
	visual_float(delta)         # Sempre flutua visualmente
	update_state(delta)         # Lógica da State Machine
	move_and_slide()            # Executa o movimento final

# =========================================================
# Gerencia a troca de comportamentos baseada no estado
# Responsabilidade: Máquina de Estados (State Machine)
# =========================================================
func update_state(delta):
	match current_state:
		State.IDLE:
			idle_state()
		State.PREPARING:
			preparing_state(delta)
		State.DASHING:
			dashing_state()
		State.COOLDOWN:
			cooldown_state(delta)
		State.RETURN:
			return_state()

# =========================================================
# Estado Parado: Fica vigiando a área
# Responsabilidade: Detectar o jogador para iniciar ataque
# =========================================================
func idle_state():
	velocity = Vector2.ZERO
	if player:
		var dist = global_position.distance_to(player.global_position)
		if dist < DETECT_RANGE:
			# Só entra no preparo se já não estiver nele
			dash_direction = global_position.direction_to(player.global_position)
			dash_start_pos = global_position
			
			attack_timer = PREPARA_TIME # Reinicia o cronômetro de preparo
			current_state = State.PREPARING # Muda o estado

# =========================================================
# Estado de Preparação: O "Aviso" do ataque
# Responsabilidade: Dar tempo de reação e feedback visual (tremer)
# =========================================================
func preparing_state(delta):
	velocity = Vector2.ZERO
	attack_timer -= delta # O tempo vai diminuindo aqui
	
	# Efeito visual de tremer
	if sprite:
		sprite.position.x = randf_range(-3, 3) 
	
	# SÓ ATACA QUANDO O TIMER ZERAR
	if attack_timer <= 0:
		if sprite: sprite.position.x = 0 
		go_to_dash() # Só aqui ele vira um "míssil"

# =========================================================
# Estado de Dash: O bote em linha reta fixa
# Responsabilidade: Mover o fantasma até a distância máxima
# =========================================================
func dashing_state():
	velocity = dash_direction * DASH_SPEED
	
	if sprite:
		sprite.position.x = 0
		sprite.flip_h = (velocity.x < 0)
	
	# Verifica se já percorreu a distância limite do dash
	if global_position.distance_to(dash_start_pos) >= DASH_DISTANCE:
		velocity = Vector2.ZERO
		attack_timer = ATTACK_COOLDOWN 
		
		# --- O TRUQUE ESTÁ AQUI ---
		current_state = State.COOLDOWN # Mantém a lógica de espera (não ataca)
		sprite.play("Idle" + gender_suffix) # Muda o visual para Idle imediatamente
		print("LOG: Dash concluído, descansando em pose Idle.")

# =========================================================
# Estado de Cooldown: Descanso após o bote
# Responsabilidade: Impedir ataques seguidos e checar fuga do player
# =========================================================
func cooldown_state(delta):
	velocity = Vector2.ZERO
	attack_timer -= delta
	
	# Se o player fugir, ele volta para o spawn
	if player and global_position.distance_to(player.global_position) > DETECT_RANGE * 1.2:
		current_state = State.RETURN
		return

	# Quando o descanso acaba, ele volta a vigiar (IDLE)
	if attack_timer <= 0:
		go_to_idle()

# =========================================================
# Estado de Retorno: Volta para o posto original
# Responsabilidade: Manter o fantasma na posição de spawn
# =========================================================
func return_state():
	var dir = global_position.direction_to(spawn_position)
	velocity = dir * RETURN_SPEED
	
	if sprite:
		sprite.flip_h = (velocity.x < 0)
		
	if global_position.distance_to(spawn_position) < 10.0:
		global_position = spawn_position
		go_to_idle() # <--- Troque current_state por isso

func go_to_idle():
	current_state = State.IDLE
	sprite.play("Idle" + gender_suffix)

func go_to_dash():
	current_state = State.DASHING
	sprite.play("Dash" + gender_suffix)

# =========================================================
# Efeito Visual de Flutuar
# Responsabilidade: Mover apenas o Sprite (não a colisão) suavemente
# =========================================================
func visual_float(delta):
	time_passed += delta
	# Não balança enquanto está tremendo na preparação
	if sprite and current_state != State.PREPARING:
		sprite.position.y = sin(time_passed * FLOAT_SPEED) * FLOAT_AMPLITUDE

# =========================================================
# Recebe dano com imunidade seletiva
# Responsabilidade: Filtro de distância (Só aceita tiro de longe)
# =========================================================
# No script do INIMIGO (enemy.gd)
func take_damage(amount, _from_position, _direction, is_projectile = false):
	# Se NÃO for um projétil, o fantasma ignora o dano
	if not is_projectile:
		print("LOG: Fantasma é imune a ataques físicos!")
		# Opcional: Tocar um som de "erro" ou faísca
		return 
	
	# Se for projétil, segue a vida normal
	health -= amount
	print("Fantasma atingido por projétil! Vida: ", health)
	
	if health <= 0:
		queue_free()
# =========================================================
# Remove o inimigo da cena
# Responsabilidade: Morte
# =========================================================
func die():
	queue_free()

# =========================================================
# Detecta colisão com o player para causar dano
# Responsabilidade: Causar dano no Santa Vingança
# =========================================================

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		# SÓ entra se o status do player NÃO for 'possessed'
		if body.status != body.PlayerState.possessed:
			if body.has_method("go_to_possessed_state"):
				body.go_to_possessed_state(self)
				queue_free() # Fantasma entra no player
		else:
			# Se ele já está possuído, o fantasma apenas dá um dano normal ou some
			print("Player já está possuído, ignorando!")
			# Opcional: queue_free() aqui também se quiser que o fantasma bata e suma
