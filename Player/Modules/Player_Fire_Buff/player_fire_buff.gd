extends Node

var p
var timer
var crackle_timer

var fire_buff_time_left = 0.0

var fire_aura_fx
var fire_smoke_fx
var fire_crackle_sfx


func setup(player):
	p = player

	fire_aura_fx = p.get_node_or_null("Node2D/FireAuraFX")
	fire_smoke_fx = p.get_node_or_null("Node2D/FireSmokeFX")
	fire_crackle_sfx = p.get_node_or_null("Node2D/FireCrackleSFX")

	if fire_aura_fx:
		fire_aura_fx.emitting = false

	if fire_smoke_fx:
		fire_smoke_fx.emitting = false

	if fire_crackle_sfx:
		fire_crackle_sfx.stop()

	# Timer principal du buff feu
	timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = p.fire_buff_duration
	add_child(timer)
	timer.timeout.connect(_on_fire_buff_timeout)

	# Timer des crépitements
	crackle_timer = Timer.new()
	crackle_timer.one_shot = true
	add_child(crackle_timer)
	crackle_timer.timeout.connect(_on_crackle_timeout)

	set_process(false)


func _process(delta):
	if not p.fire_buff_active:
		return

	fire_buff_time_left -= delta

	if fire_buff_time_left < 0.0:
		fire_buff_time_left = 0.0


func activate_fire_buff():
	p.fire_buff_active = true
	fire_buff_time_left = p.fire_buff_duration

	timer.stop()
	timer.wait_time = p.fire_buff_duration
	timer.start()

	set_process(true)

	if fire_aura_fx:
		fire_aura_fx.emitting = true

	if fire_smoke_fx:
		fire_smoke_fx.emitting = true

	_start_crackle()

	if p.game_state and p.game_state.hud:
		p.game_state.hud.start_fire_cooldown(p.fire_buff_duration)
		p.game_state.hud.set_fire_attack_fx(true)


func disable_fire_buff():
	p.fire_buff_active = false
	fire_buff_time_left = 0.0
	timer.stop()

	if crackle_timer:
		crackle_timer.stop()

	if fire_crackle_sfx:
		fire_crackle_sfx.stop()

	if fire_aura_fx:
		fire_aura_fx.emitting = false

	if fire_smoke_fx:
		fire_smoke_fx.emitting = false

	if p.game_state and p.game_state.hud:
		p.game_state.hud.set_fire_attack_fx(false)

	set_process(false)


func _start_crackle():
	if not fire_crackle_sfx:
		return

	fire_crackle_sfx.pitch_scale = randf_range(0.92, 1.08)
	fire_crackle_sfx.play()

	crackle_timer.wait_time = randf_range(1.4, 2.5)
	crackle_timer.start()


func _on_crackle_timeout():
	if not p.fire_buff_active:
		return

	_start_crackle()


func is_fire_buff_active():
	return p.fire_buff_active


func _on_fire_buff_timeout():
	disable_fire_buff()


func unlock_fire_skill():
	if p.game_state.fire_buff_unlocked:
		return

	p.game_state.fire_buff_unlocked = true

	if p.popups_mod:
		p.popups_mod.show_info("🔥 Skill feu débloqué")

	if p.game_state and p.game_state.hud:
		p.game_state.hud.disappear_fire_craft_quest()
