extends CharacterBody2D

var direction = 1
const SPEED = 500

func _physics_process(_delta):
	velocity.x = direction * SPEED
	move_and_slide()

	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var body = collision.get_collider()

		# No loop de colisão da bullet:
		if body.is_in_group("enemy"):
			# Criamos um vetor de direção baseado na direção da bala
			var dir_impacto = Vector2(direction, 0) 
			
			# Enviamos: (Dano, Posição, Direção)
			body.take_damage(1, global_position, dir_impacto)
			queue_free()
