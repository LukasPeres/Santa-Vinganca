extends CharacterBody2D

# 1. ATUALIZADO: Agora aponta para o AnimatedSprite2D
@onready var sprite = $AnimatedSprite2D 
@onready var col_ar = $HitboxSoco/CollisionShape2D
@onready var col_chao = $HitboxSoco/CollisionShape2D2

func _ready():
	add_to_group("enemy")

func _physics_process(_delta):
	if get_parent().name != "snowboss": 
		move_and_slide()

# --- COMBATE ---

# Função que o Boss chama ao entrar no estado de Martelo
func set_martelada_ativa(valor: bool):
	$HitboxSoco.visible = valor
	if not valor:
		desativar_todas_colisoes_soco()
		sprite.offset.y = 0

# Essa função roda TODA VEZ que o frame da animação muda
func _on_animated_sprite_2d_frame_changed():
	#para resolver problemas com nil
	if not sprite: 
		return
	if sprite.animation == "martelada":
		# AJUSTE DE ALTURA (Mude o -15 para o valor que encaixar no seu chão)
		sprite.offset.y = -13
		

		
		# CONTROLE DE HITBOX (Ativando por frames)
		match sprite.frame:
			0, 1, 2: # Preparação
				desativar_todas_colisoes_soco()
			3: # FRAME DO SLASH (Corte no ar)
				col_ar.disabled = false
				col_chao.disabled = false
				# 1. TREMOR DE TELA
				aplicar_tremor(10.0, 0.25)
				
				# 2. CHUVA DE BOLAS (Agora acontece junto com o impacto!)
				if get_parent().has_method("disparar_chuva_bolas"):
					get_parent().disparar_chuva_bolas()
				
				print("DEBUG CORPO: IMPACTO TOTAL (Shake + Neve)!")
				#aplicar_tremor(10.0, 0.25)
			4: # FRAME DO IMPACTO (Martelo no chão)
				col_ar.disabled = false    
				col_chao.disabled = false
			
			5: # Fim / Recuperação

				desativar_todas_colisoes_soco()
	
	# Dentro do _on_animated_sprite_2d_frame_changed() no corpo.gd
	elif sprite.animation == "soltando_raio":
		match sprite.frame:
			1, 2, 3:
				if get_parent().has_method("mostrar_aviso_raio"):
					get_parent().mostrar_aviso_raio()
			4:
				if get_parent().has_method("disparar_raio"):
					get_parent().disparar_raio()
	
	elif sprite.animation == "andando":
		# O andando precisa subir SÓ UM POUCO (ex: -4)
		# Ajuste esse número até os pés tocarem a linha do chão
		sprite.offset.y = -1
		
	else:
		# Idle ou outras animações (ajuste conforme necessário)
		sprite.offset.y = 0

# Função auxiliar para limpar as colisões
func desativar_todas_colisoes_soco():
	if col_ar: col_ar.disabled = true
	if col_chao: col_chao.disabled = true
	
# --- SISTEMA ---
func atualizar_direcao(dir):
	# Note: Removi o sprite.flip_h daqui. 
	# Vamos fazer o Boss principal girar o sprite, 
	# e o corpo gira o resto abaixo:
	
	if has_node("RemoteTransform2D"):
		$RemoteTransform2D.position.x = abs($RemoteTransform2D.position.x) * dir
		
	if has_node("HitboxSoco"):
		$HitboxSoco.position.x = abs($HitboxSoco.position.x) * dir
		
	if has_node("PontoImpacto"):
		$PontoImpacto.position.x = abs($PontoImpacto.position.x) * dir
	
	if has_node("PontoRaio"):
		if dir > 0: # Olhando para a DIREITA
			$PontoRaio.position.x = 35 # O valor que você anotou
		else: # Olhando para a ESQUERDA
			$PontoRaio.position.x = -25 # O mesmo valor, mas negativo
		
func flash_damage():
	# 2. ATUALIZADO: O Tween agora usa o AnimatedSprite2D
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(10, 10, 10), 0.05)
		tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.05)

# Adicionei o _dir no meio para completar os 4 espaços
func take_damage(amount, _from_pos = Vector2.ZERO, _dir = Vector2.ZERO, _is_projectile = false):
	flash_damage()
	
	# Se você vai repassar o dano para o pai, 
	# o ideal é repassar todos os dados para evitar erros em cascata
	if get_parent().has_method("take_damage"):
		get_parent().take_damage(amount, _from_pos, _dir, _is_projectile)

func _on_hitbox_soco_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			# Dano do martelo/soco é maior que o de contato
			body.take_damage(2, global_position)
			print("BOSS: Player atingido pelo MARTELO!")

func _on_area_dano_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			# Dano de contato normal é 1
			body.take_damage(1, global_position)
			print("BOSS: Player encostou no corpo!")


func _on_animated_sprite_2d_animation_finished():
	if sprite.animation == "martelada":
		# Apenas encerra o estado para o Boss voltar a andar
		set_martelada_ativa(false)
		if get_parent().has_method("go_to_seguindo_state"):
			get_parent().go_to_seguindo_state()
			
func aplicar_tremor(intensidade: float, duracao: float):
	var cam = get_viewport().get_camera_2d()
	if cam:
		var original_offset = cam.offset
		var tween = create_tween()
		
		# Faz a câmera vibrar rapidamente
		for i in range(5):
			var move_para = Vector2(randf_range(-intensidade, intensidade), randf_range(-intensidade, intensidade))
			tween.tween_property(cam, "offset", move_para, duracao / 5)
		
		# Garante que a câmera volte ao normal (0,0)
		tween.tween_property(cam, "offset", original_offset, 0.05)
