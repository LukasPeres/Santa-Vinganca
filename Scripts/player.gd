extends CharacterBody2D #Herda Mobilidade e colisão (velocity, 
#move_and_slide() e in_on_floor() (retorna true or false)

#Estados do player (State Machine) - Bom para organização do código
enum PlayerState{
	idle,
	walk,
	jump,
	attack,
	dash,
	slide, 
	possessed
}

#State Machine das armas
enum WeaponType{
	melee,
	gun,
	elf_gun
}

#Referencia aos Nós
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D #Controla animações
@onready var hitbox: Area2D = $Hitbox #Controla Hitbox

var combo_stage: int = 0 # 0 = nenhum, 1 = primeiro ataque, 2 = segundo
var combo_window_timer: float = 0.0 # Timer para o 1 segundo de janela

# --- SISTEMA DE POSSESSÃO ---
var is_spasm_active: bool = false 
var possessed_dir: int = 0
var spasm_count: int = 0
var spasm_cooldown: float = 0.0
const SPASM_CHANCES = [0.15, 0.35, 0.60, 1.0] # 15%, 35%, 60% e 100% de chance de sair

# --- CONFIGURAÇÕES (CONSTANTES) ---
const COYOTE_TIME = 0.15 # 150ms é o padrão "justo" para plataformas
var coyote_timer = 0.0    # O cronómetro que vai diminuir no ar
var slope_timer = 0.0
const SLOPE_CONFIRMATION_TIME = 0.1 # Tempo mínimo para "confirmar" que é rampa

# Movimentação Base
const SPEED = 150.0
const JUMP_VELOCITY = -300.0
const GROUND_FRICTION = 900
const AIR_FRICTION = 120
const SLIDE_ACCEL = 2000.0
const MAX_SLIDE_SPEED = 200.0
const SLIDE_JUMP_BOOST = 1.3

# Mecânicas Especiais
const DASH_SPEED = 400
const DASH_TIME = 0.15
const ATTACK_COOLDOWN_MS = 400
const MAX_DASHES = 1 # <--- Adicionado para o sistema de pulo
const WALL_JUMP_VELOCITY = -250.0 # Força para cima
const WALL_JUMP_PUSHBACK = 250.0 # Força para longe da parede
const WALL_JUMP_LOCK_TIME = 0.30 # Tempo cda trava
const WALL_SLIDE_SPEED = 50.0 # Velocidade máxima de descida na parede
const INVINCIBILITY_TIME = 1.0 # 1 segundo de invencibilidade
const KNOCKBACK_FREEZE_TIME = 0.2 # Tempo que o player perde o controle ao ser atingido

# --- ESTADOS E ATRIBUTOS (VARIÁVEIS) ---
var status: PlayerState
var health = 5
var is_dead = false

# --- CONTROLE DE TEMPO E INPUT ---
var dash_timer = 0.0
var dash_count = 0 # <--- Adicionado para contar os dashes
var input_direction = 0
var last_attack_timer = 0.0 # msec usa float/int grande
var wall_jump_timer = 0.0 # O cronômetro da trava
var invincibility_timer = 0.0
var knockback_timer = 0.0

# --- EQUIPAMENTO ---
var current_weapon = WeaponType.melee

#Função que se inicia quando o jogo começa
func _ready() -> void:
	add_to_group("player")
	hitbox.monitoring = false #Hitbox de dano desligada
	go_to_idle_state() #Começa Idle

#Gravidade - Caso o player não esteja no chão, adiciona velocidade vertical
func _physics_process(delta):
	update_timers(delta)
	handle_wall_slide(delta) # wall slide
	update_ground_resources() # resetar habilidades
	apply_gravity(delta)      # física
	update_state(delta)       # lógica da state machine
	check_weapon_swap()
	update_animation_offsets()# visual

	floor_snap_length = 8.0 if velocity.y >= 0 else 0.0
	move_and_slide()          # movimento final

func update_ground_resources():
	if is_on_floor():
		dash_count = 0

#Gravidade
func apply_gravity(delta):
	if not is_on_floor():
		velocity += get_gravity() * 0.8 * delta

func update_state(delta):
	match status:
		PlayerState.idle:
			idle_state()
		PlayerState.walk:
			walk_state()
		PlayerState.jump:
			jump_state()
		PlayerState.attack:
			attack_state()
		PlayerState.dash:
			dash_state()
		PlayerState.slide:
			slide_state()
		PlayerState.possessed:
			possessed_state(delta)

