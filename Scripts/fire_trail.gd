extends Area2D

# Dano por tempo + efeito visual de piscar antes de sumir
const LIFETIME     = 2.5
const BLINK_START  = 1.5
const DAMAGE_COOLDOWN = 0.5  # Evita dano a cada frame

var timer:          float = 0.0
var damage_timer:   float = 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	sprite.play("Fogo")

func _physics_process(delta: float) -> void:
	timer        += delta
	damage_timer  = max(0.0, damage_timer - delta)

	if timer >= BLINK_START:
		sprite.visible = int(timer * 6) % 2 == 0

	if timer >= LIFETIME:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage") and damage_timer <= 0:
		damage_timer = DAMAGE_COOLDOWN
		body.take_damage(1, global_position)
