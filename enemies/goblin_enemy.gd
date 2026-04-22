extends CharacterBody2D

const HIT_EFFECT = preload("uid://n4ayhex880q1")
const DEATH_EFFECT = preload("uid://qopvvt3pqdab")
const SPEAR = preload("uid://dg1tn2r6t6mfa")

const SPEED = 50
const FRICTION = 500
const XP = 3

@export var min_range: = 48
@export var target_range: = 96
@export var max_range: = 160
@export var escape_range: = 196

@export var stats: Stats

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var playback = animation_tree.get("parameters/StateMachine/playback") as AnimationNodeStateMachinePlayback
@onready var ray_cast_2d: RayCast2D = $RayCast2D
@onready var hurtbox: Hurtbox = $Hurtbox

@onready var center: Marker2D = $Center
@onready var navigation_agent_2d: NavigationAgent2D = $Marker2D/NavigationAgent2D
@onready var marker_2d: Marker2D = $Marker2D
@onready var launcher: Marker2D = $Launcher
@onready var timer: Timer = $Timer

@export var player: Player


signal enemy_death()

var state = "IdleState"
var attack_ready = true

func _ready() -> void:
	stats = stats.duplicate()
	hurtbox.hurt.connect(take_hit.call_deferred)
	stats.no_health.connect(die)
	
func update_state(new_state):
	if new_state!=state:
		_on_state_entered(new_state)
	state = new_state
			
func _on_state_entered(new_state):
	if new_state == "IdleStandState":
		velocity = Vector2.ZERO
	elif new_state == "IdleWalkState":
		velocity = Vector2(randf_range(-1,1),randf_range(-1,1)).normalized() * SPEED * .25
		sprite_2d.scale.x = sign(velocity.x)
	elif new_state == "MenaceStandState":
		await get_tree().create_timer(randf_range(.1,.5)).timeout
		velocity = Vector2.ZERO
	elif new_state == "MenaceWalkState":
		await get_tree().create_timer(randf_range(.1,.5)).timeout
		var player = get_player()
		if player is Player:
			navigation_agent_2d.target_position = player.global_position
			var next_point = navigation_agent_2d.get_next_path_position()
			velocity = global_position.direction_to(next_point-marker_2d.position).rotated(90*signf((randf()-.5))) * SPEED * .8
			sprite_2d.scale.x = sign(velocity.x)
		else:
			velocity = Vector2.ZERO
	elif new_state == "AttackState":
		attack()
	elif new_state == "FleeState":
		await get_tree().create_timer(randf_range(.1,.5)).timeout
	elif new_state == "ChaseState":
		await get_tree().create_timer(randf_range(.1,.5)).timeout
	
	
func _physics_process(delta: float) -> void:
	update_state(playback.get_current_node())
	match state:
		"IdleStandState":
			pass
		"IdleWalkState":
			move_and_slide()
		"ChaseState":
			var player: = get_player()
			if player is Player:
				navigation_agent_2d.target_position = player.global_position
				var next_point = navigation_agent_2d.get_next_path_position()
				velocity = global_position.direction_to(next_point-marker_2d.position) * SPEED
				sprite_2d.scale.x = sign(velocity.x)
			else:
				velocity = Vector2.ZERO
			move_and_slide()
		"HitState":
			velocity = velocity.move_toward(Vector2.ZERO,FRICTION * delta)
			move_and_slide()
		"FleeState":
			var player: = get_player()
			if player is Player:
				navigation_agent_2d.target_position = player.global_position
				var next_point = navigation_agent_2d.get_next_path_position()
				velocity = global_position.direction_to(next_point-marker_2d.position).rotated(180) * SPEED * 1.2
				sprite_2d.scale.x = sign(velocity.x)
			else:
				velocity = Vector2.ZERO
			move_and_slide()
		"MeanceStandState":
			pass
		"MenaceWalkState":
			move_and_slide()
		"AttackState":
			pass
			
func die() -> void:
	var death_effect = DEATH_EFFECT.instantiate()
	get_tree().current_scene.add_child(death_effect)
	death_effect.global_position = center.global_position
	enemy_death.emit()
	queue_free()

func take_hit(other_hitbox: Hitbox) -> void:
	var hit_effect = HIT_EFFECT.instantiate()
	get_tree().current_scene.add_child(hit_effect)
	hit_effect.global_position = center.global_position
	stats.health -= other_hitbox.damage
	velocity = other_hitbox.knockback_direciton * other_hitbox.knockback_amount
	playback.start("HitState")
	
func attack() -> void:
	var player: = get_player()
	if player is Player:
		playback.start("AttackState")
		await playback.state_finished
		var spear = SPEAR.instantiate()
		get_tree().current_scene.add_child(spear)
		spear.global_position = launcher.global_position
		#spear.rotation = spear.global_position.direction_to(player.global_position).angle()
		#print(spear.rotation)
		spear.throw()
		attack_ready = false
		start_attack_timer()
		
func start_attack_timer() -> void:
	await get_tree().create_timer(randf_range(2,5)).timeout
	attack_ready = true

func get_player() -> Player:
	return get_tree().get_first_node_in_group("player")
	
func is_player_escaped() -> bool:
	var result = false
	var player: = get_player()
	if player is Player:
		var distance_to_player = global_position.distance_to(player.global_position)
		if distance_to_player > escape_range:
			result = true
	return result

func is_player_in_range() -> bool:
	var result = false
	var player: = get_player()
	if player is Player:
		var distance_to_player = global_position.distance_to(player.global_position)
		if distance_to_player < max_range:
			result = true
	return result
	
func is_player_too_close() -> bool:
	var result = false
	var player: = get_player()
	if player is Player:
		var distance_to_player = global_position.distance_to(player.global_position)
		if distance_to_player < min_range:
				result = true
	return result
	
func is_player_within_target_range() -> bool:
	var result = false
	var player: = get_player()
	if player is Player:
		var distance_to_player = global_position.distance_to(player.global_position)
		if distance_to_player < target_range:
			result = true
	return result

func can_see_player() -> bool:
	if not is_player_in_range():
		return false
	var player: = get_player()
	ray_cast_2d.target_position = player.global_position - global_position
	ray_cast_2d.force_raycast_update()
	var has_los_to_player: = not ray_cast_2d.is_colliding()
	return has_los_to_player
