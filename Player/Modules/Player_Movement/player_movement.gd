extends Node

var p
var fall_damage_consumed = false
var fall_landed_confirmed = false

func setup(player):
	p = player

# ============================================================================
#                                 PROCESS
# ============================================================================

func process(delta, was_on_floor):
	if p.is_hit_locked:
		p.velocity.x = 0
		return

	if not p.can_move:
		return

	process_climb()
	process_liana(delta)
	update_jump(delta)

	move_horizontal()

	process_hang_swing(delta)

	track_fall_speed(was_on_floor)

func post_physics(was_on_floor):
	apply_fall_damage(was_on_floor)
	process_wall_jump_input()

# ============================================================================
#                           MOUVEMENTS
# ============================================================================
func move_horizontal():
	if p.is_on_liana:
		p.velocity.x = 0
		return

	var dir = Input.get_action_strength(p.INPUT["right"]) - Input.get_action_strength(p.INPUT["left"])
	var current_speed = p.speed

	p.velocity.x = dir * current_speed

	if dir != 0:
		p.sprite.scale.x = abs(p.sprite.scale.x)

		if dir > 0:
			p.sprite.flip_h = false
		else:
			p.sprite.flip_h = true

# ============================================================================
#                                CLIMB
# ============================================================================
func process_climb():
	# pas en zone => on sort proprement du climb/hang
	if not p.can_climb:
		if p.climbing_anim != "" or p.is_hanging:
			p.climbing_anim = ""
			p.is_hanging = false
			p.hang_timer = 0.0
			p.sprite.rotation_degrees = 0
			p.velocity.y = 0
			if p.anim.current_animation == "hang":
				p.anim.play("idle")
		return

	# on est en zone climb : on initialise le mode
	if p.climbing_anim == "":
		p.climbing_anim = "climb_coco"
		p.anim.play("hang")
		p.velocity.y = 0
		p.is_hanging = true

	# input : ui_up OU action "climb" si tu l'utilises
	var up_pressed = Input.is_action_pressed("ui_up") 

	if up_pressed:
		if not p.anim.is_playing() or p.anim.current_animation != p.climbing_anim:
			p.anim.play(p.climbing_anim)
		p.velocity.y = -p.climb_speed
		p.is_hanging = false
	else:
		if p.anim.current_animation != "hang":
			p.anim.play("hang")
		p.velocity.y = 0
		p.is_hanging = true


func process_hang_swing(delta):
	if p.is_hanging:
		p.hang_timer += delta
		var swing = sin(p.hang_timer * 2.0) * 5
		p.sprite.rotation_degrees = swing
	else:
		p.sprite.rotation_degrees = 0
		p.hang_timer = 0.0

# ============================================================================
#                                LIANA
# ============================================================================
func process_liana(_delta):
	if not p.is_on_liana or p.current_liana == null or p.did_double_jump:
		return

	p.velocity = Vector2.ZERO
	hand_to_grip()

	var left = Input.is_action_pressed("ui_left")
	var right = Input.is_action_pressed("ui_right")
	if p.current_liana.has_node("Pivot"):
		if left:
			p.current_liana.angle_direction = 1
		elif right:
			p.current_liana.angle_direction = -1
		else:
			p.current_liana.angle_direction = 0

	if Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("ui_up"):
		var power = 900
		var angle_deg = p.current_liana.get_node("Pivot").rotation_degrees
		p.velocity = Vector2(0, -power).rotated(deg_to_rad(angle_deg))
		p.current_liana.expect_exit = true
		p.current_liana.on_player_detach()
		p.current_liana.disable_collision_temporarily(0.3)
		detach_to_liana()

func hand_to_grip():
	var grip = p.current_liana.get_node("Pivot/Grip")
	var hand = p.get_node("Node2D/AttachMarker")
	var delta = grip.global_position - hand.global_position
	p.global_position += delta

func attach_to_liana(liana):
	p.is_on_liana = true
	p.current_liana = liana
	if p.current_liana.has_method("on_player_attach"):
		p.current_liana.on_player_attach()

	p.velocity = Vector2.ZERO
	hand_to_grip()
	p.anim.play("climb_liana")

func detach_to_liana():
	p.is_on_liana = false
	p.current_liana = null
# ============================================================================
#                           JUMP / WALL JUMP
# ============================================================================
func update_jump(delta):
	if not p.can_move:
		p.is_jumping = false
		p.jump_count = 0
		return

	# Si Moko est sur un arbre, ui_up sert à grimper, pas à sauter
	if p.climbing_anim != "":
		p.is_jumping = false
		return

	if p.is_on_floor():
		p.jump_count = 0
		p.is_jumping = false

	p.max_jump_count = 1
	if p.double_jump_unlocked:
		p.max_jump_count = 2

	var jump_pressed = Input.is_action_just_pressed(p.INPUT["jump"])

	if jump_pressed and p.jump_count < p.max_jump_count:
		p.velocity.y = p.jump_force
		p.jump_count += 1
		p.is_jumping = true

	if not p.is_on_floor():
		p.is_jumping = true
		
		p.velocity.y += p.gravity * p.gravity_factor * delta


func process_wall_jump_input():
	if p.is_on_floor():
		return
	if p.is_on_liana:
		return

	if p.is_on_wall() and Input.is_action_just_pressed("jump"):
		wall_jump()

func wall_jump():
	var normal = p.get_wall_normal()
	var dir = -normal.x

	if dir == 0:
		if p.sprite.scale.x >= 0:
			dir = -1
		else:
			dir = 1

	p.velocity.y = p.jump_force
	p.velocity.x = dir * p.speed

# ============================================================================
#                           FALL DAMAGE
# ============================================================================
func track_fall_speed(was_on_floor):
	if not p.fall_damage_enabled:
		return

	if p.is_hit_locked:
		return

	if p.is_on_liana or p.climbing_anim != "" or p.is_hanging:
		p.fall_speed_track = 0
		fall_damage_consumed = false
		fall_landed_confirmed = false
		return

	# Après un impact consommé, on attend d'abord
	# d'avoir confirmé que Moko est réellement posé au sol.
	if fall_damage_consumed:
		if p.is_on_floor():
			fall_landed_confirmed = true

		# Nouveau vrai départ du sol.
		if fall_landed_confirmed and was_on_floor and not p.is_on_floor():
			fall_damage_consumed = false
			fall_landed_confirmed = false
			p.fall_speed_track = 0

		return

	# Chute normale
	if not p.is_on_floor():
		if p.velocity.y > p.fall_speed_track:
			p.fall_speed_track = p.velocity.y
	else:
		p.fall_speed_track = 0


func apply_fall_damage(was_on_floor):
	if not p.fall_damage_enabled:
		return

	if p.is_dead:
		return

	if p.is_hit_locked:
		return

	if fall_damage_consumed:
		return

	if not was_on_floor and p.is_on_floor():
		var impact_speed = p.fall_speed_track
		p.fall_speed_track = 0

		if impact_speed <= p.fall_safe_limit:
			return

		var dmg = p.fall_damage_min

		if impact_speed >= p.fall_speed_max:
			dmg = p.fall_damage_max
		else:
			var range_speed = p.fall_speed_max - p.fall_safe_limit
			var over_speed = impact_speed - p.fall_safe_limit
			dmg += (p.fall_damage_max - p.fall_damage_min) * over_speed / range_speed

		dmg = int(dmg)

		if dmg <= 0:
			return

		# Cet atterrissage est maintenant consommé.
		fall_damage_consumed = true
		fall_landed_confirmed = true

		p.damage_mod.on_hit(dmg)
