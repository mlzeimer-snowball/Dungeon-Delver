extends Node2D

@export var enemy_prefab: PackedScene
@onready var timer: Timer = $Timer

func _on_timer_timeout() -> void:
	var enemy = enemy_prefab.instantiate()
	add_child(enemy)
	timer.wait_time = randf_range(1,5)