#ESTADOS
func idle_state():#Importante - Ordem: Ataque, Andar, Pular
	move() #Possibilita movimento nesse estado
	
	#Dash
	if wants_dash():
		go_to_dash_state()
		return
	
	#Quando ataque é precionado, mudamos para o estado de ataque
	if wants_attack():
		use_weapon()
		return
		
	#Quando o pulo é acionado, mudamos para o estado de pulo
	if wants_jump():
		# A condição agora é: Chão OU Timer de tolerância
		if is_on_floor() or coyote_timer > 0:
			go_to_jump_state()
			return
		elif handle_wall_jump():
			status = PlayerState.jump
			return
		
	#Quando a velocidade é diferente de 0, mudamos para o estado de andar
	if velocity.x != 0:
		go_to_walk_state()
		return
		
	if is_on_steep_slope() and velocity.y >= 0:
		slope_timer += get_physics_process_delta_time()
		if slope_timer >= SLOPE_CONFIRMATION_TIME:
			go_to_slide_state()
			slope_timer = 0.0 # Reseta para a próxima
			return
	else:
		slope_timer = 0.0 # Se saiu da rampa ou o chão ficou reto, reseta o tempo
		
func walk_state():
	move()
	
	#Dash
	if wants_dash():
		go_to_dash_state()
		return
	
	#Quando ataque é precionado, mudamos para o estado de ataque
	if wants_attack():
		use_weapon()
		return
	
	#Quando o pulo é acionado, mudamos para o estado de pulo
	if wants_jump():
		# A condição agora é: Chão OU Timer de tolerância
		if is_on_floor() or coyote_timer > 0:
			go_to_jump_state()
			return
		elif handle_wall_jump():
			status = PlayerState.jump
			return

	#Quando a velocidade é = 0, mudamos para o estado parado
	if velocity.x == 0:
		go_to_idle_state()
		return
	
	if is_on_steep_slope() and velocity.y >= 0:
		slope_timer += get_physics_process_delta_time()
		if slope_timer >= SLOPE_CONFIRMATION_TIME:
			go_to_slide_state()
			slope_timer = 0.0 # Reseta para a próxima
			return
	else:
		slope_timer = 0.0 # Se saiu da rampa ou o chão ficou reto, reseta o tempo
	
	
func jump_state():
	move()
	
	# Permite pular de novo se bater em uma parede no ar
	if wants_jump() and handle_wall_jump():
		return # O handle_wall_jump já aplicou a velocidade
		
	#Dash
	if wants_dash():
		go_to_dash_state()
		return
	
	#Quando ataque é precionado, mudamos para o estado de ataque
	if wants_attack():
		use_weapon()
		return
	
	#Se estiver no chão e a velocidade 0 vai para parado, caso contrario ande
	if is_on_floor():
		if velocity.x == 0: 
			go_to_idle_state()
		else:
			go_to_walk_state()
		return
		
func attack_state():
	move()
	
	#Quando precionar pular E estamos no chão, pula, mas não troca de estado
	#Para não quebrar a animação de ataque
	if wants_jump() and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	#Se a animação terminou, a hitbox é desligada
	if not sprite.is_playing():
		hitbox.monitoring = false
		
		#Se depois do ataque voce esta no ar, muda para pular
		if not is_on_floor():
			status = PlayerState.jump
			return
		#Se a velocidade é 0 muda pra parado
		elif velocity.x == 0:
			go_to_idle_state()
		#Se velocidade é diferente de 0 vai para andando
		else:
			go_to_walk_state()

func dash_state():
	# Se tomar dano no meio do dash, o dash cancela
	if knockback_timer > 0: 
		status = PlayerState.jump
		return
	dash_timer -= get_physics_process_delta_time()
	
	# O SEGREDO: Em cada frame do dash, nós forçamos a velocidade horizontal
	# e ZERAMOS a vertical (velocity.y = 0). 
	# Isso anula o efeito da gravidade que foi aplicado um milissegundo antes.
	var direction = -1 if sprite.flip_h else 1
	velocity.x = direction * DASH_SPEED
	velocity.y = 0 

	if dash_timer <= 0:
		# Saída suave para não deslizar no sabão
		velocity.x *= 0.3
		
		# Transição de saída (Mantendo seu padrão de funções)
		if not is_on_floor():
			status = PlayerState.jump
		else:
			if velocity.x == 0: go_to_idle_state()
			else: go_to_walk_state()

