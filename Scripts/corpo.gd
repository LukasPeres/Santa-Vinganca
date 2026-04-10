extends CharacterBody2D

@onready var sprite = $Sprite2D

func _ready():
	add_to_group("enemy")

func _physics_process(_delta):
	# Na Fase 1, ele não executa física própria, apenas segue o pai.
	# Na Fase 2, move_and_slide será chamado aqui.
	if get_parent().name != "snowboss": # Se não for mais filho do snowboss
		move_and_slide()

func atualizar_direcao(dir):
	if sprite:
		sprite.flip_h = (dir == -1)
	
	# 1. Inverte o RemoteTransform (Pescoço/Cabeça)
	if has_node("RemoteTransform2D"):
		$RemoteTransform2D.position.x = abs($RemoteTransform2D.position.x) * dir
		
	# 2. Inverte o HitboxSoco (A área da Martelada)
	if has_node("HitboxSoco"):
		$HitboxSoco.position.x = abs($HitboxSoco.position.x) * dir
		# Opcional: Se o Hitbox tiver um CollisionShape não centralizado, 
		# ele acompanhará a posição do pai HitboxSoco.
		
	# 3. Inverte o PontoImpacto (Onde nascem as bolas de neve)
	if has_node("PontoImpacto"):
		$PontoImpacto.position.x = abs($PontoImpacto.position.x) * dir
		
		
func flash_damage():
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(10, 10, 10), 0.05)
	tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.05)

func take_damage(amount, _from_pos = Vector2.ZERO, _is_projectile = false):
	flash_damage() # O corpo pisca para dar feedback visual
	
	# Se ainda for Fase 1 (filho do snowboss), repassa o dano para o HP global
	if get_parent().has_method("take_damage"):
		get_parent().take_damage(amount) 
	else:
		# Lógica de vida própria da Fase 2 (quando o pai já morreu)
		# health -= amount...
		pass

func _on_area_dano_body_entered(body):
	if body.is_in_group("player"):
		body.take_damage(1, global_position)
