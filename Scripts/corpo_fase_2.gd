extends CharacterBody2D

# --- ESTADOS ---
enum State { IDLE, WALK, ATTACK }

# --- CONFIGURAÇÕES ---
@export var speed: float = 80.0
@export var health: float = 8.0
@export var attack_cooldown: float = 2.0

# --- SISTEMA DE CHANCE ACUMULADA ---
var timer_sorteio: float = 0.0
var chance_ataque: float = 0.0
const INCREMENTO_CHANCE = 15.0 # Aumenta 15% de chance a cada segundo

# --- VARIÁVEIS DE CONTROLE ---
var current_state: State = State.IDLE
var direction: int = 1 # 1 para direita, -1 para esquerda
var attack_timer: float = 0.0

@onready var marker_impacto = $Marker2D # Verifique se ele está no nó raiz do boss
@onready var shape_1 = $HitboxMartelada/CollisionShape2D
@onready var shape_2 = $HitboxMartelada/CollisionShape2D2
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

const SNOWBALL_SCN = preload("res://Entities/snowball_arc.tscn")

func _ready():
	add_to_group("enemy")
	go_to_walk() # Começa andando

func _physics_process(delta):
	# 1. Aplica chance de ataque apenas se estiver andando
	if current_state == State.WALK:
		processar_chance_martelada(delta)
	
	# 2. Gravidade
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# 3. Executa o estado atual (O walk_state já está aqui dentro!)
	match current_state:
		State.IDLE:
			idle_state(delta)
		State.WALK:
			walk_state()
		State.ATTACK:
			attack_state()

	move_and_slide()
	update_boss_animation_offsets()

# --- LÓGICA DOS ESTADOS ---

func idle_state(delta):
	velocity.x = move_toward(velocity.x, 0, speed * delta)
	# Exemplo: esperar 1 segundo antes de voltar a andar
	attack_timer -= delta
	if attack_timer <= 0:
		go_to_walk()

func walk_state():
	velocity.x = direction * speed
	
	# Só vira se estiver realmente batendo na parede NA DIREÇÃO do movimento
	if is_on_wall():
		# Pegamos a normal da parede para ter certeza de que lado batemos
		var normal = get_wall_normal()
		
		# Se a parede está na nossa direita (normal.x < 0) e queríamos ir para a direita
		# OU se a parede está na esquerda (normal.x > 0) e queríamos ir para a esquerda
		if (normal.x < 0 and direction > 0) or (normal.x > 0 and direction < 0):
			direction *= -1
			sprite.flip_h = (direction < 0)
			# Afasta um tiquinho da parede para não bugar no próximo frame
			atualizar_orientacao()
			global_position.x += direction * 2

func attack_state():
	velocity.x = 0 # Fica parado durante a martelada
	
	# Quando a animação acabar, volta a andar
	if not sprite.is_playing():
		go_to_walk()

# --- FUNÇÕES "GO TO" (Troca de Estados e Animações) ---

func go_to_idle():
	current_state = State.IDLE
	attack_timer = 1.0 # Tempo de espera
	sprite.play("idle")

func go_to_walk():
	current_state = State.WALK
	sprite.play("andando")
	sprite.flip_h = (direction < 0)
	desativar_hitbox_martelo()

func go_to_attack():
	current_state = State.ATTACK
	sprite.play("martelada")

# --- SISTEMA DE DANO (IGUAL À CABEÇA) ---

func processar_chance_martelada(delta):
	timer_sorteio += delta
	
	# A cada 1 segundo, tentamos a sorte
	if timer_sorteio >= 1.0:
		timer_sorteio = 0.0
		chance_ataque += INCREMENTO_CHANCE
		
		print("BOSS: Chance de Martelada em ", chance_ataque, "%")
		
		# randf() gera um número entre 0.0 e 1.0. Multiplicamos por 100 para comparar.
		if randf() * 100.0 < chance_ataque:
			executar_ataque_martelo()

func executar_ataque_martelo():
	# Reseta a chance para o próximo ciclo
	chance_ataque = 0.0
	
	# Vai para o estado de ataque que já criamos
	if has_method("go_to_attack"):
		go_to_attack()

