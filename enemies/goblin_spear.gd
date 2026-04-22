extends CharacterBody2D

const SPEED = 200
const SPEAR = preload("uid://dg1tn2r6t6mfa")
@onready var hitbox: Hitbox = $Hitbox
@onready var area_2d: Area2D = $Area2D

signal hurt(hitbox: Hitbox)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hitbox.area_entered.connect(_on_area_entered)
	area_2d.body_entered.connect(_on_body_entered)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	move_and_slide()

func get_player() -> Player:
	return get_tree().get_first_node_in_group("player")

func _on_area_entered(area_2d: Area2D) -> void:
	hurt.emit(area_2d)
	queue_free()
	
func _on_body_entered(area_2d) -> void:
	queue_free()
	
func throw():
	var player = get_player()
	if player is Player:
		self.look_at(player.global_position)
		rotation_degrees -= 90
		velocity = self.global_position.direction_to(player.global_position) * SPEED
