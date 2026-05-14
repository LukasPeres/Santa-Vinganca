extends RigidBody2D

# --- CONFIGURAÇÕES DE CONTROLE ---
@export var velocidade_arremesso: float = 300.0
@export var velocidade_giro_soda: float = 200.0 
@export var intervalo_tiro: float = 0.5        
@export var gravidade_customizada: float = 0.8

var modo_soda: bool = false 
var active: bool = true
var timer_soda: float = 0.0
var timer_tiro: float = 0.0
var face_dir: int = 1 # <--- ADICIONADO: Para guardar a direção do Boss

@onready var SHARD_SCENE = preload("res://Entities/bottle_shard.tscn")
@onready var JET_SCENE = preload("res://Entities/soda_jet_bottle.tscn")

func setup(dir: int, angle_offset: float, is_soda: bool) -> void:
	modo_soda = is_soda
	face_dir = dir # <--- ADICIONADO: Salva se é -1 ou 1
	active = true
	gravity_scale = gravidade_customizada
	
	# <--- ADICIONADO: Ajusta a rotação inicial para a garrafa não "nascer" de costas
	if face_dir == -1:
		rotation_degrees = 180
	else:
		rotation_degrees = 0
	
	var angle := deg_to_rad(angle_offset - 45)
	linear_velocity = Vector2(cos(angle) * velocidade_arremesso * dir, sin(angle) * velocidade_arremesso)

func _physics_process(delta: float) -> void:
	if modo_soda:
		_comportamento_soda(delta)

func _comportamento_soda(delta: float) -> void:
	timer_soda += delta
	
	if timer_soda > 0.6 and timer_soda < 4.0:
		if not freeze:
			freeze = true 
			# <--- ADICIONADO: Zera a velocidade para ela não "deslizar" no ar enquanto atira
			linear_velocity = Vector2.ZERO
			angular_velocity = 0
		
		# <--- ALTERADO: Multiplicamos pelo face_dir para o giro seguir o sentido do arremesso
		rotation_degrees += (velocidade_giro_soda * face_dir) * delta 
		
		timer_tiro += delta
		if timer_tiro >= intervalo_tiro:
			timer_tiro = 0.0
			_disparar_balas()
			
	elif timer_soda >= 4.0:
		queue_free()

func _disparar_balas() -> void:
	for i in 2: 
		var jet = JET_SCENE.instantiate()
		get_parent().add_child(jet)
		jet.global_position = global_position
		
		var angle = rotation + (PI * i) 
		jet.direction = Vector2(cos(angle), sin(angle))

# Lógica de colisão para a garrafa comum (que quebra)
func _on_body_entered(_body: Node2D) -> void:
	if not active: return
	
	# Se NÃO for modo soda, ela explode em estilhaços ao bater
	if not modo_soda:
		active = false
		call_deferred("_spawn_shards")
		visible = false
		# Desativa colisões para evitar bugs
		collision_mask = 0
		collision_layer = 0
		get_tree().create_timer(0.1).timeout.connect(queue_free)

func _spawn_shards() -> void:
	for i in 4:
		var shard = SHARD_SCENE.instantiate()
		get_parent().add_child(shard)
		shard.global_position = global_position
		# Setup do caco com física
		if shard.has_method("setup"):
			shard.setup((PI / 2.0) * i + randf_range(-0.5, 0.5))
