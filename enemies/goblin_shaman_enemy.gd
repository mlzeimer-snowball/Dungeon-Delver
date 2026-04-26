extends CharacterBody2D

const HIT_EFFECT = preload("uid://n4ayhex880q1")
const DEATH_EFFECT = preload("uid://qopvvt3pqdab")
const SUMMON_EFFECT = preload("uid://bigsoae0sv5i5")
const SPEAR = preload("uid://dg1tn2r6t6mfa")
const POISON_BOLT = preload("uid://lxtdmpa4qtpg")
const SLIME_SPAWNER = preload("uid://y8i66d1steai")

const SPEED = 40
const FRICTION = 500
const XP = 3

@export var min_range: = 80
@export var target_range: = 128
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
@onready var buffer_area_2d: Area2D = $BufferArea2D
@onready var summon: Marker2D = $Summon

@export var player: Player

signal enemy_death()

var state = "IdleState"
var spell_ready = true
var summon_ready = true
var attack_ready = true
var push_force = 250

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
	elif new_state == "SpellState":
		cast_spell()
	elif new_state == "SummonState":
		cast_summon()
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
		"SpellState":
			pass
		"SummonState":
			pass
	apply_buffers(delta)
	if velocity.length()>SPEED*1.2:
		velocity.limit_length(SPEED*1.2)
			
func die() -> void:
	var death_effect = DEATH_EFFECT.instantiate()
	get_tree().current_scene.add_child(death_effect)
	death_effect.global_position = center.global_position
	enemy_death.emit()
	queue_free()

func take_hit(other_hitbox: Hitbox, poison: bool) -> void:
	var hit_effect = HIT_EFFECT.instantiate()
	get_tree().current_scene.add_child(hit_effect)
	hit_effect.global_position = center.global_position
	stats.health -= other_hitbox.damage
	velocity = other_hitbox.knockback_direciton * other_hitbox.knockback_amount
	playback.start("HitState")
	
func cast_spell() -> void:
	var player: = get_player()
	if player is Player:
		var cur = sprite_2d.scale.x
		sprite_2d.scale.x = sign(global_position.direction_to(player.global_position).x)
		if sprite_2d.scale.x * cur <0:
			launcher.position.x = -abs(launcher.position.x)
		playback.start("SpellState")
		await playback.state_finished
		var poison_bolt = POISON_BOLT.instantiate()
		get_tree().current_scene.add_child(poison_bolt)
		poison_bolt.global_position = launcher.global_position
		poison_bolt.shoot()
		spell_ready = false
		attack_ready = false
		start_spell_timer()

func cast_summon() -> void:
	var player: = get_player()
	if player is Player:
		var summon_effect = SUMMON_EFFECT.instantiate()
		get_tree().current_scene.add_child(summon_effect)
		summon_effect.global_position = summon.global_position
		playback.start("SummonState")
		await playback.state_finished
		var slime_spawner = SLIME_SPAWNER.instantiate()
		get_tree().current_scene.add_child(slime_spawner)
		slime_spawner.global_position = summon.global_position
		slime_spawner.spawn("uid://dibn888a1bccm")
		summon_ready = false
		attack_ready = false
		start_summon_timer()
		
func start_spell_timer() -> void:
	await get_tree().create_timer(2).timeout
	attack_ready = true
	
	await get_tree().create_timer(randf_range(2,4)).timeout
	spell_ready = true
	
func start_summon_timer() -> void:
	await get_tree().create_timer(2).timeout
	attack_ready = true
	
	await get_tree().create_timer(randf_range(6,10)).timeout
	summon_ready = true

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

func apply_buffers(delta):
	var overlapping_bodies = buffer_area_2d.get_overlapping_areas()
	var separation_vector = Vector2.ZERO
	for body in overlapping_bodies:
		if body == self:
			continue
		var direction = (global_position - body.global_position).normalized()
		var distance = global_position.distance_to(body.global_position)
		var force = 1.0 - (distance / (buffer_area_2d.get_child(0).shape.radius * 2)) # Adjust based on shape
		separation_vector += direction * force
	velocity += separation_vector.normalized() * push_force * delta
			
