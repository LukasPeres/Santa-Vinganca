extends Area2D

# Dura 3 segundos, pisca no último segundo
const LIFETIME     = 3.0
const BLINK_START  = 2.0  # Começa a piscar aos 2s

var timer: float = 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func setup(angle: float) -> void:
	var dist := randf_range(20, 60)
	position += Vector2(cos(angle) * dist, sin(angle) * dist)

func _physics_process(delta: float) -> void:
	timer += delta

	# Efeito de piscar no último segundo
	if timer >= BLINK_START:
		sprite.visible = int(timer * 8) % 2 == 0  # 8 piscadas por segundo

	if timer >= LIFETIME:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(1, global_position)
