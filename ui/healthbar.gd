extends TextureProgressBar

@export var player_stats: Stats

func _ready():
	max_value = player_stats.max_health
	value = player_stats.health
	player_stats.health_changed.connect(set_health)
	
	
func set_health(new_health) -> void:
	value = new_health
	
