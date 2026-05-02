extends CanvasLayer

@export var asset_vida_cheia: Texture2D
@export var asset_vida_negra: Texture2D

@onready var container_coracoes = $Control/PainelPrincipal/CoracoesContainer

func _ready():
	# Espera um frame para garantir que o Player já entrou no grupo
	await get_tree().process_frame
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		# Conecta o sinal do Player à função de atualizar o visual
		player.vida_alterada.connect(atualizar_vida_display)
		# Inicializa o HUD com a vida atual do player
		atualizar_vida_display(player.health)

func atualizar_vida_display(vida_que_restou: int):
	var lista_de_coracoes = container_coracoes.get_children()
	
	for i in range(lista_de_coracoes.size()):
		# Se o índice do coração for menor que a vida, fica cheio
		# Ex: Vida 3 -> Índices 0, 1, 2 ficam cheios. 3 e 4 ficam negros.
		if i < vida_que_restou:
			lista_de_coracoes[i].texture = asset_vida_cheia
		else:
			lista_de_coracoes[i].texture = asset_vida_negra
