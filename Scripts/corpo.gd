extends CharacterBody2D

@onready var sprite = $AnimatedSprite2D

# Constantes físicas (Padronizadas com seu Enemy)
const GRAVITY = 900
const KNOCKBACK_FORCE = 150 
const KNOCKBACK_UP = -150   
const SPEED = 60            

# Estado interno
var direction = -1

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
	# O corpo não tem vida própria, ele avisa o Snowboss (Pai)
	var pai = get_parent()
	if pai and pai.has_method("take_damage"):
		pai.take_damage(amount)
	
	# Sofre o impacto visual/físico do golpe
	apply_knockback(from_position)

func apply_knockback(from_position):
	var knockback_direction = sign(global_position.x - from_position.x)
	velocity.x = knockback_direction * KNOCKBACK_FORCE
	velocity.y = KNOCKBACK_UP

# Chamado pelo Pai no início da Fase 2
func mudar_para_fase_2():
	print("Corpo: Fase 2 iniciada!")



func _on_area_dano_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		# Garante que o player receba o dano e a posição para o knockback dele
		if body.has_method("take_damage"):
			body.take_damage(1, global_position)
