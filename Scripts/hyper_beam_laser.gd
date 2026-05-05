extends Area2D

# O laser é um Area2D comprido que se expande da boca do boss
# Visualmente: um RayCast2D define o comprimento e a cena usa um Sprite esticado
var direction: int = 1

const DAMAGE_INTERVAL = 0.2
const MAX_LENGTH      = 600.0

var damage_timer: float = 0.0

@onready var ray:    RayCast2D     = $RayCast2D
@onready var sprite: Sprite2D      = $Sprite2D  # Sprite do feixe (esticado no eixo X)
@onready var col:    CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	ray.target_position = Vector2(direction * MAX_LENGTH, 0)

func _physics_process(delta: float) -> void:
	damage_timer = max(0.0, damage_timer - delta)
	_update_beam_length()

func _update_beam_length() -> void:
	var length := MAX_LENGTH
	if ray.is_colliding():
		length = ray.get_collision_point().distance_to(global_position)

	# Atualiza o visual e a colisão proporcionalmente ao comprimento real
	sprite.scale.x = length / 100.0  # Ajuste conforme o tamanho base do Sprite
	sprite.position.x = (length / 2.0) * direction

	var shape := col.shape as RectangleShape2D
	if shape:
		shape.size.x = length
	col.position.x = (length / 2.0) * direction

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage") and damage_timer <= 0:
		damage_timer = DAMAGE_INTERVAL
		body.take_damage(2, global_position)  # Laser causa 2 de dano
