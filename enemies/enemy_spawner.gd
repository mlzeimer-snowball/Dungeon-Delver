class_name EnemySpawner extends Node2D

@export var enemy_prefab: PackedScene
@onready var timer: Timer = $Timer

func _on_timer_timeout() -> void:
	var enemy = enemy_prefab.instantiate()
	add_child(enemy)
	timer.wait_time = randf_range(30,45)

func spawn(UID) -> void:
	enemy_prefab = preload("uid://dibn888a1bccm")
	var enemy = enemy_prefab.instantiate()
	add_child(enemy)
