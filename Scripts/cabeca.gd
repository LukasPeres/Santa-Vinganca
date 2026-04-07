extends CharacterBody2D

@onready var sprite = $AnimatedSprite2D


# Configurações de Movimento
var quicando: bool = false
var velocidade: float = 300.0
var direcao: Vector2 = Vector2(1, -1).normalized()

# Estado de Vida
var health = 2
var fase_atual = 1 

func _ready():
	add_to_group("enemy")

func iniciar_quique():
	quicando = true
	fase_atual = 2 

func _physics_process(delta):
	if quicando:
		# move_and_collide é ideal para o comportamento de rebater (bounce)
		var colisao = move_and_collide(direcao * velocidade * delta)
		if colisao:
			# Rebate a direção com base na normal da superfície atingida
			direcao = direcao.bounce(colisao.get_normal())

func take_damage(amount, _from_position, _is_projectile = false):
	flash_damage()
	# Print para debug no console
	print("Cabeça atingida. Fase atual: ", fase_atual)
	
	if fase_atual == 1:
		# Na Fase 1, a vida é controlada pelo Snowboss (Pai)
		if get_parent().has_method("take_damage"):
			get_parent().take_damage(amount)
	else:
		# Na Fase 2 (Separada), a vida é individual
		health -= amount
		print(name, " (Cabeça) tomou dano! Vida restante: ", health)
		
		if health <= 0:
			die()

func _on_area_dano_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(1, global_position)
			print("Player encostou na cabeça!")

func flash_damage():
	if sprite:
		sprite.modulate = Color(10, 10, 10) # Fica muito brilhante (branco)
		await get_tree().create_timer(0.1).timeout
		sprite.modulate = Color(1, 1, 1) # Volta ao normal

func die():
	print("CABEÇA DESTRUÍDA!")
	queue_free()
