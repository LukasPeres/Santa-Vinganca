extends CanvasLayer

@export var asset_vida_cheia: Texture2D
@export var asset_vida_negra: Texture2D
@onready var container_coracoes = $Control/PainelPrincipal/CoracoesContainer

@export var slot_bengala: Control
@export var slot_carvao: Control
@export var slot_elfo: Control

func _ready():
	await get_tree().process_frame
	
	# REMOVIDO O "var" DAQUI SE ELA JÁ ESTIVER NO TOPO OU SE FOR REPETIDA
	var player = get_tree().get_first_node_in_group("player") 
	
	if player:
		# Conecta os sinais via código (sem precisar da aba Sinais)
		player.vida_alterada.connect(atualizar_vida_display)
		player.arma_alterada.connect(atualizar_arma_selecionada)
		
		# Inicializa o visual com os valores atuais do Player
		atualizar_vida_display(player.health)
		atualizar_arma_selecionada(player.current_weapon)
	else:
		print("Erro: Player não encontrado no grupo 'player'")

func atualizar_vida_display(vida_que_restou: int):
	var lista_de_coracoes = container_coracoes.get_children()
	
	for i in range(lista_de_coracoes.size()):
		if i < vida_que_restou:
			lista_de_coracoes[i].texture = asset_vida_cheia
		else:
			lista_de_coracoes[i].texture = asset_vida_negra

func atualizar_arma_selecionada(tipo_arma: int):
	# Verificamos se os slots foram arrastados no Inspector para evitar erros
	if not slot_bengala or not slot_carvao or not slot_elfo:
		return

	# Resetamos a opacidade de todos (0.5 = desativado/escuro)
	slot_bengala.modulate.a = 0.5
	slot_carvao.modulate.a = 0.5
	slot_elfo.modulate.a = 0.5
	
	# Destacamos (1.0 = brilhante/ativo) apenas a arma que o Player enviou pelo sinal
	match tipo_arma:
		0: # WeaponType.melee
			slot_bengala.modulate.a = 1.0
		1: # WeaponType.gun
			slot_carvao.modulate.a = 1.0
		2: # WeaponType.elf_gun
			slot_elfo.modulate.a = 1.0
