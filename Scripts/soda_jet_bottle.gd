extends Area2D

var direction: Vector2 = Vector2.ZERO 
@export var speed: float = 200.0  # Velocidade do projétil voando
const LIFETIME = 2.0

func _ready() -> void:
	rotation = direction.angle()
	# Timer para sumir
	get_tree().create_timer(LIFETIME).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	# Agora ele realmente se move para frente!
	position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(1, global_position)
		queue_free() # Some ao tocar no player
