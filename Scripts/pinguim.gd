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
			{"personagem": "Papanel", "emocao": "bravo", "texto": "DO QUE VOCÊ ESTÁ FALANDO? VOCÊ É EXATAMENTE COMO ELES!"},
			{"personagem": "Papanel", "emocao": "bravo", "texto": "ACHA QUE ME ENGANA CRIATURA VOADORA!?"},
			{"personagem": "Pinguim", "emocao": "triste", "texto": "Se é isso o que quer fazer… Vá em frente, já aceitei meu destino."},			{"personagem": "Papanel", "emocao": "bravo", "texto": "QUEM VOCÊ PENSA QUE É?"},
			{"personagem": "Papanel", "emocao": "bravo", "texto": "ACHA QUE EU NÃO CONSEGUIRIA TE DERROTAR SE VOCÊ ME ENFRENTAR?"},
			{"personagem": "Papanel", "emocao": "bravo", "texto": "VIRA HOMEM SEU BUNDA-MOLE!"},
			{"personagem": "Pinguim", "emocao": "triste", "texto": "…"},
			{"personagem": "Papanel", "emocao": "normal", "texto": "Você, criatura voadora, realmente vai ficar parado esperando seu fim?"},
			{"personagem": "Pinguim", "emocao": "triste", "texto": "Você não é o primeiro a tentar e nem vai ser o último…"},
			{"personagem": "Papanel", "emocao": "normal", "texto": "Hum?"},
			{"personagem": "Pinguim", "emocao": "normal", "texto": "Os outros pinguins estão bem armados."},
			{"personagem": "Pinguim", "emocao": "normal", "texto": "O Urso não economizou no preparo, mesmo sabendo que ele está liso."},
			{"personagem": "Papanel", "emocao": "normal", "texto": "Realmente, são adversários formidáveis, mas…"},
			{"personagem": "Papanel", "emocao": "bravo", "texto": "Espera, o Urso está… LISO?"},
			{"personagem": "Papanel", "emocao": "bravo", "texto": "DESDE QUANDO AQUELE INFELIZ ESTÁ QUEBRADO?"},
			{"personagem": "Papanel", "emocao": "bravo", "texto": "E O PIOR DE TUDO… COMO VOCÊ SABE DISSO?"},
			{"personagem": "Pinguim", "emocao": "triste", "texto": "Eu costumava ser um deles, mas meus equipamentos vieram com defeitos…"},
			{"personagem": "Pinguim", "emocao": "normal", "texto": "Sabe como o CHEFÃO é: não aceita imperfeições…"},
			{"personagem": "Papanel", "emocao": "normal", "texto": "Graças às “imperfeições” você não está detonado por mim como os outros!"},
			{"personagem": "Papanel", "emocao": "normal", "texto": "Será que você ainda tem utilidade para mim, criatura voadora?"},
			{"personagem": "Pinguim", "emocao": "normal", "texto": "Bem… nos últimos tempos notei que o Urso mudou."},
			{"personagem": "Pinguim", "emocao": "normal", "texto": "Seus gestos parecem diferentes… talvez você se surpreenda."},
			{"personagem": "Pinguim", "emocao": "normal", "texto": "Ele fala de um jeito incomum, agora usa até palavras difíceis."},
			{"personagem": "Pinguim", "emocao": "normal", "texto": "Fora o fato de estar mais azed-"},
			{"personagem": "Papanel", "emocao": "bravo", "texto": "ISSO É FRESCURA SUA!!!"},
			{"personagem": "Papanel", "emocao": "bravo", "texto": "CONHEÇO O URSO A MUITO TEMPO E ELE NUNCA MUDOU!"},
			{"personagem": "Papanel", "emocao": "bravo", "texto": "O ADVERSÁRIO QUE ESTUDO A ANOS NÃO ESTÁ DIFERENTE!"},
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
		self.set_deferred("monitoring", true)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_perto = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_perto = false
