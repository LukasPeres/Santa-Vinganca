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
	possessed,
	throw
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

var direcao_forcada: int = 0 # 0 = normal, 1 = direita, -1 = esquerda
var ja_arremessou = false # Evita que nasçam 50 balas no mesmo frame
var pode_se_mexer = true
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
const DASH_COOLDOWN = 0.3 # Tempo de espera entre um dash e outro (em segundos)
var dash_cooldown_timer = 0.0 # O cronómetro que vai diminuir com o tempo
const DASH_SPEED = 300
const DASH_TIME = 0.22
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
	direcao_forcada = 0

#Gravidade - Caso o player não esteja no chão, adiciona velocidade vertical
func _physics_process(delta):
	if not pode_se_mexer:
		velocity = Vector2.ZERO # Faz o player parar imediatamente
		move_and_slide()
		return # Sai da função e ignora os inputs de movimento
	update_timers(delta)
	handle_wall_slide(delta) # wall slide
	update_ground_resources() # resetar habilidades
	apply_gravity(delta)      # física
	update_state(delta)       # lógica da state machine
	check_weapon_swap()
	update_animation_offsets()# visual
	aplicar_rotacao_slide(delta) # <--- Adicione aqui

	floor_snap_length = 8.0 if velocity.y >= 0 else 0.0
	move_and_slide()          # movimento final

func update_ground_resources():
	if is_on_floor():
		dash_count = 0

#Gravidade
func apply_gravity(delta):
	# Se estiver escorregando na parede, não aplicamos gravidade normal
	# Isso evita que ele "acelere" nas quinas entre blocos
	if sprite.animation == "Escorregar" and is_on_wall():
		velocity.y = WALL_SLIDE_SPEED
		return

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
		PlayerState.throw: 
			throw_state()  
#ESTADOS
func idle_state():#Importante - Ordem: Ataque, Andar, Pular
	move() #Possibilita movimento nesse estado
	if not is_on_floor():
		go_to_falling()
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
	if not is_on_floor():
		go_to_falling()
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
	if velocity.y > 0 and sprite.animation == "Pulando":
		go_to_falling()
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
			
			# Transição de saída
		if not is_on_floor():
				# EM VEZ DE SÓ MUDAR O STATUS:
				# Chamamos a função que já troca o status E dá play no "Caindo"
			go_to_falling()
		else:
			if velocity.x == 0:
				go_to_idle_state()
			else:
				go_to_walk_state()

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

func throw_state():
	# 1. Permite que o jogador use as setas para se mover ou cair
	move() 
	
	# 2. LÓGICA DE SPAWN (Frame 1 como combinamos)
	if sprite.frame == 1 and not ja_arremessou:
		ja_arremessou = true 
		if current_weapon == WeaponType.gun:
			shoot_straight()
		elif current_weapon == WeaponType.elf_gun:
			shoot_elf()

	# 3. LÓGICA DE SAÍDA
	if not sprite.is_playing():
		if is_on_floor():
			if velocity.x == 0:
				go_to_idle_state()
			else:
				go_to_walk_state()
		else:
			# Se terminar no ar, ele cai corretamente
			go_to_falling()

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
	velocity.y = JUMP_VELOCITY
	sprite.play("Pulando")
	print("LOG: Iniciou Pulo (Subindo)")

func go_to_falling():
	# Mantemos o status como jump, pois a lógica física é a mesma
	status = PlayerState.jump 
	sprite.play("Caindo")
	print("LOG: Iniciou Queda (Descendo)")

func go_to_wall_slide():
	status = PlayerState.jump # Mantemos jump ou pode criar PlayerState.wall_slide se preferir
	sprite.play("Escorregar") # Reset visual para não travar no frame de ataque
	print("LOG: Entrou em Wall Slide")

func go_to_attack_state():
	status = PlayerState.attack
	combo_stage = 1
	combo_window_timer = 1.0 # Abre 1 segundo para o próximo clique
	sprite.play("Ataque_1") # Nome da sua primeira animação
	hitbox.monitoring = true
	
