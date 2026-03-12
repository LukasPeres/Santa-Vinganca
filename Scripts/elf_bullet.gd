extends CharacterBody2D

var direction = 1

const THROW_SPEED = 220
const THROW_UP = -250
const GRAVITY = 900

func _ready():

	velocity.x = direction * THROW_SPEED
	velocity.y = THROW_UP


func _physics_process(delta):

	velocity.y += GRAVITY * delta

	move_and_slide()

	for i in get_slide_collision_count():

		var collision = get_slide_collision(i)
		var body = collision.get_collider()

		if body.is_in_group("enemy"):
			body.take_damage(1, global_position)
			queue_free()
