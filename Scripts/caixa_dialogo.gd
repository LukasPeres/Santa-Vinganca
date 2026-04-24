extends CanvasLayer

@onready var foto_rosto = $Control/TextureRect
@onready var texto_fala = $Control/RichTextLabel

var lista_completas: Array = []
var index_fala: int = 0

func _ready():
	self.visible = false
	texto_fala.bbcode_enabled = true

func iniciar_conversa(_nome: String, frases: Array):
	# 1. Procura o player e trava o movimento antes de começar
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.pode_se_mexer = false
	
	# 2. Configura os dados do diálogo
	lista_completas = frases
	index_fala = 0
	self.visible = true
	mostrar_fala()

func _input(event):
	if self.visible and event.is_action_pressed("ui_accept"):
		if texto_fala.visible_ratio < 1.0:
			texto_fala.visible_ratio = 1.0
		else:
			index_fala += 1
			mostrar_fala()

func mostrar_fala():
	if index_fala < lista_completas.size():
		var dados_atuais = lista_completas[index_fala]
		var personagem = dados_atuais.get("personagem", "Pinguim")
		var emocao = dados_atuais.get("emocao", "normal")
		var texto_puro = dados_atuais.get("texto", "")
		
		# Atualiza Portrait
		var caminho = "res://Sprites/Portraits/" + personagem + "/" + personagem + emocao + ".png"
		if FileAccess.file_exists(caminho):
			foto_rosto.texture = load(caminho)
		
		# Atualiza Texto
		texto_fala.text = texto_puro
		texto_fala.visible_ratio = 0.0
		
		var duracao = clamp(texto_puro.length() * 0.04, 0.5, 2.0)
		var tween = create_tween()
		tween.tween_property(texto_fala, "visible_ratio", 1.0, duracao)
	else:
		# --- O DIÁLOGO ACABOU AQUI ---
		self.visible = false
		index_fala = 0
		
		# 3. Procura o player e DESTRAVA o movimento
		var player = get_tree().get_first_node_in_group("player")
		if player:
			player.pode_se_mexer = true
