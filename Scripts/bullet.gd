extends CharacterBody2D

var direction = 1
const SPEED = 230
# Velocidade da rotação (em radianos por segundo). 
# Aumente para girar mais rápido.
const ROTATION_SPEED = 5.0 

@onready var sprite: Sprite2D = $Sprite2D # Mudei para Sprite2D se for um frame só

func _ready():
	# Centraliza a rotação no meio do sprite (importante se não for perfeitamente redondo)
	if sprite:
		sprite.centered = true
		# Se a imagem tiver um "lado da frente", viramos de acordo com a direção
		# Mas se for só um carvão redondo, talvez nem precise
		sprite.flip_h = (direction < 0)

func _physics_process(delta):
	# Movimento linear
	velocity.x = direction * SPEED
	move_and_slide()

	# --- ADICIONADO: Lógica de Rotação Visível ---
	if sprite:
		# Giramos o sprite continuamente. Multiplicamos pela direção para girar pro lado certo
		# delta garante que gire na mesma velocidade independente do FPS do jogo
		sprite.rotation += ROTATION_SPEED * direction * delta

	# Sistema de colisão
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var body = collision.get_collider()

# Altere a linha onde o dano é causado:
		if body.is_in_group("enemy"):
			if body.has_method("take_damage"):
				var dir_impacto = Vector2(direction, 0)
				# Adicionamos o 'true' no final para dizer que É um projétil
				body.take_damage(1, global_position, dir_impacto, true)
			queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
