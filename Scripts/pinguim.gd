extends Area2D

var player_perto = false
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	sprite.play("Idle")

func _process(_delta):
	if player_perto and Input.is_action_just_pressed("ui_accept"):
		iniciar_dialogo()
		
func iniciar_dialogo():
	var interface = get_tree().get_first_node_in_group("interface_sistema")
	
	if interface:
		self.set_deferred("monitoring", false)
		player_perto = false 
		
		var dialogo = [
			{"personagem": "Papanel", "emocao": "bravo", "texto": "AAAAAAAAAAAAAAAH!!!!!"},
			{"personagem": "Pinguim", "emocao": "triste", "texto": "NÃO! Por favor poupe minha vida, não tenho mais nada…"},
			{"personagem": "Papanel", "emocao": "normal", "texto": "Espera aí, você está… falando?"},
			{"personagem": "Pinguim", "emocao": "normal", "texto": "Vi o que fez com os outros. Eles mereceram."},
			{"personagem": "Papanel", "emocao": "bravo", "texto": "DO QUE VOCÊ ESTÁ FALANDO?"},
			{"personagem": "Papanel", "emocao": "bravo", "texto": "VOCÊ É EXATAMENTE COMO ELES!"},
			{"personagem": "Papanel", "emocao": "bravo", "texto": "ACHA QUE ME ENGANA CRIATURA VOADORA!?"},
			{"personagem": "Pinguim", "emocao": "triste", "texto": "Se é isso o que quer fazer…"},
			{"personagem": "Pinguim", "emocao": "triste", "texto": "vá em frente, já aceitei meu destino."},
			{"personagem": "Papanel", "emocao": "bravo", "texto": "QUEM VOCÊ PENSA QUE É?"},
			{"personagem": "Papanel", "emocao": "bravo", "texto": "ACHA QUE EU NÃO CONSEGUIRIA TE DERROTAR"},
			{"personagem": "Papanel", "emocao": "bravo", "texto": "SE VOCÊ ME ENFRENTAR?"},
			{"personagem": "Papanel", "emocao": "bravo", "texto": "VIRA HOMEM SEU BUNDA-MOLE!"},
			{"personagem": "Pinguim", "emocao": "triste", "texto": "…"},
			{"personagem": "Papanel", "emocao": "normal", "texto": "Você, criatura voadora, realmente vai ficar"},
			{"personagem": "Papanel", "emocao": "normal", "texto": "parado esperando seu fim?"},
			{"personagem": "Pinguim", "emocao": "triste", "texto": "Você não é o primeiro a tentar"},
			{"personagem": "Pinguim", "emocao": "triste", "texto": "e nem vai ser o último…"},
			{"personagem": "Papanel", "emocao": "normal", "texto": "Hum?"},
			{"personagem": "Pinguim", "emocao": "normal", "texto": "Os outros pinguins estão bem armados."},
			{"personagem": "Pinguim", "emocao": "normal", "texto": "O Urso não economizou no preparo,"},
			{"personagem": "Pinguim", "emocao": "normal", "texto": "mesmo sabendo que ele está liso."},
			{"personagem": "Papanel", "emocao": "normal", "texto": "Realmente, são adversários formidáveis, mas…"},
			{"personagem": "Papanel", "emocao": "bravo", "texto": "Espera, o Urso está… LISO?"},
			{"personagem": "Papanel", "emocao": "bravo", "texto": "DESDE QUANDO AQUELE INFELIZ"},
			{"personagem": "Papanel", "emocao": "bravo", "texto": "ESTÁ QUEBRADO?"},
			{"personagem": "Papanel", "emocao": "bravo", "texto": "E O PIOR DE TUDO..."},
			{"personagem": "Papanel", "emocao": "bravo", "texto": "COMO VOCÊ SABE DISSO?"},
			{"personagem": "Pinguim", "emocao": "triste", "texto": "Eu costumava ser um deles, mas meus equipamentos"},
			{"personagem": "Pinguim", "emocao": "triste", "texto": "vieram com defeitos…"},
			{"personagem": "Pinguim", "emocao": "normal", "texto": "Sabe como o CHEFÃO é:"},
			{"personagem": "Pinguim", "emocao": "normal", "texto": "não aceita imperfeições."},
			{"personagem": "Papanel", "emocao": "normal", "texto": "Graças às “imperfeições” você não está"},
			{"personagem": "Papanel", "emocao": "normal", "texto": "detonado por mim como os outros!"},
			{"personagem": "Papanel", "emocao": "normal", "texto": "Será que você ainda tem utilidade"},
			{"personagem": "Papanel", "emocao": "normal", "texto": "para mim, criatura voadora?"},
			{"personagem": "Pinguim", "emocao": "normal", "texto": "Bem… nos últimos tempos"},
			{"personagem": "Pinguim", "emocao": "normal", "texto": "notei que o Urso mudou."},
			{"personagem": "Pinguim", "emocao": "normal", "texto": "Seus gestos parecem diferentes…"},
			{"personagem": "Pinguim", "emocao": "normal", "texto": "talvez você se surpreenda."},
			{"personagem": "Pinguim", "emocao": "normal", "texto": "Ele fala de um jeito incomum,"},
			{"personagem": "Pinguim", "emocao": "normal", "texto": "agora usa até palavras difíceis."},
			{"personagem": "Pinguim", "emocao": "normal", "texto": "Fora o fato de estar mais azedo."},
			{"personagem": "Papanel", "emocao": "bravo", "texto": "ISSO É UMA FRESCURA SUA!"},
			{"personagem": "Papanel", "emocao": "bravo", "texto": "CONHEÇO O URSO A MUITO TEMPO"},
			{"personagem": "Papanel", "emocao": "bravo", "texto": "E ELE NUNCA MUDOU!"},
			{"personagem": "Papanel", "emocao": "bravo", "texto": "O ADVERSÁRIO QUE ESTUDO A ANOS"},
			{"personagem": "Papanel", "emocao": "bravo", "texto": "NÃO ESTÁ DIFERENTE!"},
			{"personagem": "Pinguim", "emocao": "triste", "texto": "…"},
			{"personagem": "Papanel", "emocao": "normal", "texto": "Adeus, criatura voadora."},
			{"personagem": "Papanel", "emocao": "normal", "texto": "Depois volto para te buscar."},
			{"personagem": "Papanel", "emocao": "normal", "texto": "(Será possível? Ele realmente mudaria?)"},
			{"personagem": "Papanel", "emocao": "normal", "texto": "(Não posso ignorar sinais como estes.)"},
			{"personagem": "Papanel", "emocao": "normal", "texto": "(Preciso ficar esperto.)"}
		]
		
		if not interface.is_connected("visibility_changed", _ao_mudar_visibilidade):
			interface.visibility_changed.connect(_ao_mudar_visibilidade)
			
		interface.iniciar_conversa("Pinguim", dialogo)

func _ao_mudar_visibilidade():
	var interface = get_tree().get_first_node_in_group("interface_sistema")
	if interface and not interface.visible:
		self.set_deferred("monitoring", true)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_perto = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_perto = false
