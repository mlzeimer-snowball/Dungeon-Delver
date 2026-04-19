extends StaticBody2D

@export var CRATE_EFFECT: PackedScene
@onready var hurtbox: Hurtbox = $Hurtbox

func _ready() -> void:
	hurtbox.hurt.connect(_on_hurt)

func _on_hurt(other_hitbox: Hitbox) -> void:
	var crate_effect_instance = CRATE_EFFECT.instantiate()
	get_tree().current_scene.add_child(crate_effect_instance)
	crate_effect_instance.global_position = global_position
	queue_free()
