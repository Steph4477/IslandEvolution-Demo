extends CanvasLayer

# -----------------------------
#            NODES
# -----------------------------
@onready var health_bar = $HealthBar
@onready var moko_lives = $HealthBar/MokoLives
@onready var portrait_3_lives = $HealthBar/MokoLives/Portrait3Lives
@onready var portrait_2_lives = $HealthBar/MokoLives/Portrait2lives
@onready var portrait_1_life = $HealthBar/MokoLives/Portrait1Life
@onready var portrait_0_life = $HealthBar/MokoLives/Portrait0Life

@onready var coco_button = $Gamepad/Coco
@onready var health_button = $Gamepad/Health
@onready var fire_button = $Gamepad/Fire

@onready var save_button = $Gamepad/Save
@onready var pause_button = $Gamepad/Break
@onready var break_sprite = get_node_or_null("BreakSprite")

@onready var banane_label = get_node_or_null("Gamepad/Health/BananeCountLabel")
@onready var coco_label = get_node_or_null("Gamepad/Coco/CocoCountLabel")

@onready var banane_hbox = get_node_or_null("HBoxContainerBanane")

@onready var banane_cooldown = $Gamepad/Health/coolDownCircle
@onready var fire_cooldown = $Gamepad/Fire/coolDownCircle

@onready var anim_coco = get_node_or_null("Gamepad/Coco/AnimCoco")
@onready var anim_potion = get_node_or_null("Gamepad/Health/AnimPotion")
@onready var anim_fire = get_node_or_null("Gamepad/Fire/AnimFire")

# --- Craft fire_skill ---
@onready var wood_check = get_node_or_null("FireCraftChecklist/WoodRow/Check")
@onready var wood_label_checklist = get_node_or_null("FireCraftChecklist/WoodRow/Label")

# --- Fire Hud ---
@onready var clac_fire_fx = $Gamepad/Hand/FireFX
@onready var kick_fire_fx = $Gamepad/Kick/FireFX
@onready var coco_fire_fx = $Gamepad/Coco/FireFX

# --- Quête lvl1 graines ---
@onready var lvl1_checklist = get_node_or_null("Lvl1Checklist")
@onready var lvl1_seed_check = get_node_or_null("Lvl1Checklist/SeedRow/Check")
@onready var lvl1_totem_check = get_node_or_null("Lvl1Checklist/TotemRow/Check")
@onready var lvl1_key_check = get_node_or_null("Lvl1Checklist/KeyRow/Check")


# -----------------------------
#            VARS
# -----------------------------
var gs

# ---- Cooldowns ---
var banane_cd_left = 0.0
var banane_cd_total = 1.0

var fire_cd_left = 0.0
var fire_cd_total = 1.0

# -----------------------------
#            READY
# -----------------------------
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

	gs = get_node("/root/GameState")
	gs.hud = self

	gs.health_bar = health_bar

	if gs.player:
		update_health_bar(gs.player.pv, gs.player.max_pv)
	coco_button.visible = false
	health_button.visible = false
	fire_button.visible = false

	if banane_hbox:
		banane_hbox.visible = false

	if lvl1_checklist:
		lvl1_checklist.visible = false

	set_button_enabled(coco_button, false)

	set_button_enabled(health_button, false)
	set_button_enabled(fire_button, false)
	
	update_lives_display(gs.lives)
	update_coco_display()
	update_fire_display()
	update_seed_display(gs.collected_seeds, gs.total_seeds_in_level)

	if gs.coco_count > 0 or gs.can_fire_coco:
		_show_coco()
		update_coco_display()

	if gs.banane_count > 0:
		_show_health()
		update_banane_display()

	for b in [coco_button, health_button, fire_button]:
		b.action = ""

	if break_sprite:
		break_sprite.visible = false

	banane_cooldown.visible = false
	fire_cooldown.visible = false

	update_lvl1_checklist()


func _process(delta):
	# --- CoolDown ---
	if banane_cd_left > 0.0:
		banane_cd_left -= delta
		if banane_cd_left < 0.0:
			banane_cd_left = 0.0
		banane_cooldown.value = (banane_cd_left / banane_cd_total) * banane_cooldown.max_value
		if banane_cd_left == 0.0:
			banane_cooldown.visible = false

	if fire_cd_left > 0.0:
		fire_cd_left -= delta
		if fire_cd_left < 0.0:
			fire_cd_left = 0.0

		fire_cooldown.value = (fire_cd_left / fire_cd_total) * fire_cooldown.max_value

		if fire_cd_left == 0.0:
			fire_cooldown.visible = false

