extends Node

var p
var firing_locked = false
var evolution = 0


func setup(player):
	p = player

# ============================================================================
#                                 PROCESS
# ============================================================================
func process():
	if p == null:
		return

	if p.is_hit_locked:
		p.is_attacking = false
		p.is_kicking = false
		p.is_jump_clacing = false
		return

	shoot()

	if Input.is_action_just_pressed(p.INPUT["clac"]):
		clac()

	kick_input()

# ============================================================================
#                                 DAMAGE
# ============================================================================
func get_evolved_damage(base_damage):
	if p.game_state.moko_evolution_percent != null:
		evolution = p.game_state.moko_evolution_percent
	return p.game_state.score_system.get_player_damage(
		base_damage,
		p.game_state.moko_evolution_percent
	)

# ============================================================================
#                                 SHOOT
# ============================================================================
func shoot():
	if p.is_hit_locked:
		return

	if firing_locked:
		return

	if Input.is_action_just_pressed(p.INPUT["fire"]) and p.can_fire_coco:
		firing_locked = true
		await coco()
		firing_locked = false
		return

func coco():
	if p.is_hit_locked:
		return

	if p.is_hanging or p.is_on_liana:
		return

	p.coco_count = p.game_state.coco_count
	p.can_fire_coco = p.game_state.can_fire_coco

	if not p.can_fire_coco:
		return
	if p.coco_count <= 0:
		return

	p.animation_locked = true

	if p.is_on_floor():
		p.anim.play("shoot")
	else:
		p.anim.play("jump_shoot")

	await p.anim.animation_finished

	if p.is_hit_locked:
		p.animation_locked = false
		return

	var scene = p.spell_coco
	var projectile_damage = GameBalance.PLAYER_DAMAGE["coco"]

	if p.game_state.fire_buff_unlocked and p.fire_buff_active:
		scene = p.spell_coco_fire
		projectile_damage = GameBalance.PLAYER_DAMAGE["coco_fire"]

	projectile_damage = get_evolved_damage(projectile_damage)

	var spell = scene.instantiate()
	spell.z_index = 100
	spell.z_as_relative = false

	var dir = 1
	if p.sprite.flip_h:
		dir = -1
	
	print("FIRE =", p.fire_buff_active)
	print("DAMAGE =", projectile_damage)
	print("EVOLUTION =", p.game_state.moko_evolution_percent)
	
	spell.start(p.get_node("ShootPoint").global_position, dir, projectile_damage)
	p.get_tree().current_scene.add_child(spell)

	p.coco_count -= 1
	p.can_fire_coco = p.coco_count > 0

	p.game_state.coco_count = p.coco_count
	p.game_state.can_fire_coco = p.can_fire_coco

	p.hud_mod.update_coco_display()

	p.animation_locked = false
	p.enter_combat_stance()
	p.hud_mod.refresh_hud_buttons()
	await p.get_tree().create_timer(p.rate_of_fire).timeout

# ============================================================================
#                           CLAC / HEADBUTT / KICK
# ============================================================================
func clac():
	if p.is_hit_locked:
		return

	await attack()

func kick_input():
	if p.is_hit_locked:
		return

	if not p.is_on_floor():
		return

	if not Input.is_action_just_pressed(p.INPUT["kick"]):
		return

	await kick()

func attack():
	if p.is_hit_locked:
		return

	if p.is_attacking or p.is_dead:
		return

	if p.is_hanging or p.is_on_liana:
		return

	p.is_attacking = true

	if p.is_on_floor():
		p.animation_locked = true
		p.anim.play("clac")

		await p.anim.animation_finished

		if p.is_hit_locked:
			p.get_node("ClacArea").monitoring = false
			p.animation_locked = false
			p.is_attacking = false
			return

		p.animation_locked = false
	else:
		p.is_jump_clacing = true
		p.anim.play("jump_clac")

		await p.anim.animation_finished

		if p.is_hit_locked:
			p.get_node("ClacArea").monitoring = false
			p.is_jump_clacing = false
			p.is_attacking = false
			return

		p.is_jump_clacing = false

	p.get_node("ClacArea").monitoring = false
	p.is_attacking = false
	p.enter_combat_stance()

func kick():
	if p.is_hit_locked:
		return

	if p.is_attacking or p.is_dead:
		return

	if not p.is_on_floor():
		return

	if p.is_on_liana :
		return

	p.is_attacking = true
	p.is_kicking = true
	p.animation_locked = true
	p.velocity.x = 0

	p.anim.play("kick")

	await p.anim.animation_finished

	if p.is_hit_locked:
		p.animation_locked = false
		p.is_kicking = false
		p.is_attacking = false
		return

	p.animation_locked = false
	p.is_kicking = false
	p.is_attacking = false

	p.enter_combat_stance()

# ============================================================================
#                         ALIAS API (HUD)
# ============================================================================
func shoot_coco():
	if p.is_hit_locked:
		return

	if firing_locked:
		return

	firing_locked = true
	await coco()
	firing_locked = false

func process_kick():
	if p.is_hit_locked:
		return

	await kick()
