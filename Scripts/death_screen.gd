extends CanvasLayer

@onready var btn_recomecar = $RestartButton

func _ready():
	hide() 
	btn_recomecar.pressed.connect(_on_recomecar_pressed)
	
# No script da Tela de Morte
func aparecer():
	print("LOG: Executando lógica de exibição da lápide.")
	self.visible = true # Força a visibilidade do CanvasLayer
	show()
	btn_recomecar.grab_focus()

func _on_recomecar_pressed():
	# Desativa para evitar múltiplos cliques e sons repetidos
	btn_recomecar.disabled = true
	confirmar_renascimento()

func confirmar_renascimento():
	var fase_atual = get_tree().current_scene.scene_file_path
	
	# Usamos a função do SceneTransition que já faz o Fade In, Troca e Fade Out
	if SceneTransition.has_method("change_scene"):
		SceneTransition.change_scene(fase_atual)
	else:
		# Fallback caso algo esteja errado no Singleton
		get_tree().reload_current_scene()
