extends CanvasLayer

@onready var foto_rosto = $Control/TextureRect
@onready var texto_fala = $Control/RichTextLabel

var pode_interagir_agora: bool = false # Nova trava
var escrevendo: bool = false
var meu_tween: Tween 
var lista_completas: Array = []
var index_fala: int = 0

func _ready():
	self.visible = false
	texto_fala.bbcode_enabled = true

func _process(_delta):
	# Se a caixa acabou de abrir, ignoramos o input deste frame específico
	if not pode_interagir_agora:
		if self.visible:
			pode_interagir_agora = true
		return

	if Input.is_action_just_pressed("ui_accept") and self.visible:
		if escrevendo:
			pular_animacao()
		else:
			index_fala += 1
			mostrar_fala()

func pular_animacao():
	if meu_tween:
		meu_tween.kill() 
	texto_fala.visible_ratio = 1.0 
	escrevendo = false 

func iniciar_conversa(_nome: String, frases: Array):
	pode_interagir_agora = false # Trava o input no momento que abre
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.pode_se_mexer = false
		player.velocity = Vector2.ZERO
		player.status = player.PlayerState.idle
		if player.sprite:
			player.sprite.play("Idle")

	lista_completas = frases
	index_fala = 0
	self.visible = true
	mostrar_fala()

func mostrar_fala():
	if index_fala < lista_completas.size():
		escrevendo = true 
		var dados_atuais = lista_completas[index_fala]
		var personagem = dados_atuais.get("personagem", "Pinguim")
		var emocao = dados_atuais.get("emocao", "normal")
		var texto_puro = dados_atuais.get("texto", "")
		
		var caminho = "res://Sprites/Portraits/" + personagem + "/" + personagem + emocao + ".png"
		if FileAccess.file_exists(caminho):
			foto_rosto.texture = load(caminho)
		
		texto_fala.text = texto_puro
		texto_fala.visible_ratio = 0.0
		
		if meu_tween: meu_tween.kill() 
		meu_tween = create_tween()
		
		# Ajustei a velocidade: 0.03 fica um pouco mais dinâmico
		var duracao = clamp(texto_puro.length() * 0.04, 0.4, 3)
		meu_tween.tween_property(texto_fala, "visible_ratio", 1.0, duracao)
		
		# Conexão segura para evitar erros se o objeto sumir
		meu_tween.finished.connect(func(): escrevendo = false)
	else:
		fechar_dialogo()

func fechar_dialogo():
	self.visible = false
	pode_interagir_agora = false # Reseta para a próxima conversa
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.pode_se_mexer = true