func slide_state():
	var n = get_floor_normal()
	
	if not is_on_floor():
		status = PlayerState.jump
		return

	# 1. Aceleração da rampa
	velocity.x += n.x * SLIDE_ACCEL * get_physics_process_delta_time()
	velocity.x = clamp(velocity.x, -MAX_SLIDE_SPEED, MAX_SLIDE_SPEED)


	if wants_jump():
		print("Pulo com Momentum! Vel:", velocity.x)
		if is_on_floor() or coyote_timer > 0:
			go_to_jump_state()
			return
		elif handle_wall_jump():
			status = PlayerState.jump
			return

	# 3. Saída por Terreno (Chão reto)
	if not is_on_steep_slope():
		if abs(velocity.x) > 100:
			go_to_walk_state()
		else:
			go_to_idle_state()
		return

func possessed_state(delta):
	apply_gravity(delta)
	
	if spasm_cooldown > 0:
		spasm_cooldown -= delta
	
	var target_vel = 0.0
	
	if is_spasm_active:
		# Aumentamos a força da resistência (de 0.8 para 1.5)
		# Isso vai dar aquele "tranco" para o lado oposto
		target_vel = -possessed_dir * (SPEED * 1.5) 
	else:
		# Diminuímos a velocidade do fantasma (de 0.4 para 0.25)
		# Agora ele vai arrastar o Papanel bem mais devagar
		target_vel = possessed_dir * (SPEED * 0.4)  
	
	# Aumentamos o peso do move_toward (de 10 para 20) para a resposta ser mais rápida
	velocity.x = move_toward(velocity.x, target_vel, 20)
	sprite.flip_h = (velocity.x < 0)

	if spasm_cooldown <= 0:
		if Input.is_action_just_pressed("left") or Input.is_action_just_pressed("right") or \
		   Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("attack"):
			apply_spasm()
	
	move_and_slide()
	
	#Go_to_states

func go_to_idle_state():
	status = PlayerState.idle
	hitbox.monitoring = false
	sprite.play("Idle")
	
func go_to_walk_state():
	status = PlayerState.walk
	hitbox.monitoring = false
	sprite.play("Andando")
	
func go_to_jump_state():
	status = PlayerState.jump
	hitbox.monitoring = false
	velocity.y = JUMP_VELOCITY
	sprite.play("Idle")
	coyote_timer = 0.0
	
func go_to_attack_state():
	status = PlayerState.attack
	combo_stage = 1
	combo_window_timer = 1.0 # Abre 1 segundo para o próximo clique
	sprite.play("Ataque_1") # Nome da sua primeira animação
	hitbox.monitoring = false
	
func go_to_attack_2_state():
	status = PlayerState.attack
	combo_stage = 2 # Avança o combo
	combo_window_timer = 0.0 # Reseta o timer pois já usou o combo
	sprite.play("Ataque_2") # Nome da sua segunda animação
	hitbox.monitoring = false
	
func go_to_dash_state():
	status = PlayerState.dash
	dash_timer = DASH_TIME
	dash_count += 1
	
	hitbox.monitoring = false
	
	var direction = -1 if sprite.flip_h else 1
	velocity.x = direction * DASH_SPEED
	velocity.y = 0
	
	sprite.play("Idle") # depois você pode colocar animação de dash

func go_to_slide_state():
	status = PlayerState.slide
	print("--- SLIDE ATIVADO! Inclinação: ", get_floor_normal().x)
	sprite.play("Idle") # Substitua pela animação do Pietro depois
	hitbox.monitoring = false

func go_to_possessed_state(_ghost_ref):
	print("LOG: Papanel foi possuído!")
	status = PlayerState.possessed
	spasm_count = 0
	spasm_cooldown = 0.0
	is_spasm_active = false
	
	# Decide direção: puxa para o lado mais longe do centro da tela
	var screen_pos = get_global_transform_with_canvas().origin.x
	var screen_center = get_viewport_rect().size.x / 2
	possessed_dir = 1 if screen_pos > screen_center else -1
	
	sprite.play("Idle") # Ou "Possuido" se você tiver a animação

func apply_spasm():
	spasm_count += 1
	spasm_cooldown = 0.6 
	is_spasm_active = true
	print("LOG: Tentativa de resistência nº: ", spasm_count)
	
	# Timer curto de controle
	await get_tree().create_timer(0.2).timeout
	if status == PlayerState.possessed:
		is_spasm_active = false
	
	# Cálculo de chance de liberdade
	var chance_idx = clampi(spasm_count - 1, 0, SPASM_CHANCES.size() - 1)
	var roll = randf()
	print("LOG: Roll de liberdade: ", roll, " vs Chance: ", SPASM_CHANCES[chance_idx])
	
	if roll < SPASM_CHANCES[chance_idx]:
		print("LOG: Papanel se libertou!")
		# Pequeno knockback pra cima pra dar feedback visual de que saiu
		velocity.y = -150 
		take_damage(1, global_position)
		go_to_idle_state()

