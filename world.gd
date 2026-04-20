extends Node2D
@onready var respawn_marker_2d: Marker2D = $RespawnMarker2D

var score = 0
signal score_update

func _ready() -> void:
	var player = get_tree().get_first_node_in_group("player")
	player.respawned.connect(_on_player_respawned.bind(player))
	for enemy in get_tree().get_nodes_in_group("enemy"):
		enemy.enemy_death.connect(_on_enemy_death.bind(enemy))
	
func _on_player_respawned(player):
	player.global_position = respawn_marker_2d.global_position
	player.stats.health = player.stats.max_health
	score = 0
	score_update.emit()

func _on_enemy_death(enemy):
	score += enemy.XP
	score_update.emit()
