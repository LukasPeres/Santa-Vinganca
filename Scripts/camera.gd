extends Camera2D

var target: Node2D


func _ready() -> void:
	limit_left = 0
	limit_bottom = 208
	get_target()


func _process(_delta: float) -> void:
	# Verifica se o player ainda existe
	if not is_instance_valid(target):
		get_target()
		return
	
	position = target.position


func get_target():
	var nodes = get_tree().get_nodes_in_group("player")

	if nodes.size() == 0:
		return   # NÃO dá erro todo frame

	target = nodes[0]

func set_limits(l, r, t, b):
	limit_left = l
	limit_right = r
	limit_top = t
	limit_bottom = b
	print("Limites atualizados: ", l, r, t, b) # Adicione esse print para debugar no console

func reset_limits():
	# Retorna aos valores que você usa na fase comum
	limit_left = 0
	limit_right = 1000000 
	limit_top = -1000000
	limit_bottom = 208 # O seu valor ideal
	print("Câmera resetada para a Fase 2")
