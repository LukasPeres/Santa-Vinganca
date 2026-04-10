extends CharacterBody2D

@onready var sprite = $Sprite2D
var quicando = false

func _ready():
	add_to_group("enemy")

func _physics_process(delta):
	if quicando:
		# Lógica de quique que você já tem
		pass

func take_damage(amount, from_pos, is_projectile):
	if get_parent().has_method("take_damage_boss"):
		get_parent().take_damage_boss(amount)
	else:
		# Vida própria Fase 2
		pass

func flash_damage():
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(10, 10, 10), 0.05)
	tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.05)
