extends CanvasLayer

@onready var btn_continuar = $BtnContinuar
@onready var txt_continuar = $BtnContinuar/RichTextLabel
@onready var btn_menu = $BtnMenu
@onready var txt_menu = $BtnMenu/RichTextLabel

func _ready():
	hide()
	
	btn_continuar.pressed.connect(_on_continuar_pressed)
	btn_menu.pressed.connect(_on_menu_pressed)
	
	btn_continuar.mouse_entered.connect(func(): _aplicar_hover(btn_continuar, txt_continuar, "Continuar"))
	btn_continuar.mouse_exited.connect(func(): _remover_hover(btn_continuar, txt_continuar, "Continuar"))
	
	btn_menu.mouse_entered.connect(func(): _aplicar_hover(btn_menu, txt_menu, "Título"))
	btn_menu.mouse_exited.connect(func(): _remover_hover(btn_menu, txt_menu, "Título"))
	
	btn_continuar.pivot_offset = btn_continuar.size / 2
	btn_menu.pivot_offset = btn_menu.size / 2

	# --- ADICIONE ESTAS LINHAS ABAIXO ---
	# Define o estado inicial (Preto e sem animação)
	_remover_hover(btn_continuar, txt_continuar, "Continuar")
	_remover_hover(btn_menu, txt_menu, "Título")

func _input(event):
	# Detecta o Esc (ui_cancel) para alternar o estado do pause
	if event.is_action_pressed("ui_cancel"):
		if not get_tree().paused:
			pausar()
		else:
			despausar()

func pausar():
	# Reseta o visual para o padrão antes de mostrar
	_remover_hover(btn_continuar, txt_continuar, "Continuar")
	_remover_hover(btn_menu, txt_menu, "Título")
	
	show()
	self.layer = 100 
	get_tree().paused = true
	btn_continuar.grab_focus()

func despausar():
	hide()
	get_tree().paused = false

# --- Efeitos Visuais (Estilo Santa Vingança) ---

func _aplicar_hover(obj_btn, obj_txt, texto_original):
	obj_txt.modulate = Color(1, 1, 1, 1) # Branco
	obj_txt.text = "[center][shake rate=20 level=5]" + texto_original + "[/shake][/center]"
	
	var tween = create_tween()
	tween.tween_property(obj_btn, "scale", Vector2(1.1, 1.1), 0.1).set_trans(Tween.TRANS_BACK)

func _remover_hover(obj_btn, obj_txt, texto_original):
	obj_txt.modulate = Color(0, 0, 0, 1) # Preto
	obj_txt.text = "[center]" + texto_original + "[/center]"
	
	var tween = create_tween()
	tween.tween_property(obj_btn, "scale", Vector2(1.0, 1.0), 0.1)

# --- Ações dos Botões ---

func _on_continuar_pressed():
	despausar()

func _on_menu_pressed():
	# Sempre despausar o motor antes de mudar de cena
	get_tree().paused = false
	# Substitua pelo caminho real do seu menu principal
	# get_tree().change_scene_to_file("res://cenas/menu_principal.tscn")
	print("Saindo para o menu...")
