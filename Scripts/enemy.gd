extends CharacterBody2D

# Constantes físicas do inimigo
const GRAVITY = 900
const KNOCKBACK_FORCE = 120 # força horizontal do knockback
const KNOCKBACK_UP = -120   # força vertical do knockback
const SPEED = 60            # velocidade de patrulha

# Estado interno
var direction = -1          # -1 = esquerda | 1 = direita
var health = 3              # vida do inimigo


# =========================================================
# Função chamada quando o inimigo entra na cena
# Responsabilidade: configuração inicial
# =========================================================
func _ready():
	add_to_group("enemy")


# =========================================================
# Loop principal da física
# Responsabilidade: orquestrar o comportamento
# =========================================================
func _physics_process(delta):
	apply_gravity(delta)
	handle_movement()
	handle_ai()
	move_and_slide()


# =========================================================
# Aplica gravidade enquanto não estiver no chão
# Responsabilidade: gravidade
# =========================================================
func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += GRAVITY * delta


# =========================================================
# Controla movimento horizontal básico
# Responsabilidade: movimentação
# =========================================================
func handle_movement():
	if is_on_floor():
		velocity.x = direction * SPEED


# =========================================================
# Lógica da IA de patrulha
# Verifica bordas e paredes para inverter direção
# Responsabilidade: decisões de IA
# =========================================================
func handle_ai():
	if is_on_floor():
		# 1. Checagem de Parede:
		# Só invertemos se a velocidade estiver "empurrando" contra a parede
		if is_on_wall():
			# Se estou tentando ir para a direita (1) e bati na parede, OU vice-versa
			# Isso evita que ele inverta se já estiver se afastando
			var collision = get_last_slide_collision()
			if collision:
				var normal = collision.get_normal()
				# Se a parede está na frente da minha direção atual
				if (direction > 0 and normal.x < 0) or (direction < 0 and normal.x > 0):
					flip_direction()
					return # Sai da função para não checar o abismo no mesmo frame

		# 2. Checagem de Abismo (RayCast):
		if not $RayCast2D.is_colliding():
			flip_direction()

	update_sensors()

# =========================================================
# Inverte a direção do inimigo
# Responsabilidade: alterar direção
# =========================================================
func flip_direction():
	direction *= -1
	# IMPORTANTE: Atualiza a velocidade imediatamente para ele se afastar da parede
	velocity.x = direction * SPEED 
	# Inverte o sprite(ainda nao temos)
	#$Sprite2D.flip_h = (direction == 1)

# =========================================================
# Mantém RayCast e Hitbox alinhados com a direção atual
# Responsabilidade única: sincronizar sensores
# =========================================================
func update_sensors():
	$RayCast2D.position.x = abs($RayCast2D.position.x) * direction
	$DamageArea/CollisionShape2D.position.x = abs($DamageArea/CollisionShape2D.position.x) * direction


# =========================================================
# Recebe dano
# Responsabilidade: reduzir vida e reagir ao impacto
# =========================================================
func take_damage(amount, from_position):
	health -= amount
	print("Enemy vida:", health)

	if health <= 0:
		die()
		return

	apply_knockback(from_position)


# =========================================================
# Aplica força de knockback baseada na posição do atacante
# Responsabilidade única: reação física ao dano
# =========================================================
func apply_knockback(from_position):
	var knockback_direction = sign(global_position.x - from_position.x)
	velocity.x = knockback_direction * KNOCKBACK_FORCE
	velocity.y = KNOCKBACK_UP


# =========================================================
# Remove o inimigo da cena
# No futuro pode conter animações, som, efeitos etc.
# Responsabilidade: morte
# =========================================================
func die():
	print("Enemy morreu")
	queue_free()


# =========================================================
# Detecta colisão da hitbox com o player
# Responsabilidade: causar dano no player
# =========================================================
func _on_damage_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.take_damage(1, global_position)
