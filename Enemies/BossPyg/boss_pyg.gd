extends EnemyGroundBase


# ============================================================================
#                                  RÉGLAGES
# ============================================================================

@export var projectile_scene = null

@export var projectile_spawn_delay = 0.8
@export var melee_attack_duration = 0.5

@export var jump_attack_interval = 15.0
@export var jump_velocity = -900.0

@export var quake_duration = 0.8
@export var quake_damage = 50

@export var block_duration = 1.0


# ============================================================================
#                                  COMBAT
# ============================================================================

var melee_distance = 0
var min_shoot_distance = 0
var max_shoot_distance = 0
var fire_interval = 0.0

var projectile_attack_animation = "throw_projectile"

var projectile_spawn = null
var target = null

var target_mod = EnemyModTarget.new()
var melee_mod = EnemyModMelee.new()
var throw_mod = EnemyModThrowProjectile.new()


# ============================================================================
#                                  ÉTATS
# ============================================================================

var is_throwing = false
var is_melee_attacking = false

var is_quake_jumping = false
var is_quaking = false
var has_left_floor = false

var quake_pending = false

var is_blocking = false
var moko_attack_count = 0

var boss_hit_lock_time = 0.5

# Le boss reste dormant jusqu'à la cinématique King.
var boss_active = false


# ============================================================================
#                                  NODES
# ============================================================================

@onready var jump_timer = $JumpTimer


# ============================================================================
#                                  READY
# ============================================================================

func _ready():
	super._ready()

	max_hp = GameBalance.ENEMY_HP["boss_pyg"]
	damage = GameBalance.ENEMY_DAMAGE["boss_pyg"]
	projectile_scene = load(GameBalance.ENEMY_PROJECTILE_SCENE["boss_pyg"])
	projectile_damage = GameBalance.ENEMY_PROJECTILE["spear_boss"]

	speed = GameBalance.ENEMY_SPEED["boss_pyg"]

	attack_range = GameBalance.ENEMY_RANGE["boss_pyg"]
	melee_distance = GameBalance.ENEMY_MELEE_DISTANCE["boss_pyg"]

	min_shoot_distance = GameBalance.ENEMY_MIN_SHOOT_DISTANCE["boss_pyg"]
	max_shoot_distance = GameBalance.ENEMY_MAX_SHOOT_DISTANCE["boss_pyg"]

	fire_interval = GameBalance.ENEMY_COOLDOWN["boss_pyg"]

	attack_anim_name = "attack"

	finalize_stats()

	min_shoot_distance = melee_distance

	projectile_spawn = $Rotator/ProjectileSpawn

	target_mod.setup(self)
	melee_mod.setup(self)
	throw_mod.setup(self)

	attack_timer.wait_time = melee_attack_duration
	attack_timer.stop()

	projectile_timer.wait_time = fire_interval
	projectile_timer.one_shot = true
	projectile_timer.stop()

	jump_timer.wait_time = jump_attack_interval
	jump_timer.one_shot = true
	jump_timer.stop()

	# ========================================================
	# ATTENTE DE LA CINÉMATIQUE KING
	# ========================================================

	boss_active = false
	velocity = Vector2.ZERO

	visible = true
	$Rotator.visible = false


# ============================================================================
#                              APPARITION BOSS
# ============================================================================

func start_boss_appear():
	if boss_active:
		return

	print("BOSS PYG : début apparition")

	velocity = Vector2.ZERO

	attack_timer.stop()
	projectile_timer.stop()
	jump_timer.stop()

	visible = true
	$Rotator.visible = true

	if anim and anim.has_animation("appear"):
		anim.play("appear")
		await anim.animation_finished
	else:
		push_error("BOSS PYG : animation appear introuvable")

	velocity = Vector2.ZERO

	print("BOSS PYG : apparition terminée")

func activate_boss():
	if boss_active:
		return

	boss_active = true
	velocity = Vector2.ZERO

	attack_timer.stop()
	projectile_timer.stop()
	jump_timer.stop()

	print("BOSS PYG : COMBAT ACTIVÉ")
# ============================================================================
#                                  PHYSICS
# ============================================================================

