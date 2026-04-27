extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		# Chamamos a função de morte que você já tem no player.gd
		body.die()
