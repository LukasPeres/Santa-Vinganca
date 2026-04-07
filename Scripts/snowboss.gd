extends Node2D

# --- VARIÁVEIS DE ESTADO ---
var vida_maxima: float = 4.0
var vida_atual: float = 4.0
var fase_atual: int = 1

# --- REFERÊNCIAS ---
# Usando find_child como você prefere, mas garantindo os nomes
@onready var remote_transform = find_child("RemoteTransform2D", true)
@onready var cabeca_no = find_child("cabeca", true)
@onready var corpo_no = find_child("corpo", true)

func _ready():
	print("--- BOSS SPAWNOU ---")
	# Configuração inicial: Prender a cabeça
	if remote_transform and cabeca_no:
		remote_transform.remote_path = cabeca_no.get_path()
		print("Cabeça conectada e visível!")

func _process(_delta):
	# MOTIVO 2: Player apertou a tecla 2 (tiro reto)
	# Certifique-se que "weapon_2" existe no seu Input Map
	if fase_atual == 1 and Input.is_action_just_pressed("weapon_2"):
		print("Motivo: Arma 2 selecionada! Separando...")
		separar_boss()

# Função que os filhos (corpo/cabeca) vão chamar ao levar tiro
func take_damage(quantidade: float):
	vida_atual -= quantidade
	print("Vida do Boss: ", vida_atual)
	
	# Motivo 1: Vida pela metade
	if fase_atual == 1 and vida_atual <= (vida_maxima / 2):
		separar_boss()
	
	if vida_atual <= 0:
		morrer()

func separar_boss():
	if fase_atual == 2: return
	
	fase_atual = 2
	if remote_transform:
		remote_transform.remote_path = "" # Solta a cabeça
		print("SOLTANDO CABEÇA!")
		
		# Avisa a cabeça para quicar
		if cabeca_no and cabeca_no.has_method("iniciar_quique"):
			cabeca_no.iniciar_quique()
		
		# Avisa o corpo para mudar (se quiser que ele corra ou troque sprite)
		if corpo_no and corpo_no.has_method("mudar_para_fase_2"):
			corpo_no.mudar_para_fase_2()

func morrer():
	print("Boss derrotado!")
	queue_free()
