extends CharacterBody2D

var direction = 1
const SPEED = 500

func _physics_process(_delta):
	velocity.x = direction * SPEED
	move_and_slide()

	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var body = collision.get_collider()

		if body.is_in_group("enemy"):
		# Adicionamos o 'true' no final para avisar que é um projétil
			body.take_damage(1, global_position, true)
			queue_free()
