extends Node2D

const JET_SCENE     = preload("res://Entities/soda_jet_bottle.tscn")
const LIFETIME      = 5.0
const ROTATION_SPEED = 120.0  # Graus por segundo
const JET_INTERVAL  = 0.4

var timer:     float = 0.0
var jet_timer: float = 0.0

func _physics_process(delta: float) -> void:
	timer     += delta
	jet_timer += delta
	rotation_degrees += ROTATION_SPEED * delta

	if jet_timer >= JET_INTERVAL:
		jet_timer = 0.0
		_fire_jets()

	if timer >= LIFETIME:
		queue_free()

func _fire_jets() -> void:
	# Dispara 2 jatos opostos baseados na rotação atual
	for i in 2:
		var jet = JET_SCENE.instantiate()
		var angle := rotation + (PI * i)  # 0° e 180°
		jet.global_position = global_position
		jet.direction = Vector2(cos(angle), sin(angle))
		get_parent().add_child(jet)