func go_to_attack_2_state():
	status = PlayerState.attack
	combo_stage = 2 # Avança o combo
	combo_window_timer = 0.0 # Reseta o timer pois já usou o combo
	sprite.play("Ataque_2") # Nome da sua segunda animação
	hitbox.monitoring = true
	
func go_to_dash_state():
	status = PlayerState.dash
	dash_timer = DASH_TIME
	dash_count += 1
	dash_cooldown_timer = DASH_COOLDOWN # <--- Ativa o cooldown aqui
	
	hitbox.monitoring = false
	
	var direction = -1 if sprite.flip_h else 1
	velocity.x = direction * DASH_SPEED
	velocity.y = 0
	
	sprite.play("Dash")

func go_to_slide_state():
	status = PlayerState.slide
	print("--- SLIDE ATIVADO! Inclinação: ", get_floor_normal().x)
	sprite.play("Slide") # Substitua pela animação do Pietro depois
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
	
	sprite.play("Possuido") # Ou "Possuido" se você tiver a animação

func go_to_throw_state():
	status = PlayerState.throw
	ja_arremessou = false # Reseta para o novo arremesso
	sprite.play("Arremessar")
	
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
	if is_on_wall() and not is_on_floor():
		var wall_normal = get_wall_normal()	
		
		velocity.x = wall_normal.x * WALL_JUMP_PUSHBACK
		velocity.y = WALL_JUMP_VELOCITY
		wall_jump_timer = WALL_JUMP_LOCK_TIME
		
		# --- CORREÇÃO DA HITBOX E DIREÇÃO ---
		# Força o lado baseado na parede (Normal x > 0 significa parede na esquerda, pula pra direita)
		sprite.flip_h = (wall_normal.x < 0)
		hitbox.scale.x = -1 if sprite.flip_h else 1
		
		# Respeitando sua regra: usa o go_to_jump_state para iniciar a animação
		go_to_jump_state()
		
		return true 
	return false

func handle_wall_slide(_delta):
	var wall_normal = get_wall_normal()
	var dir = Input.get_axis("left", "right")

	if dir != 0 and sign(dir) == sign(wall_normal.x):
		if status == PlayerState.jump and sprite.animation == "Escorregar":
			go_to_falling()
		return

	if is_on_wall() and not is_on_floor() and velocity.y > 0:
		sprite.flip_h = (wall_normal.x < 0) 

		if sprite.animation != "Escorregar" and status == PlayerState.jump:
			go_to_wall_slide()
		
		# Mantém o player "colado" na parede para evitar flicker nas quinas
		velocity.x = -wall_normal.x * 10
			

func is_on_steep_slope() -> bool:
	if is_on_floor():
		var n = get_floor_normal()
		return abs(n.x) > 0.15 # Detecta qualquer inclinação
	return false
	
func pode_interagir() -> bool:
	# Só pode se estiver no chão
	if not is_on_floor():
		return false
	
	# Só pode se o estado atual for idle ou walk
	if status == PlayerState.idle or status == PlayerState.walk:
		return true
		
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
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
		
#Movimentação

func move():
	# 1. Travas de controle (se estiver em Wall Jump ou tomando dano)
	if wall_jump_timer > 0 or knockback_timer > 0: return
	
	# --- ALTERAÇÃO AQUI: Prioridade para direção forçada ---
	var dir: float
	if direcao_forcada != 0:
		dir = direcao_forcada
	else:
		dir = Input.get_axis("left", "right")
	# -------------------------------------------------------
	
	# 2. TRAVA DE WALL SLIDE: 
	# Se estiver na parede e segurando na direção DELA, travamos o visual.
	if is_on_wall() and not is_on_floor() and dir != 0:
		var wall_normal = get_wall_normal()
		if sign(dir) != sign(wall_normal.x):
			return 

	# 3. LÓGICA DE MOVIMENTAÇÃO NORMAL
	if dir:
		var speed_multiplier = 1.2 if is_on_steep_slope() else 1.0
		
		# Controle de Momentum no ar
		if not is_on_floor() and abs(velocity.x) > SPEED:
			if sign(dir) == sign(velocity.x):
				velocity.x = move_toward(velocity.x, dir * MAX_SLIDE_SPEED, 2)
			else:
				velocity.x = move_toward(velocity.x, dir * SPEED, 15) 
		else:
			# Movimento padrão
			velocity.x = dir * SPEED * speed_multiplier
			
		# Atualiza a direção do personagem e da hitbox
		sprite.flip_h = (dir < 0)
		hitbox.scale.x = -1 if dir < 0 else 1
	else:
		# Atrito/Freio (Friction)
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
			if combo_stage == 1 and combo_window_timer > 0:
				go_to_attack_2_state()
			else:
				go_to_attack_state()
		# Em vez de atirar direto, mudamos para o estado de arremesso
		WeaponType.gun, WeaponType.elf_gun:
			go_to_throw_state()

