extends Area2D

@export_file("*.tscn") var next_scene: String

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		# 1. Descobre para onde o Papanel está olhando (baseado no flip do sprite)
		# Se flip_h for true, ele olha pra esquerda (-1), senão pra direita (1)
		var direcao = -1 if body.get_node("AnimatedSprite2D").flip_h else 1
		
		# 2. "Sequestra" o controle do player
		body.direcao_forcada = direcao
		
		# 3. Chama a transição (ela já tem o fade que criamos)
		if next_scene != "":
			SceneTransition.change_scene(next_scene)
		else:
			print("Caminho da cena vazio!")
