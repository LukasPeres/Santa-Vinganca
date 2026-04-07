extends Node2D

@export var boss_cena: PackedScene 
@onready var spawn_point = $Marker2D
@onready var paredes = $paredes_invisiveis
@onready var gatilho = $gatilho_entrada

func _ready():
	# Garante que as paredes comecem desativadas (atravessáveis)
	# Usamos o set_deferred para não causar erro de conflito na física
	paredes.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)

# Chame esta função quando o Boss morrer
func finalizar_luta():
	# 1. Libera o Player para seguir caminho
	paredes.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
	
	# 2. Reseta a Câmera
	var cam = get_viewport().get_camera_2d()
	if cam and cam.has_method("reset_limits"):
		cam.reset_limits()

# Esta é a função que o seu sinal está chamando:
func _on_gatilho_entrada_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		ativar_evento_boss()

func ativar_evento_boss():
	var cam = get_viewport().get_camera_2d()
	if cam and cam.has_method("set_limits"):
		# Pegamos a posição central da arena como base
		var centro_x = global_position.x
		var centro_y = global_position.y
		
		# --- CONFIGURAÇÃO DOS LIMITES ---
		# Ajuste esses números conforme o tamanho da arena do Pietro
		var limite_esq = centro_x + 336   # Esquerda
		var limite_dir = centro_x + 763  # Direita
		var limite_sup = centro_y - 600  # CIMA (Quanto menor o nº, mais sobe)
		var limite_inf = centro_y + 30  # BAIXO (Quanto maior o nº, mais desce)
		
		# Aplica os 4 limites na ordem correta: (Esquerda, Direita, Topo, Base)
		cam.set_limits(limite_esq, limite_dir, limite_sup, limite_inf)
	paredes.set_deferred("process_mode", Node.PROCESS_MODE_INHERIT)
# --- SPAWN SEGURO ---
	if boss_cena:
		var boss = boss_cena.instantiate()
		# Usamos o call_deferred para adicionar o boss sem erro de física
		get_parent().call_deferred("add_child", boss)
		# Definimos a posição. Se der erro de 'null', verifique o nome do Marker2D
		boss.global_position = spawn_point.global_position

	# Mudamos para call_deferred para evitar o erro "flushing queries"
	gatilho.call_deferred("queue_free")
