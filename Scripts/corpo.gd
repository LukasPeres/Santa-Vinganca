extends CharacterBody2D

@onready var sprite = $AnimatedSprite2D

# Constantes físicas (Padronizadas com seu Enemy)
const GRAVITY = 900
const KNOCKBACK_FORCE = 150 
const KNOCKBACK_UP = -150   
const SPEED = 60            

# Estado interno
var direction = -1
var health = 2
var fase_atual = 1 # Começa em 1 (vinculado ao pai)

func _ready():
	add_to_group("enemy")

func _physics_process(delta):
	apply_gravity(delta)
	handle_movement()
	handle_ai()
	move_and_slide()

func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += GRAVITY * delta

func handle_movement():
	if is_on_floor():
		velocity.x = direction * SPEED

func handle_ai():
	if is_on_floor():
		# Checagem de Parede: Inverte a direção ao bater
		if is_on_wall():
			var collision = get_last_slide_collision()
			if collision:
				var normal = collision.get_normal()
				# Verifica se a parede está à frente da direção atual
				if (direction > 0 and normal.x < 0) or (direction < 0 and normal.x > 0):
					flip_direction()

# =========================================================
# Inverte a direção e o visual
# =========================================================
func flip_direction():
	direction *= -1
	velocity.x = direction * SPEED 
	if sprite:
		sprite.flip_h = (direction == 1) # Inverte conforme a lógica do seu sprite

# =========================================================
# Recebe dano e REPASSA para o Pai (Snowboss)
# =========================================================
func take_damage(amount, from_position, _is_projectile = false):
	flash_damage()
	if fase_atual == 1:
		# Na Fase 1, repassa o dano para a vida global do pai
		if get_parent().has_method("take_damage"):
			get_parent().take_damage(amount)
	else:
		# Na Fase 2, sofre dano individual
		health -= amount
		# O PRINT QUE VOCÊ PEDIU:
		print(name, " tomou dano! Vida restante: ", health)
		
		if health <= 0:
			die()

	apply_knockback(from_position)

func apply_knockback(from_position):
	var knockback_direction = sign(global_position.x - from_position.x)
	velocity.x = knockback_direction * KNOCKBACK_FORCE
	velocity.y = KNOCKBACK_UP

func die():
	print(name, " FOI DESTRUÍDO!")
	queue_free()
	
func flash_damage():
	if sprite:
		sprite.modulate = Color(10, 10, 10) # Fica muito brilhante (branco)
		await get_tree().create_timer(0.1).timeout
		sprite.modulate = Color(1, 1, 1) # Volta ao normal

# Chamado pelo Pai no início da Fase 2
func mudar_para_fase_2():
	print("Corpo: Fase 2 iniciada!")



func _on_area_dano_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		# Garante que o player receba o dano e a posição para o knockback dele
		if body.has_method("take_damage"):
			body.take_damage(1, global_position)