func wants_jump():
	return Input.is_action_just_pressed("jump")

func wants_attack():
	var current_time = Time.get_ticks_msec()
	if Input.is_action_just_pressed("attack"):
		if current_time - last_attack_timer >= ATTACK_COOLDOWN_MS:
			last_attack_timer = current_time # Registra o momento do ataque
			return true
	return false

func wants_dash():
	return Input.is_action_just_pressed("dash") and can_dash()

func handle_wall_jump() -> bool:
	# 1. Checa se está na parede e NO AR
	if is_on_wall() and not is_on_floor():
		var wall_normal = get_wall_normal() # Retorna a direção OPOSTA à parede	
		# 2. Aplica o impulso (Normal.x empurra para longe da parede)
		velocity.x = wall_normal.x * WALL_JUMP_PUSHBACK
		velocity.y = WALL_JUMP_VELOCITY
		# 2. LIGA A TRAVA: O player não vai conseguir mudar o X por 0.15s
		wall_jump_timer = WALL_JUMP_LOCK_TIME
		#Sprite inverte
		sprite.flip_h = (wall_normal.x < 0)
		#Depois do walljump, é possivel fazer outro dash
		#dash_count = 0 
		
		return true # Wall jump aconteceu!
	return false # Não estava na parede

func handle_wall_slide(_delta):
	# Só desliza se: estiver no ar, encostado na parede e CAINDO
	if is_on_wall() and not is_on_floor() and velocity.y > 0:
		# Se a velocidade de queda for maior que o limite, a gente trava no limite
		if velocity.y > WALL_SLIDE_SPEED:
			velocity.y = WALL_SLIDE_SPEED
	
func is_on_steep_slope() -> bool:
	if is_on_floor():
		var n = get_floor_normal()
		return abs(n.x) > 0.15 # Detecta qualquer inclinação
	return false
	
func update_timers(delta):
	# Lógica do Coyote Time
	if is_on_floor():
		coyote_timer = COYOTE_TIME # Enquanto toca no chão, o tempo é máximo
	else:
		coyote_timer -= delta      # No ar, o tempo começa a esgotar-se
		
	if wall_jump_timer > 0:
		wall_jump_timer -= delta
	if invincibility_timer > 0:
		invincibility_timer -= delta
		# Efeito visual: piscar o personagem
		sprite.visible = not sprite.visible if invincibility_timer > 0 else true
	else:
		sprite.visible = true # Garante que ele termine visível

	if knockback_timer > 0:
		knockback_timer -= delta
		
	if combo_window_timer > 0:
		combo_window_timer -= delta
	else:
		# Se o tempo acabar e o player não atacou de novo, o combo volta a 0
		if status != PlayerState.attack:
			combo_stage = 0
	
#Movimentação
func move():
	if wall_jump_timer > 0 or knockback_timer > 0: return
	
	var dir = Input.get_axis("left", "right")
	
	if dir:
		var speed_multiplier = 1.2 if is_on_steep_slope() else 1.0
		
		# Lógica de Controle de Momentum
		if not is_on_floor() and abs(velocity.x) > SPEED:
			# Se você estiver indo para o mesmo lado do momentum, mantém a força
			if sign(dir) == sign(velocity.x):
				velocity.x = move_toward(velocity.x, dir * MAX_SLIDE_SPEED, 2)
			else:
				# Se apertar para o lado OPOSTO, você tem controle e freia o impulso
				velocity.x = move_toward(velocity.x, dir * SPEED, 15) 
		else:
			# Movimento normal
			velocity.x = dir * SPEED * speed_multiplier
			
		sprite.flip_h = (dir < 0)
		hitbox.scale.x = -1 if dir < 0 else 1
	else:
		# Freio: No ar o freio é menor para não parar seco
		var friction = 60 if is_on_floor() else 15
		velocity.x = move_toward(velocity.x, 0, friction)


#Sistema das Armas
func check_weapon_swap():

	if Input.is_action_just_pressed("weapon_1"):
		current_weapon = WeaponType.melee

	if Input.is_action_just_pressed("weapon_2"):
		current_weapon = WeaponType.gun

	if Input.is_action_just_pressed("weapon_3"):
		current_weapon = WeaponType.elf_gun
		
