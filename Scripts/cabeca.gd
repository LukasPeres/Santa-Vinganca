extends CharacterBody2D

var quicando: bool = false
var velocidade: float = 300.0
var direcao: Vector2 = Vector2(1, -1).normalized() # Vai para diagonal

func iniciar_quique():
	quicando = true

func _physics_process(delta):
	if quicando:
		# O move_and_collide retorna a colisão para podermos rebater
		var colisao = move_and_collide(direcao * velocidade * delta)
		if colisao:
			# Calcula o ângulo de rebote (bounce)
			direcao = direcao.bounce(colisao.get_normal())

func _on_area_dano_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		# No seu player a função se chama 'take_damage'
		if body.has_method("take_damage"):
			# Passamos o dano (1) e a posição do boss para o knockback
			body.take_damage(1, global_position)
			print("Dano enviado ao Player!")
