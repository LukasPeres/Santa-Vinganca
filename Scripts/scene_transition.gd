extends CanvasLayer

@onready var rect = $rect

func change_scene(target_scene_path: String):
	# Garante que o rect comece invisível e apareça no topo
	rect.modulate.a = 0.0 
	rect.show() # Garante que o nó não está oculto

	# 1. Fade In
	var tween = get_tree().create_tween()
	tween.tween_property(rect, "modulate:a", 1.0, 0.5)
	await tween.finished
	
	# 2. Muda a fase
	get_tree().change_scene_to_file(target_scene_path)
	
	# 3. Fade Out (Um pequeno atraso ajuda a ver o efeito)
	await get_tree().create_timer(0.1).timeout 
	var tween2 = get_tree().create_tween()
	tween2.tween_property(rect, "modulate:a", 0.0, 0.5)
