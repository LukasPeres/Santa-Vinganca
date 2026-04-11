extends CharacterBody2D

var gravidade = 700.0
var tempo_vida = 0.0

func _ready():
	print(">> BOLINHA ", name, ": Nasci em ", global_position, " com velocity ", velocity)

func _physics_process(delta):
	tempo_vida += delta
	velocity.y += gravidade * delta
	
	# move_and_slide() retorna true se houve colisão
	var colidiu = move_and_slide()
	
	# TUDO ABAIXO PRECISA DE UM TAB (RECUO) PARA ESTAR DENTRO DA FUNÇÃO
	if colidiu:
		for i in get_slide_collision_count():
			var colisao = get_slide_collision(i)
			var objeto = colisao.get_collider()
			
			# Ignora colisões entre as próprias bolas
			if objeto.name.contains("snowball_arc") or objeto.name.contains("@CharacterBody2D"):
				continue 
				
			# Se bater em algo que não seja outra bola nos primeiros frames
			if tempo_vida < 0.1:
				print(">> BOLINHA ", name, " MORREU batesse em: ", objeto.name)
				queue_free()
				return
			
			# Se tocar no chão (TileMap ou StaticBody2D) depois de um tempo
			if is_on_floor():
				print(">> BOLINHA ", name, ": Toquei no chão.")
				queue_free()
				return

# Esta função fica fora do _physics_process mesmo, no nível principal
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print(">> BOLINHA ", name, ": DEI DANO!")
		if body.has_method("take_damage"):
			body.take_damage(1, global_position)
		queue_free()
	
	elif body.name.contains("snowboss") and tempo_vida < 0.2:
		print(">> BOLINHA ", name, ": Ignorei o Boss.")