# ---------------------------------------------
#         MAJ BARRE DE VIE DE MOKO
# ---------------------------------------------
func update_health_bar(pv, max_pv):
	if health_bar:
		health_bar.set_max_value(max_pv)
		health_bar.set_value(pv)

# -----------------------------
#        HELPERS VISIBILITÉ
# -----------------------------
func _show_coco():
	coco_button.visible = true
	set_button_enabled(coco_button, gs.coco_count > 0)

func _show_health():
	health_button.visible = true
	if banane_hbox:
		banane_hbox.visible = true

func _show_fire():
	fire_button.visible = true
	update_fire_display()

# -----------------------------
#        UPDATE HUD
# -----------------------------
func update_lives_display(lives):
	portrait_3_lives.visible = lives >= 3
	portrait_2_lives.visible = lives == 2
	portrait_1_life.visible = lives <= 1
	portrait_0_life.visible = lives <= 0


func set_button_enabled(button, enabled):
	if button == null:
		return

	var shape = button.get_node_or_null("CollisionShape2D")
	if shape:
		shape.disabled = not enabled

	if enabled:
		button.modulate = Color(1, 1, 1, 1)
	else:
		button.modulate = Color(1, 1, 1, 0.4)

func update_hud_buttons(can_fire_coco, can_heal, can_fire):
	if coco_button.visible:
		set_button_enabled(coco_button, can_fire_coco)

	if fire_button.visible:
		set_button_enabled(fire_button, can_fire)

	if health_button.visible:
		set_button_enabled(health_button, can_heal)

func update_seed_display(collected, total):
	var label = $HBoxContainerSeed/SeedCountLabel
	if total > 0:
		var pcent = int(round(float(collected) / float(total) * 100))
		label.text = "%d / %d (%d%%)" % [collected, total, pcent]
	else:
		label.text = "0 / 0 (0%)"

func update_banane_display():
	if banane_label:
		banane_label.text = str(gs.banane_count)

func update_coco_display():
	if coco_label:
		coco_label.text = str(gs.coco_count)
	if coco_button.visible:
		set_button_enabled(coco_button, gs.coco_count > 0)

func update_fire_display():
	if not gs.fire_buff_unlocked:
		fire_button.visible = false
		set_button_enabled(fire_button, false)
		return

	fire_button.visible = true
	set_button_enabled(fire_button, true)

func set_fire_attack_fx(active: bool):
	clac_fire_fx.emitting = active
	kick_fire_fx.emitting = active
	coco_fire_fx.emitting = active

# ============================================================================
#        BOSS FIGHT HUD
# ============================================================================
func set_gameplay_hud_visible(not_visible):
	$HBoxContainerSeed.visible = not_visible
	$BarSlot.visible = not_visible
	$HealthBar.visible = not_visible
	$Gamepad/Menu.visible = not_visible
	$Gamepad/Break.visible = not_visible
	$Gamepad/Save.visible = not_visible

# =============================================================================
#              QUETES LVL1 COLLECTE DE GRAINES                         
# ============================================================================
# --- Ultilitaire pour check les objectifs de quete accomplies
func update_check_texture(check_node, is_valid):
	if check_node == null:
		return

	if is_valid:
		check_node.texture = preload("res://Items/CheckBox/valid.png")
	else:
		check_node.texture = preload("res://Items/CheckBox/empty.png")

# --- Lvl1 collecte de graines ---  
func update_lvl1_checklist():
	if lvl1_checklist == null:
		return

	if not gs.lvl1_quest_revealed:
		lvl1_checklist.visible = false
		return

	lvl1_checklist.visible = true

	update_check_texture(lvl1_seed_check, gs.lvl1_seeds_done)
	update_check_texture(lvl1_totem_check, gs.lvl1_totem_done)
	update_check_texture(lvl1_key_check, gs.lvl1_key_done)


func appear_lvl1_quest():
	if lvl1_checklist:
		lvl1_checklist.visible = true

	var anim = get_node_or_null("Lvl1Checklist/AnimationPlayer")
	if anim:
		anim.play("appear_lvl1_quest")
		await anim.animation_finished

	update_lvl1_checklist()


