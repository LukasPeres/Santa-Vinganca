extends CharacterBody2D

@onready var sprite = $Sprite2D
var quicando = false

func _ready():
	add_to_group("enemy")

func _physics_process(_delta):
	if quicando:
		# Lógica de quique que você já tem
		pass

func take_damage(amount, _from_pos, _is_projectile):
	if get_parent().has_method("take_damage_boss"):
		get_parent().take_damage_boss(amount)
	else:
		# Vida própria Fase 2
		pass
		
func _on_area_dano_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			# Aplica 1 de dano ao player
			body.take_damage(1, global_position)

func flash_damage():
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(10, 10, 10), 0.05)
	tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.05)
