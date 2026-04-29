extends Area2D

# --- ESTADO DO NPC ---
var tem_dialogo_pendente = true # Se false, ele para de olhar e o sinal some
var esta_conversando = false
var player_perto = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
# @onready var icone_exclamacao = $Exclamacao # Já deixei aqui para o seu futuro nó

func _ready():
	sprite.play("Idle")
	# Garante que começa olhando para a direita
	sprite.flip_h = false 

func _process(_delta):
	gerenciar_visual()
	
	if player_perto and tem_dialogo_pendente and Input.is_action_just_pressed("ui_accept"):
		var player = get_tree().get_first_node_in_group("player")
		if player and player.pode_interagir():
			get_viewport().set_input_as_handled() 
			iniciar_dialogo()

func gerenciar_visual():
	# Regra: Se tem algo a falar e o player está perto OU se está no meio do papo
	if tem_dialogo_pendente and (player_perto or esta_conversando):
		olhar_para_player()
	else:
		# Se já falou tudo ou player saiu de perto, olha para a direita
		sprite.flip_h = false
	
	# Aqui você controlará o sinal de exclamação no futuro
	# if icone_exclamacao:
	#	icone_exclamacao.visible = tem_dialogo_pendente

func olhar_para_player():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		# Se a posição X do player for menor que a do pinguim, ele vira para a esquerda
		sprite.flip_h = player.global_position.x < global_position.x

func iniciar_dialogo():
	var interface = get_tree().get_first_node_in_group("interface_sistema")
	
	if interface:
		esta_conversando = true
		self.set_deferred("monitoring", false)
		player_perto = false
		
		var dialogo = [
			{"personagem": "Papanel", "emocao": "bravo", "texto": "AAAAAAAAAAAAAAAH!!!!!"},
			{"personagem": "Pinguim", "emocao": "triste", "texto": "NÃO! Por favor poupe minha vida, não tenho mais nada…"},
			{"personagem": "Papanel", "emocao": "normal", "texto": "Espera aí, você está… falando?"},
			{"personagem": "Pinguim", "emocao": "normal", "texto": "Vi o que fez com os outros. Eles mereceram."},
			{"personagem": "Papanel", "emocao": "bravo", "texto": "DO QUE VOCÊ ESTÁ FALANDO? VOCÊ É EXATAMENTE COMO ELES! ACHA QUE ME ENGANA CRIATURA VOADORA!?"},
			{"personagem": "Pinguim", "emocao": "triste", "texto": "Se é isso o que quer fazer… Vá em frente, já aceitei meu destino."},
			{"personagem": "Papanel", "emocao": "bravo", "texto": "QUEM VOCÊ PENSA QUE É? ACHA QUE EU NÃO CONSEGUIRIA TE DERROTAR SE VOCÊ ME ENFRENTAR? VIRA HOMEM SEU BUNDA-MOLE!"},
			{"personagem": "Pinguim", "emocao": "triste", "texto": "…"},
			{"personagem": "Papanel", "emocao": "normal", "texto": "Você, criatura voadora, realmente vai ficar parado esperando seu fim?"},
			{"personagem": "Pinguim", "emocao": "triste", "texto": "Você não é o primeiro a tentar e nem vai ser o último…"},
			{"personagem": "Papanel", "emocao": "normal", "texto": "Hum?"},
			{"personagem": "Pinguim", "emocao": "normal", "texto": "Os outros pinguins estão bem armados. O Urso não economizou no preparo, mesmo sabendo que ele está liso."},
			{"personagem": "Papanel", "emocao": "normal", "texto": "Realmente, são adversários formidáveis, mas…"},
			{"personagem": "Papanel", "emocao": "bravo", "texto": "Espera, o Urso está… LISO?"},
			{"personagem": "Papanel", "emocao": "bravo", "texto": "DESDE QUANDO AQUELE INFELIZ ESTÁ QUEBRADO? E O PIOR DE TUDO… COMO VOCÊ SABE DISSO?"},
			{"personagem": "Pinguim", "emocao": "triste", "texto": "Eu costumava ser um deles, mas meus equipamentos vieram com defeitos…"},
			{"personagem": "Pinguim", "emocao": "normal", "texto": "Sabe como é o CHEFÃO: não aceita imperfeições…"},
			{"personagem": "Papanel", "emocao": "normal", "texto": "Graças às “imperfeições” você não está detonado por mim como os outros!"},
			{"personagem": "Papanel", "emocao": "normal", "texto": "Será que você ainda tem util ​idade para mim, criatura voadora?"},
			{"personagem": "Pinguim", "emocao": "normal", "texto": "Bem… nos últimos tempos notei que o Urso mudou. Seus gestos parecem diferentes… talvez você se surpreenda."},
			{"personagem": "Pinguim", "emocao": "normal", "texto": "Ele fala de um jeito incomum, agora usa até palavras difíceis. Fora o fato de estar mais azed-"},
			{"personagem": "Papanel", "emocao": "bravo", "texto": "ISSO É FRESCURA SUA!!! "},
			{"personagem": "Papanel", "emocao": "bravo", "texto": "CONHEÇO O URSO A MUITO TEMPO E ELE NUNCA MUDOU! O ADVERSÁRIO QUE ESTUDO A ANOS NÃO ESTÁ DIFERENTE!"},
			{"personagem": "Pinguim", "emocao": "triste", "texto": "…"},
			{"personagem": "Papanel", "emocao": "normal", "texto": "Adeus, criatura voadora. Depois volto para te buscar."},
			{"personagem": "Papanel", "emocao": "normal", "texto": "(Será possível? Ele realmente mudaria?)"},
			{"personagem": "Papanel", "emocao": "normal", "texto": "(Não posso ignorar sinais como estes. Preciso ficar esperto.)"}		]
		
		if not interface.is_connected("visibility_changed", _ao_mudar_visibilidade):
			interface.visibility_changed.connect(_ao_mudar_visibilidade)
			
		interface.iniciar_conversa("Pinguim", dialogo)

func _ao_mudar_visibilidade():
	var interface = get_tree().get_first_node_in_group("interface_sistema")
	if interface and not interface.visible:
		# DIÁLOGO TERMINOU:
		esta_conversando = false
		tem_dialogo_pendente = false # <--- AQUI o terreno está preparado
		self.set_deferred("monitoring", true)
		print("Pinguim: Falei tudo o que tinha, agora vou olhar para a direita.")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_perto = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_perto = false