func disappear_lvl1_quest():
	var anim = get_node_or_null("Lvl1Checklist/AnimationPlayer")
	if anim:
		anim.play("disappear_lvl1_quest")

# -----------------------------
#        COOLDOWN API
# -----------------------------
func start_banane_cooldown(duration):
	banane_cd_total = duration
	banane_cd_left = duration
	banane_cooldown.visible = true
	banane_cooldown.value = banane_cooldown.max_value

func start_fire_cooldown(duration):
	fire_cd_total = duration
	fire_cd_left = duration
	fire_cooldown.visible = true
	fire_cooldown.value = fire_cooldown.max_value


# ------------------------------------------------------------------------------
#                   APPEAR / ANIM_TO
# ------------------------------------------------------------------------------
func appear_coco():
	_show_coco()
	update_coco_display()
	if anim_coco:
		anim_coco.stop()
		anim_coco.play("appear_coco")

func anim_to_coco_mode():
	_show_coco()
	update_coco_display()
	if anim_coco:
		anim_coco.stop()
		anim_coco.play("anim_to_coco_mode")

func appear_health():
	_show_health()
	update_banane_display()
	if anim_potion:
		anim_potion.stop()
		anim_potion.play("appear_health")

func appear_fire():
	_show_fire()
	if anim_fire:
		anim_fire.stop()
		anim_fire.play("appear_fire")

func anim_to_health_mode():
	appear_health()

# ---------------------------------------------------------------------------------
#                                       RESET HUD (nouvelle partie)
# -----------------------------------------------------------------------------------
func reset_hud():
	coco_button.visible = false
	health_button.visible = false
	fire_button.visible = false

	if banane_hbox:
		banane_hbox.visible = false

	if lvl1_checklist:
		lvl1_checklist.visible = false

	set_button_enabled(coco_button, false)
	set_button_enabled(health_button, false)
	set_button_enabled(fire_button, false)

	update_lives_display(gs.lives)
	update_banane_display()
	update_coco_display()
	update_fire_display()
	update_seed_display(0, 0)

# ----------------------------------------
#            DIFFICULTY
# ----------------------------------------
func set_difficulty_color(color: Color):
	var roots = [
		get_node_or_null("Gamepad"),
		get_node_or_null("DirectionalArrow"),
		get_node_or_null("HBoxContainerSeed"),
		get_node_or_null("HBoxContainerBanane"),
		get_node_or_null("HBoxContainerHoney"),
		get_node_or_null("BarSlot"),
		get_node_or_null("Lvl1Checklist"),
		get_node_or_null("FireCraftChecklist"),
		get_node_or_null("AirCraftChecklist")
	]

	for node in roots:
		if node and node is CanvasItem:
			node.modulate = color

	if health_bar and health_bar.has_method("set_difficulty_color"):
		health_bar.set_difficulty_color(color)

# ---------------------------------------
#               BUTTONS
# ---------------------------------------
func _player_ready():
	return gs != null and gs.player != null and is_instance_valid(gs.player)


func _on_menu_pressed():
	if gs == null:
		return

	gs.load_level("res://Levels/Lvl0/lvl_0.tscn")


func _on_hand_pressed():
	if not _player_ready():
		return

	if gs.player.combat_mod:
		gs.player.combat_mod.clac()


func _on_coco_pressed():
	if not _player_ready():
		return

	if gs.player.combat_mod:
		gs.player.combat_mod.shoot_coco()


func _on_health_pressed():
	if not _player_ready():
		return

	if gs.player.heal_mod:
		gs.player.heal_mod.use_banane()

func _on_break_pressed():
	if gs == null:
		return

	gs.toggle_pause()

func set_pause_visual(paused):
	if break_sprite:
		break_sprite.visible = paused

func _on_fire_pressed():
	if not _player_ready():
		return

	if gs.player.skills_mod:
		gs.player.skills_mod.use_fire_buff()

func _on_kick_pressed():
	if not _player_ready():
		return

	if gs.player.combat_mod:
		gs.player.combat_mod.process_kick()

func _on_jump_pressed():
	if not _player_ready():
		return

	Input.action_press("jump")
	await get_tree().process_frame
	Input.action_release("jump")

func _on_save_pressed():
	if gs == null:
		return

	gs.save_game()
