extends Node

var p
var saved_turnaxis_local_pos = Vector2.ZERO
var saved_turnaxis_top_level = false


func setup(player):
	p = player

# ============================================================================
#                                 PROCESS
# ============================================================================
func process(_delta):
	if p.is_hit_locked:
		return

	process_fire_buff()


# ============================================================================
#                                 BUFF
# ============================================================================
# --- Fire ___
func process_fire_buff():
	if p.is_hit_locked:
		return

	if Input.is_action_just_pressed(p.INPUT["fire_buff"]):
		use_fire_buff()

func use_fire_buff():
	if p.is_hit_locked:
		return

	if not p.game_state:
		return
	if not p.game_state.fire_buff_unlocked:
		return
	if p.fire_buff_active:
		return
	if p.fire_buff_mod == null:
		return

	p.fire_buff_mod.activate_fire_buff()

	p.popups_mod.show_info("🔥 Buff feu activé !")
