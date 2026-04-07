extends Node2D

# --- VARIÁVEIS DE ESTADO ---
var health = 16
var fase_atual = 1

# --- REFERÊNCIAS ---
@onready var remote_transform = find_child("RemoteTransform2D", true)
@onready var cabeca_no = find_child("cabeca", true)
@onready var corpo_no = find_child("corpo", true)

func _ready():
	print("--- BOSS SPAWNOU ---")
	if remote_transform and cabeca_no:
		remote_transform.remote_path = cabeca_no.get_path()

func _process(_delta):
	if fase_atual == 1 and Input.is_action_just_pressed("weapon_2"):
		separar_boss()
	
	# Checa se os dois filhos foram destruídos para matar o Pai
	if fase_atual == 2 and get_child_count() == 0:
		morrer()

func take_damage(amount):
	if fase_atual == 1:
		health -= amount
		print("Dano Fase 1. Vida: ", health)
		if health <= 8:
			separar_boss()

func separar_boss():
	if fase_atual == 2: return
	fase_atual = 2
	
	# EFEITO VISUAL: Chacoalhar a tela apenas na divisão
	apply_shake(5.0, 0.2) # Um pouco mais forte e longo que o anterior
	
	if remote_transform:
		remote_transform.remote_path = "" 
		print("SOLTANDO CABEÇA!")
		
		if cabeca_no:
			cabeca_no.fase_atual = 2
			if cabeca_no.has_method("iniciar_quique"):
				cabeca_no.iniciar_quique()
		
		if corpo_no:
			corpo_no.fase_atual = 2
			if corpo_no.has_method("mudar_para_fase_2"):
				corpo_no.mudar_para_fase_2()

func morrer():
	print("Boss derrotado!")
	queue_free()

func apply_shake(intensity: float, duration: float):
	var cam = get_viewport().get_camera_2d()
	if cam:
		var start_pos = cam.offset
		for i in range(int(duration * 60)):
			cam.offset = start_pos + Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
			await get_tree().create_timer(0.01).timeout
		cam.offset = start_pos