func _physics_process(delta):
	if not boss_active:
		velocity = Vector2.ZERO
		return

	if is_dead:
		return

	apply_gravity(delta)

	if is_blocking:
		velocity.x = 0
		move_and_slide()
		return

	if is_quake_jumping:
		update_quake_jump()
		move_and_slide()
		return

	if is_quaking:
		velocity.x = 0
		move_and_slide()
		return

	if is_throwing:
		velocity.x = 0
		move_and_slide()
		return

	if is_melee_attacking:
		velocity.x = 0
		move_and_slide()
		return

	if hit_locked:
		velocity.x = 0
		move_and_slide()
		return

	target_player()
	target_mod.update()

	if player == null:
		stop_combat()
		play_idle()
		move_and_slide()
		return

	flip()

	if distance > attack_range:
		stop_combat()
		run_to_player()
		move_and_slide()
		return

	if jump_timer.is_stopped() and not quake_pending:
		jump_timer.start()

	if quake_pending:
		start_quake_jump()

		if is_quake_jumping:
			move_and_slide()
			return

	if distance <= melee_distance:
		projectile_timer.stop()

		var was_attacking = is_attacking

		melee_mod.update_state()

		if not was_attacking and is_attacking:
			lock_melee_animation()

		velocity.x = 0
		move_and_slide()
		return

	melee_mod.update_state()

	if distance >= min_shoot_distance and distance <= max_shoot_distance:
		velocity.x = 0

		if projectile_timer.is_stopped():
			start_throw()
		else:
			play_idle()

		move_and_slide()
		return

	run_to_player()
	move_and_slide()


# ============================================================================
#                                  RUN
# ============================================================================

func run_to_player():
	if dx > 0:
		velocity.x = speed
	else:
		velocity.x = -speed

	if anim.current_animation != "run":
		anim.play("run")


# ============================================================================
#                             ARRÊT DU COMBAT
# ============================================================================

func stop_combat():
	velocity.x = 0

	in_melee = false

	is_attacking = false
	is_shooting = false

	is_melee_attacking = false

	quake_pending = false

	attack_timer.stop()
	projectile_timer.stop()
	jump_timer.stop()


# ============================================================================
#                              MELEE LOCK
# ============================================================================

func lock_melee_animation():
	if is_dead:
		return

	if is_melee_attacking:
		return

	if is_blocking:
		return

	is_melee_attacking = true
	velocity.x = 0

	await get_tree().create_timer(melee_attack_duration).timeout

	if is_dead:
		return

	is_melee_attacking = false


# ============================================================================
#                              PROJECTILE
# ============================================================================

func start_throw():
	if is_dead:
		return

	if player == null:
		return

	if target == null:
		return

	if is_blocking:
		return

	if is_throwing:
		return

	if is_melee_attacking:
		return

	if is_quaking:
		return

	if is_quake_jumping:
		return

	if not is_on_floor():
		return

	if quake_pending:
		return

	is_throwing = true
	velocity.x = 0

	flip()

	throw_mod.on_timer_timeout()

	projectile_timer.start()

	await get_tree().create_timer(projectile_spawn_delay).timeout

	if is_dead:
		return

	is_throwing = false


# ============================================================================
#                              QUAKE JUMP
# ============================================================================

func start_quake_jump():
	if is_dead:
		return

	if player == null:
		return

	if is_blocking:
		return

	if distance > attack_range:
		quake_pending = false
		return

	if is_throwing:
		return

	if is_melee_attacking:
		return

	if not is_on_floor():
		return

	quake_pending = false

	projectile_timer.stop()
	attack_timer.stop()
	jump_timer.stop()

	is_attacking = false
	is_shooting = false
	in_melee = false

	is_quake_jumping = true
	is_quaking = false

	has_left_floor = false

	velocity.x = 0
	velocity.y = jump_velocity

	anim.play("jump")


# ============================================================================
#                          SURVEILLANCE DU JUMP
# ============================================================================

func update_quake_jump():
	if not is_quake_jumping:
		return

	if not is_on_floor():
		has_left_floor = true

	if has_left_floor and is_on_floor():
		finish_quake_jump()


# ============================================================================
#                          FIN ANIMATION JUMP
# ============================================================================

