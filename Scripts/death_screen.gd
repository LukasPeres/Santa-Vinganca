extends CanvasLayer

@onready var btn_recomecar = $RestartButton
@onready var txt_recomecar = $RestartButton/RichTextLabel 
@onready var msg_morte = $MensagemMorte 

# Variável para travar o estado visual após o clique
var clicou: bool = false

const FRASE_LORE = "[center][wave amp=20 freq=2]Minha vingança... interrompida...[/wave][/center]"
const FRASE_FURIA = "[center][shake rate=20 level=8]EU NÃO ACEITO O FIM![/shake][/center]"

func _ready():
	hide() 
	btn_recomecar.pressed.connect(_on_recomecar_pressed)
	btn_recomecar.mouse_entered.connect(_on_mouse_entered)
	btn_recomecar.mouse_exited.connect(_on_mouse_exited)
	
	btn_recomecar.pivot_offset = btn_recomecar.size / 2
	_on_mouse_exited()

func aparecer():
	clicou = false # Reseta a trava quando a tela surge
	self.visible = true 
	show()
	
	msg_morte.text = FRASE_LORE
	msg_morte.visible_ratio = 0.0 
	msg_morte.modulate = Color(1, 1, 1, 1) # Garante que comece branco
	
	var tween_msg = create_tween()
	tween_msg.tween_property(msg_morte, "visible_ratio", 1.0, 1.5)
	
	_on_mouse_exited()

func _on_mouse_entered():
	# Se já clicou, não faz nada (mantém o visual de fúria)
	if clicou: return
	
	msg_morte.text = FRASE_FURIA
	msg_morte.visible_ratio = 1.0 
	msg_morte.modulate = Color(1, 1, 1, 1) # Mantém branco
	
	txt_recomecar.modulate = Color(1, 1, 1, 1)
	txt_recomecar.text = "[center][shake rate=20.0 level=5]Recomeçar[/shake][/center]"
	
	var tween = create_tween()
	tween.tween_property(btn_recomecar, "scale", Vector2(1.1, 1.1), 0.1)

func _on_mouse_exited():
	# SÓ RESETA SE NÃO TIVER CLICADO
	if clicou: return
	
	msg_morte.text = FRASE_LORE
	msg_morte.modulate = Color(1, 1, 1, 1) # Mantém branco
	
	txt_recomecar.modulate = Color(0, 0, 0, 1)
	txt_recomecar.text = "[center]Recomeçar[/center]"
	
	var tween = create_tween()
	tween.tween_property(btn_recomecar, "scale", Vector2(1.0, 1.0), 0.1)

func _on_recomecar_pressed():
	clicou = true # ATIVA A TRAVA
	btn_recomecar.disabled = true
	
	# Garante que o visual fique no modo "Fúria" e "Branco" permanentemente
	txt_recomecar.modulate = Color(1, 1, 1, 1)
	txt_recomecar.text = "[center][shake rate=30.0 level=10]Recomeçar[/shake][/center]"
	
	msg_morte.text = FRASE_FURIA
	msg_morte.modulate = Color(1, 1, 1, 1) # Travado no branco
	
	confirmar_renascimento()

func confirmar_renascimento():
	var fase_atual = get_tree().current_scene.scene_file_path
	if SceneTransition.has_method("change_scene"):
		SceneTransition.change_scene(fase_atual)
	else:
		get_tree().reload_current_scene()
