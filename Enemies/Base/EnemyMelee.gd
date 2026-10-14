extends EnemyGroundBase
class_name EnemyMelee


@export var balance_id = "snake_melee"

var melee_distance = 0
var attack_cooldown = 1.0
var animation_attack = "attack"
var animation_walk = "walk"

var melee_mod = EnemyModMelee.new()


func _ready():
	super._ready()

	# =========================================================================
	# GAME BALANCE
	# =========================================================================
	max_hp = GameBalance.ENEMY_HP[balance_id]
	damage = GameBalance.ENEMY_DAMAGE[balance_id]
	speed = GameBalance.ENEMY_SPEED[balance_id]
	attack_range = GameBalance.ENEMY_RANGE[balance_id]
	melee_distance = GameBalance.ENEMY_MELEE_DISTANCE[balance_id]
	attack_cooldown = GameBalance.ENEMY_COOLDOWN[balance_id]
	animation_attack = GameBalance.ENEMY_ANIMATION_ATTACK[balance_id]
	animation_walk = GameBalance.ENEMY_ANIMATION_WALK[balance_id]

	attack_anim_name = animation_attack

	# =========================================================================
	# EVOLUTION + HP + HEALTH BAR
	# =========================================================================
	finalize_stats()

	# =========================================================================
	# COMBAT
	# =========================================================================
	if attack_timer:
		attack_timer.wait_time = attack_cooldown
		attack_timer.stop()

	melee_mod.setup(self)

	# =========================================================================
	# PATROL
	# =========================================================================
	patrol_mod.setup(self)

	if patrol_timer:
		patrol_timer.wait_time = patrol_change_interval
		patrol_timer.start()

	patrol_mod.start()


func _physics_process(delta):
	if is_dead:
		return

	apply_gravity(delta)

	if knockback_active:
		move_and_slide()
		return

	target_player()

	# =========================================================================
	# PATROL : MOKO HORS DE PORTEE
	# =========================================================================
	if player == null or distance > attack_range:
		update_patrol_zone()
		return

	# =========================================================================
	# COMBAT : MOKO DETECTE
	# =========================================================================
	is_patrolling = false

	flip()

	melee_mod.update_state()

	if in_melee:
		velocity.x = 0

	else:
		move_to_target()

	move_and_slide()


func update_patrol_zone():
	is_patrolling = true

	if patrol_timer and patrol_timer.is_stopped():
		patrol_timer.start()

	patrol_mod.update_movement()

	# Flip selon la direction de patrouille
	if patrol_direction < 0:
		$Rotator.scale.x = -base_scale_x
	else:
		$Rotator.scale.x = base_scale_x

	# Animation
	if abs(velocity.x) > 0:
		if anim.current_animation != animation_walk:
			anim.play(animation_walk)
	else:
		play_idle()

	move_and_slide()


func move_to_target():
	if dx > stop_distance:
		velocity.x = speed

		if anim.current_animation != animation_walk:
			anim.play(animation_walk)

	elif dx < -stop_distance:
		velocity.x = -speed

		if anim.current_animation != animation_walk:
			anim.play(animation_walk)

	else:
		velocity.x = 0
		play_idle()


func _on_attack_timer_timeout():
	melee_mod.on_timer_timeout()


func _on_patrol_timer_timeout():
	patrol_mod.on_timer_timeout()
