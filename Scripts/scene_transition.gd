extends CanvasLayer

@onready var rect = $rect

func _ready():
	rect.hide() # Garante que ele comece escondido
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE # FAÇA ISSO!
	
func fade_in():
	rect.show()
	var tween = get_tree().create_tween()
	tween.tween_property(rect, "modulate:a", 1.0, 0.5)
	await tween.finished

func fade_out():
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE # Libera o mouse IMEDIATAMENTE
	var tween = get_tree().create_tween()
	tween.tween_property(rect, "modulate:a", 0.0, 0.5)
	await tween.finished
	rect.hide()

func change_scene(target_scene_path: String):
	await fade_in()
	
	# Troca a cena
	get_tree().change_scene_to_file(target_scene_path)
	
	# Pequena pausa para garantir que a nova cena carregou os nós
	await get_tree().create_timer(0.1).timeout
	
	# Limpa qualquer rastro da tela de morte anterior (que pode ter sobrado na memória)
	# e clareia a tela
	await fade_out()