func finish_quake_jump():
	if not is_quake_jumping:
		return

	is_quake_jumping = false
	is_quaking = true

	velocity.x = 0
	velocity.y = 0

	if anim.current_animation == "jump" and anim.is_playing():
		await anim.animation_finished

	if is_dead:
		return

	await shake_camera_and_damage_player()

	if is_dead:
		return

	is_quaking = false

	projectile_timer.stop()
	attack_timer.stop()

	if player != null:
		if distance <= attack_range:
			jump_timer.start()


# ============================================================================
#                       SHAKE CAMÉRA + DÉGÂTS
# ============================================================================

func shake_camera_and_damage_player():
	var cam = get_viewport().get_camera_2d()

	if cam == null:
		return

	var original_offset = cam.offset
	var elapsed = 0.0

	if player != null:
		if player.is_on_floor():
			player.damage_mod.on_hit(quake_damage)

	while elapsed < quake_duration:
		if is_dead:
			cam.offset = original_offset
			return

		var strength = 1.0 - (elapsed / quake_duration)

		cam.offset = original_offset + Vector2(
			randf_range(-35.0, 35.0) * strength,
			randf_range(-25.0, 25.0) * strength
		)

		await get_tree().process_frame

		elapsed += get_process_delta_time()

	cam.offset = original_offset


# ============================================================================
#                                  BLOCK
# ============================================================================

func start_block():
	if is_dead:
		return

	if is_blocking:
		return

	is_blocking = true

	velocity.x = 0

	is_attacking = false
	is_shooting = false
	is_melee_attacking = false
	in_melee = false

	attack_timer.stop()
	projectile_timer.stop()

	anim.play("block")

	await get_tree().create_timer(block_duration).timeout

	if is_dead:
		return

	is_blocking = false

	start_counter_attack()


# ============================================================================
#                                  RIPOSTE
# ============================================================================

func start_counter_attack():
	if is_dead:
		return

	target_player()
	target_mod.update()

	if player == null:
		return

	flip()

	if distance > melee_distance:
		return

	in_melee = true
	is_attacking = false
	can_melee_attack = true

	attack()

	attack_timer.start()

	if is_attacking:
		lock_melee_animation()


# ============================================================================
#                                  ON HIT
# ============================================================================

func on_hit(amount):
	if is_dead:
		return

	if is_blocking:
		return

	moko_attack_count += 1

	if moko_attack_count >= 3:
		moko_attack_count = 0
		start_block()
		return

	hp -= amount
	hp = max(hp, 0)

	if hb:
		hb.set_value(hp)

	_show_damage_popup(amount)

	if hp <= 0:
		die()
		return

	if hit_locked:
		return

	hit_locked = true

	if anim and anim.has_animation("onhit"):
		anim.play("onhit")

	await get_tree().create_timer(boss_hit_lock_time).timeout

	if is_dead:
		return

	hit_locked = false


# ============================================================================
#                                  DIE
# ============================================================================

func die():
	if is_dead:
		return

	in_melee = false

	is_throwing = false
	is_melee_attacking = false

	is_quaking = false
	is_quake_jumping = false

	is_blocking = false

	has_left_floor = false
	quake_pending = false

	attack_timer.stop()
	projectile_timer.stop()
	jump_timer.stop()

	var cam = get_viewport().get_camera_2d()

	if cam:
		cam.offset = Vector2.ZERO

	super.die()


# ============================================================================
#                              ATTACK TIMER
# ============================================================================

func _on_attack_timer_timeout():
	if is_dead:
		return

	if is_blocking:
		return

	if is_throwing:
		return

	if is_melee_attacking:
		return

	if is_quaking:
		return

	if is_quake_jumping:
		return

	if quake_pending:
		return

	melee_mod.on_timer_timeout()

	if is_attacking:
		lock_melee_animation()


# ============================================================================
#                           PROJECTILE TIMER
# ============================================================================

func _on_projectile_timer_timeout():
	if is_dead:
		return

	pass


# ============================================================================
#                              JUMP TIMER
# ============================================================================

func _on_jump_timer_timeout():
	if is_dead:
		return

	if player == null:
		return

	if distance > attack_range:
		return

	quake_pending = true