func use_weapon():
	match current_weapon:
		WeaponType.melee:
			# Se já atacou e está dentro da janela de 1 segundo
			if combo_stage == 1 and combo_window_timer > 0:
				go_to_attack_2_state()
			else:
				go_to_attack_state() # O primeiro ataque
		WeaponType.gun:
			shoot_straight()
		WeaponType.elf_gun:
			shoot_elf()

func shoot_straight():

	var bullet = preload("res://Entities/bullet.tscn").instantiate()
	get_parent().add_child(bullet)

	var direction = -1 if sprite.flip_h else 1
	bullet.global_position = global_position + Vector2(20 * direction, 0)
	bullet.direction = direction
	
func shoot_elf():

	var bullet = preload("res://Entities/elf_bullet.tscn").instantiate()
	get_parent().add_child(bullet)
	
	# 1. Primeiro definimos a direção baseada no sprite
	var dir = -1 if sprite.flip_h else 1
	
	# 2. Agora usamos "dir" para posicionar a bala um pouco à frente do player
	bullet.global_position = global_position + Vector2(20 * dir, 0)
	
	# 3. Chamamos a função de lançamento que criamos na bala
	bullet.launch(dir)

#hitbox do ataque, so funciona no grupo enemy
func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		# 1. Definimos a direção baseada no flip do sprite
		var direcao_golpe = Vector2.LEFT if sprite.flip_h else Vector2.RIGHT
		
		# 2. Chamamos a função passando os TRÊS argumentos:
		# amount (1), from_position (global_position), direcao_golpe (o vetor que criamos)
		if body.has_method("take_damage"):
			body.take_damage(1, global_position, direcao_golpe)

#Ativa a hitbox do ataque, apenas no estado de ataque
func _on_animated_sprite_2d_frame_changed() -> void:	
	if status != PlayerState.attack:
		return
	# Exemplo: O Ataque 1 bate no frame 2, o Ataque 2 bate no frame 3
	if sprite.animation == "Ataque_1":
		hitbox.monitoring = (sprite.frame == 2)
	elif sprite.animation == "Ataque_2":
		hitbox.monitoring = (sprite.frame == 3)
	
	#Garante que no frame 1 do estado ataque, a hitbox de ataque seja ativada
	if sprite.frame == 0 or 1 or 2:
		hitbox.monitoring = true
	else:
		hitbox.monitoring = false

#Sistema de vida e Knockback recebido pelo player
func take_damage(amount, from_position):
	if is_dead or invincibility_timer > 0:
		return
	# Ativa os timers
	invincibility_timer = INVINCIBILITY_TIME
	knockback_timer = KNOCKBACK_FREEZE_TIME
	
	# Aplica o empurrão (Knockback)
	var knock_dir = sign(global_position.x - from_position.x)
	velocity.x = knock_dir * 250 # Força horizontal
	velocity.y = -200           # Força vertical (pulinho)
	
	health -= amount
	print("Player vida:", health)
	
	# Knockback (opcional, mas recomendado)
	var direction = sign(global_position.x - from_position.x)
	velocity.x = direction * 150
	velocity.y = -150
	
	if health <= 0:
		die()

#Sistema de Morte
func die():
	is_dead = true
	print("Player morreu")
	call_deferred("reload_scene")
	
func reload_scene():
	get_tree().reload_current_scene()
	
func update_animation_offsets():
	# Reset padrão para evitar que um estado suje o outro
	sprite.offset = Vector2.ZERO

	if status == PlayerState.possessed and is_spasm_active:
		# Tremor visual forte no eixo X
		# Escolhe um número aleatório entre -4 e 4 a cada frame
		sprite.offset.x = randf_range(-7, 7) 
		# Mantém o pé no chão do Idle
		sprite.offset.y = -1
		
	if status == PlayerState.attack:
		# Aqui é o segredo: mudamos o offset baseado no NOME da animação
		if sprite.animation == "Ataque_1":
			sprite.offset.y = -10  # Ajuste para o primeiro golpe
			sprite.offset.x = 0   # Se precisar mover para os lados também
		elif sprite.animation == "Ataque_2":
			sprite.offset.y = -8  # Ajuste diferente para o segundo golpe
			sprite.offset.x = 2   # Exemplo: se ele der um passo a frente
			
	# 2. Se não estiver atacando, segue a lógica normal dos outros estados
	else:
		match status:
			PlayerState.idle:
				sprite.offset.y = -1
			PlayerState.walk:
				sprite.offset.y = 0
			PlayerState.jump:
				sprite.offset.y = -2 # Exemplo caso o pulo também precise
			
func can_dash() -> bool:
	return dash_count < MAX_DASHES
