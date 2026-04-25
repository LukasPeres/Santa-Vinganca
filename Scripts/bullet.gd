extends CharacterBody2D

var direction = 1
const SPEED = 230
const ROTATION_SPEED = 5.0 

@onready var sprite: Sprite2D = $Sprite2D

func _ready():
	if sprite:
		sprite.centered = true
		sprite.flip_h = (direction < 0)

func _physics_process(delta):
	velocity.x = direction * SPEED
	
	# Usamos move_and_slide(), mas vamos checar IMEDIATAMENTE se houve colisão
	move_and_slide()

	if sprite:
		sprite.rotation += ROTATION_SPEED * direction * delta

	# --- CORREÇÃO DO IMPACTO ---
	# get_slide_collision_count() diz se batemos em ALGO (parede, chão ou inimigo)
	if get_slide_collision_count() > 0:
		var collision = get_slide_collision(0)
		var body = collision.get_collider()

		# Se bater em inimigo, dá dano
# No bullet.gd, dentro do _physics_process
		if body.is_in_group("enemy"):
			if body.has_method("take_damage"):
				var dir_impacto = Vector2(direction, 0)
				# Agora você envia os 4 dados e ninguém reclama
				body.take_damage(1, global_position, dir_impacto, true)
		
		# Independente de ser parede, chão ou inimigo, o carvão DEVE sumir
		# Tiramos o queue_free() de dentro do if inimigo e deixamos ele aqui fora
		queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