func disparar_chuva_bolas():
	print("TENTANDO ATIRAR BOLAS!") # Se isso não aparecer, o frame_changed não chamou a função
	if not SNOWBALL_SCN: 
		print("ERRO: Cena da bola não carregada!")
		return
		
	var numero_de_bolas = 16 
	var spot_safe_inicio = randi_range(2, 7) 
	
	for i in range(numero_de_bolas):
		# Pula os frames do "ponto seguro" para o player escapar
		if i == spot_safe_inicio or i == spot_safe_inicio + 1:
			continue
			
		var bola = SNOWBALL_SCN.instantiate()
		get_parent().add_child(bola)
		
		# Posiciona no Marker2D
		bola.global_position = marker_impacto.global_position
		
		# Cálculo do leque de bolas
		var fracao = float(i) / float(numero_de_bolas - 1)
		var direcao_horizontal = lerp(-1.0, 1.0, fracao)
		
		var forca_x = direcao_horizontal * 400.0 
		var forca_y = -450.0 - (randf() * 150.0) 
		
		if "velocity" in bola:
			bola.velocity = Vector2(forca_x, forca_y)

func take_damage(amount, _from_pos = Vector2.ZERO, _dir = Vector2.ZERO):
	health -= amount
	flash_damage() # Função de brilho que você já usa
	
	if health <= 0:
		morrer()

func flash_damage():
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(10, 10, 10), 0.05)
	tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.05)

func morrer():
	queue_free()


func _on_area_2d_body_entered(body: Node2D) -> void:
# 1. Verifica se quem entrou na área é o Player
	if body.is_in_group("player"):
		print("Boss encostou no Player! Dando dano de contato.")
		
		# 2. Verifica se o player tem a função de tomar dano
		if body.has_method("take_damage"):
			# Passa 1 de dano e a posição do boss para o cálculo de knockback
			body.take_damage(1, global_position)

func update_boss_animation_offsets():
	# Começamos com zero para resetar a cada frame
	var novo_offset = Vector2.ZERO

	# AJUSTE DE ALTURA (Y)
	if current_state == State.ATTACK:
		novo_offset.y = -11 # Sobe o sprite na martelada
	
	# AJUSTE LATERAL (X) - "Centralização" dinâmica
	# Se direction for 1 (Direita), o offset.x fica positivo (vai para a direita)
	# Se direction for -1 (Esquerda), o offset.x fica negativo (vai para a esquerda)
	# Ajuste o número 10 para a distância que você achar necessária
	novo_offset.x = 12 * direction 

	# Aplica o resultado ao sprite
	sprite.offset = novo_offset

func _on_animated_sprite_2d_frame_changed() -> void:
	if current_state != State.ATTACK:
		return
	
	# FRAME 3 e 4: Ativa o dano
	if sprite.frame == 3 or sprite.frame == 4:
		shape_1.set_deferred("disabled", false)
		shape_2.set_deferred("disabled", false)
		print("DANO ATIVADO (Frames 3-4)")
		
	if sprite.frame == 3:
		disparar_chuva_bolas()
	# OUTROS FRAMES (0, 1, 2 e após o 4): Desativa o dano
	else:
		shape_1.set_deferred("disabled", true)
		shape_2.set_deferred("disabled", true)


func _on_hitbox_martelada_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("Player atingido pelo martelo!")
		if body.has_method("take_damage"):
			# Passa o dano e a posição do boss para o knockback
			body.take_damage(2, global_position)

func desativar_hitbox_martelo():
	if shape_1 and shape_2:
		shape_1.set_deferred("disabled", true)
		shape_2.set_deferred("disabled", true)

func atualizar_orientacao():
	# 1. Vira o desenho do Sprite
	sprite.flip_h = (direction < 0)
	
	# 2. Vira as Hitboxes
	if has_node("HitboxMartelada"):
		$HitboxMartelada.scale.x = direction
		
	# 3. VIRA O MARKER (O ponto de onde saem as bolas)
	if has_node("Marker2D"):
		$Marker2D.position.x = abs($Marker2D.position.x) * direction
