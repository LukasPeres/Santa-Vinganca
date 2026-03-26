extends Camera2D

var target: Node2D


func _ready() -> void:
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
