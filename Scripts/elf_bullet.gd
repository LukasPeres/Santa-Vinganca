extends CharacterBody2D
# Variáveis de controle do projétil
var direction = 1
const THROW_SPEED = 120
const THROW_UP = -400
const GRAVITY = 900 

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	# Deixamos vazio porque o Player vai configurar a bala via launch()
	pass

# Esta função é a que o Player chama logo após dar o spawn
func launch(dir):
	direction = dir
	velocity.x = direction * THROW_SPEED
	velocity.y = THROW_UP
	if sprite:
		sprite.play("Elfo")
		sprite.flip_h = (direction < 0)

func _physics_process(delta):
	# Aplica a gravidade frame a frame para criar o arco
	velocity.y += GRAVITY * delta
	
	# Move a bala usando a física do Godot
	move_and_slide()

	# Sistema de Colisão
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var body = collision.get_collider()

# No loop de colisão da elf_bullet:
		if body.is_in_group("enemy"):
			if body.has_method("take_damage"):
				# Mesmo que seja uma parábola, mandamos a direção horizontal dela
				var dir_impacto = Vector2(direction, 0)
				body.take_damage(1, global_position, dir_impacto)
			queue_free()
		else:
			# Se bater no chão ou parede (qualquer coisa que não seja inimigo)
			queue_free()

# Função que você conectou pelo sinal do nó VisibleOnScreenNotifier2D
func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
