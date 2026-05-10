extends RigidBody2D

const LIFETIME = 3.0
const BLINK_START = 2.0

var timer: float = 0.0
@onready var sprite: Sprite2D = $Sprite2D

func setup(angle: float) -> void:
	# Em vez de mover a posição na mão, damos um impulso físico real
	var força := randf_range(150, 300)
	var direção = Vector2(cos(angle), sin(angle))
	
	# Aplica o impulso inicial (faz o caco voar)
	apply_central_impulse(direção * força)
	
	# Dá uma rotação aleatória inicial para ele girar enquanto cai
	angular_velocity = randf_range(-10, 10)

func _process(delta: float) -> void:
	timer += delta

	if not sprite: return

	# Lógica de Piscar
	if timer >= BLINK_START:
		sprite.visible = int(timer * 10) % 2 == 0

	# Lógica de Sumir
	if timer >= LIFETIME:
		queue_free()

# Para dar dano no player, o player deve estar em uma camada que o RigidBody detecte
# Ou você pode manter uma Area2D pequena dentro do RigidBody para dano.
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(1, global_position)
