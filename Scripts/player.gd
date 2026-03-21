extends CharacterBody2D #Herda Mobilidade e colisão (velocity, 
#move_and_slide() e in_on_floor() (retorna true or false)

#Estados do player (State Machine) - Bom para organização do código
enum PlayerState{
	idle,
	walk,
	jump,
	attack,
	dash
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

#Constantes da Velocidade
const SPEED = 150.0
const JUMP_VELOCITY = -300.0
const DASH_SPEED = 400
const DASH_TIME = 0.15
const GROUND_FRICTION = 900
const AIR_FRICTION = 120
const ATTACK_COOLDOWN_MS = 400

var status: PlayerState #Chamando a variável de troca de estados
var health = 5 #Vida
var is_dead = false
var dash_timer = 0
var input_direction = 0
var current_weapon = WeaponType.melee
var last_attack_timer = 0.0

#Função que se inicia quando o jogo começa
func _ready() -> void:
	add_to_group("player")
	hitbox.monitoring = false #Hitbox de dano desligada
	go_to_idle_state() #Começa Idle

#Gravidade - Caso o player não esteja no chão, adiciona velocidade vertical
func _physics_process(delta):

	apply_gravity(delta)      # física
	update_state(delta)       # lógica da state machine
	check_weapon_swap()
	update_animation_offsets()# visual

	move_and_slide()          # movimento final

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
	if wants_jump() and is_on_floor():
		go_to_jump_state()
		return
		
	#Quando a velocidade é diferente de 0, mudamos para o estado de andar
	if velocity.x != 0:
		go_to_walk_state()
		return
		
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
	if wants_jump() and is_on_floor():
		go_to_jump_state()
		return

	#Quando a velocidade é = 0, mudamos para o estado parado
	if velocity.x == 0:
		go_to_idle_state()
		return
		
func jump_state():
	move()
	
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

func go_to_idle_state():
	status = PlayerState.idle #Vai para o estado parado
	hitbox.monitoring = false #Garante que nesse modo, a hitbox vai estar off
	sprite.play("Idle") #Toca a animação parado
	
func go_to_walk_state():
	status = PlayerState.walk
	hitbox.monitoring = false
	sprite.play("Idle")
	
func go_to_jump_state():
	if not is_on_floor():
		return
	status = PlayerState.jump
	hitbox.monitoring = false
	velocity.y = JUMP_VELOCITY
	sprite.play("Idle")
	
func go_to_attack_state():
	status = PlayerState.attack
	sprite.play("Ataque")
	hitbox.monitoring = false #Está desligada porque ela é ativa em frames
	#especificos
	
func go_to_dash_state():
	status = PlayerState.dash
	dash_timer = DASH_TIME
	
	hitbox.monitoring = false
	
	var direction = -1 if sprite.flip_h else 1
	velocity.x = direction * DASH_SPEED
	velocity.y = 0
	
	sprite.play("Idle") # depois você pode colocar animação de dash

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
	return Input.is_action_just_pressed("dash") 



#Movimentação
func move():
	input_direction = Input.get_axis("left", "right")
	var direction = input_direction
	#Caso esteja apertando alguma direção, velocidade horizontal é aplicada
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, 60)
	
	#Garante que os sprites e a hitbox virem pra left e right, respectivamente
	if direction < 0:
		sprite.flip_h = true
		hitbox.scale.x = -1
	elif direction > 0:
		sprite.flip_h = false
		hitbox.scale.x = 1


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
			go_to_attack_state()
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
		body.take_damage(1, global_position) #Alem do dano da knockback

#Ativa a hitbox do ataque, apenas no estado de ataque
func _on_animated_sprite_2d_frame_changed() -> void:	
	if status != PlayerState.attack:
		return
	
	#Garante que no frame 1 do estado ataque, a hitbox de ataque seja ativada
	if sprite.frame == 1:
		hitbox.monitoring = true
	else:
		hitbox.monitoring = false

#Sistema de vida e Knockback recebido pelo player
func take_damage(amount, from_position):
	if is_dead:
		return
	
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

	# reset padrão
	sprite.offset = Vector2.ZERO

	# correção da animação de ataque
	match status:
		PlayerState.attack:
			sprite.offset.y = -3

		PlayerState.idle, PlayerState.walk:
			sprite.offset.y = -1
