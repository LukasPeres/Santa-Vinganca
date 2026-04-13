extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# --- CONFIGURAÇÕES ---
var health: float = 8.0
var speed: float = 200.0
var dano_contato: int = 1

# Variável de direção inicial (pode ser setada pelo Boss ao spawnar)
var velocity_fase2: Vector2 = Vector2.ZERO

func _ready():
	add_to_group("enemy")
	
	if sprite.sprite_frames.has_animation("girando"):
		sprite.play("girando")
	# Dá um impulso inicial aleatório para cima e para o lado para começar o quique
	var dir_x = [-1, 1].pick_random()
	velocity_fase2 = Vector2(dir_x * speed, -speed)

func _physics_process(delta):
	# 1. Tenta mover
	var colidindo = move_and_collide(velocity_fase2 * delta)
	
	# PRINT DE TESTE 1: Saber se a cabeça está se movendo
	# print("Velocidade atual: ", velocity_fase2)

	if colidindo:
		# 2. PRINT DE TESTE 2: Em quem bati?
		var objeto = colidindo.get_collider()
		print("COLIDIU COM: ", objeto.name, " | No grupo player? ", objeto.is_in_group("player"))
		
		# 3. PRINT DE TESTE 3: Qual a normal do impacto?
		var normal = colidindo.get_normal()
		print("Normal da batida: ", normal)
		
		# 4. Aplica o bounce
		var nova_velocidade = velocity_fase2.bounce(normal)
		velocity_fase2 = nova_velocidade
		
		# 5. PRINT DE TESTE 4: Mudou?
		print("Nova velocidade após quique: ", velocity_fase2)
		
		# Dano
		if objeto.is_in_group("player"):
			if objeto.has_method("take_damage"):
				objeto.take_damage(1, global_position)

# --- SISTEMA DE DANO ---

# Agora a sua função de dano aceita a direção do golpe
func take_damage(amount, _from_pos = Vector2.ZERO, direcao_golpe = Vector2.ZERO):
	health -= amount	
	# SE houver uma direção de golpe (veio de um ataque do player)
	if direcao_golpe != Vector2.ZERO:
		print("Rebatendo cabeça!")
		# Forçamos a velocidade para a direção do bastão
		velocity_fase2 = direcao_golpe * speed
		velocity_fase2.y -= 150 # O pulinho pra não pregar no chão
		flash_damage()

	
	if health <= 0:
		morrer()
		
# Esta função será chamada quando o bastão do player atingir a cabeça
func levar_rebatida(direcao_do_golpe: Vector2):
	# 1. Toma dano (já que você quer que o boss perca vida ao ser rebatido)
	take_damage(1)
	
	# 2. Inverte a direção
	# Se o player bateu pra direita, a cabeça voa pra direita
	# Usamos a direção do golpe e multiplicamos pela velocidade
	velocity_fase2 = direcao_do_golpe * speed
	
	# 3. Pequeno bônus: dar um "totó" pra cima pra não arrastar no chão
	velocity_fase2.y -= 100 
	
	# Feedback visual de que a rebatida funcionou
	print("CABEÇA: Fui rebatida!")


func morrer():
	# Efeito de partículas ou som antes de sumir
	queue_free()

# --- ATAQUE (COLISÃO COM PLAYER) ---

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(dano_contato, global_position)

func flash_damage():
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(10, 10, 10), 0.05)
	tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.05)
