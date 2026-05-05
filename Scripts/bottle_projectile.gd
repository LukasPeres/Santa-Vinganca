extends RigidBody2D

var direction: int = 1
var is_shard_type: bool = false

const SHARD_SCENE = preload("res://Entities/bottle_shard.tscn")

func setup(dir: int, angle_offset_deg: float, shard_type: bool) -> void:
	direction = dir
	is_shard_type = shard_type
	var angle := deg_to_rad(angle_offset_deg - 45)  # -45° = arco parabólico
	var speed := 400.0
	linear_velocity = Vector2(cos(angle) * speed * dir, sin(angle) * speed)

func _on_body_entered(body: Node2D) -> void:
	if is_shard_type:
		_spawn_shards()
	queue_free()

func _spawn_shards() -> void:
	# Instancia 4 estilhaços em direções radiais ao colidir
	for i in 4:
		var shard = SHARD_SCENE.instantiate()
		shard.global_position = global_position
		var angle := (PI / 2.0) * i  # 4 direções: 0°, 90°, 180°, 270°
		shard.setup(angle)
		get_parent().add_child(shard)