func shoot_straight():
	var bullet = preload("res://Entities/bullet.tscn").instantiate()
	
	# Define a direção antes de tudo
	var dir = -1 if sprite.flip_h else 1
	bullet.direction = dir
	
	# --- AJUSTE AQUI ---
	# Vector2(Distância lateral, Altura)
	# X: 20 pixels para a frente do centro
	# Y: -10 pixels (sobe um pouco para sair na altura do braço/peito)
	bullet.global_position = global_position + Vector2(20 * dir, -25)
	
	get_parent().add_child(bullet)
	
func shoot_elf():
	var bullet = preload("res://Entities/elf_bullet.tscn").instantiate()
	get_parent().add_child(bullet)
	
	var dir = -1 if sprite.flip_h else 1
	
	# --- AJUSTE AQUI ---
	# Se quiser que saia "de cima" do Papanel, coloque um valor negativo em Y (ex: -30)
	bullet.global_position = global_position + Vector2(20 * dir, -25)
	
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
	if status == PlayerState.attack:
		# Deixe aqui apenas o que for do ataque de espada
		pass

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
	if is_dead: return # Evita chamar a morte duas vezes
	is_dead = true
	print("LOG: Player caiu no abismo ou morreu")
	
	# Desativa colisão para ele não ficar batendo em nada enquanto morre
	set_physics_process(false) 	
	call_deferred("reload_scene")
	
func reload_scene():
	var fase_atual = get_tree().current_scene.scene_file_path
	SceneTransition.change_scene(fase_atual)
	
func update_animation_offsets():
	# Reset padrão para evitar que um estado suje o outro
	sprite.offset = Vector2.ZERO

	if sprite.animation == "Escorregar":
		# Se ele estiver olhando para a esquerda (parede na esquerda)
		if sprite.flip_h:
			sprite.offset.x = -7  # Ajuste esse número até encostar na parede
		else:
			# Parede na direita
			sprite.offset.x = 10   # Ajuste esse número até encostar na parede
		
		sprite.offset.y = -2 # Ajuste se ele estiver "afundando" no chão ao chegar na base
		return # Sai da função para não aplicar o match status abaixo
		
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
				sprite.offset.y = -2
			
			
func can_dash() -> bool:
	# Só pode dar dash se tiver cargas disponíveis E se o cooldown for 0
	return dash_count < MAX_DASHES and dash_cooldown_timer <= 0

# No update_animation_offsets ou no _physics_process
func aplicar_rotacao_slide(delta):
	if status == PlayerState.slide:
		# Pegamos a normal do chão (o vetor perpendicular à rampa)
		var n = get_floor_normal()
		
		# Calculamos o ângulo da rampa baseado na normal
		# O n.angle() nos dá o ângulo, mas precisamos compensar em 90° (PI/2)
		var angulo_alvo = n.angle() + PI/2
		
		# Suavizamos a rotação para o ângulo da rampa
		sprite.rotation = lerp_angle(sprite.rotation, angulo_alvo, 10 * delta)
	else:
		# Se não estiver em slide, volta a rotação para 0 suavemente
		sprite.rotation = lerp_angle(sprite.rotation, 0, 15 * delta)
