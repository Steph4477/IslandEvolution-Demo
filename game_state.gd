extends Node

# --- Sauvegarde ---
const SAVE_PATH = "user://savegame.json"          # Load = position exacte
const PROGRESS_PATH = "user://progress.json"      # Continuer = niveau débloqué + unlocks"
var has_pending_load = false
var pending_player_pos = Vector2.ZERO
var pending_level_path = ""
var unlocked_level_path = "res://Levels/Lvl1/lvl_1.tscn"

# Permet de sauvegarder depuis le menu (lvl0) quand player = null
var last_player_pos = Vector2.ZERO
var has_last_player_pos = false

# --- Données globales ---
var banane_count = 0
var coco_count = 0
var heal_amount = 0
var can_fire_coco = false
var has_key = false
var toucan_challenge_retry = false
var focus_cam_frog = false

# --- Collecte  ---
var seed_count = 0
var collected_seed_ids = []
var seed_level_path = ""

var killed_enemy_ids = []

var collected_loot_ids = []
var loot_level_path = ""


# --- Compétences débloquées ---
var double_jump_unlocked = false

# --- Dialogues uniques ---
var toucan_dialogue_seen = false

var lvl1_intro_seen = false



# --- Joueur, HUD & Scènes ---
var player_scene = preload("res://Player/player.tscn")
var player = null

var hud_scene = preload("res://Hud/Hud.tscn")
var hud = null

var health_bar = null

var fire_buff_unlocked = false


var fade_scene = preload("res://Effects/Fade/fade.tscn")
var fade = null

# --- Nœud gameplay (pausable) ---
var world = null  # contiendra level + player

# --- Vies & niveaux ---
var max_lives = 3
var lives = max_lives
var current_level_path = ""
var current_level = null

var skill_selected = "ramp"

# --- Symboles lvl2 ----
var correct_symbols = []
var selected_symbols = []

# --- Graines ---
var total_seeds_in_level = 0
var collected_seeds = 0

# --- Pause ---
var is_paused = false

# --- Signaux ---
signal all_seeds_collected
signal key_collected
signal player_updated(new_player)


##################################################################################
#                            QUETES                                              #
##################################################################################
# --- Craft skill_fire ---
var wood_collected = false


# --- Lvl_1 Collecte de graines ---
var lvl1_quest_revealed = false
var lvl1_seeds_done = false
var lvl1_totem_done = false
var lvl1_key_done = false


##################################################################################
#                            SCORE                                               #
##################################################################################
var score_system: ScoreSystem
var score_screen_scene = preload("res://Hud/ScoreScreen/score_screen.tscn")
var score_screen = null

# --- Bonus ---
var moko_evolution_percent = 0
var moko_damage_bonus_percent = 0
var moko_hp_bonus_percent = 0
var enemy_evolution_percent = 0
var score_evolution_applied = false

##################################################################################
#                            DIFFICULTE                                          #
##################################################################################
var difficulty = "explorer"

var explorer_unlocked = false
var survivor_unlocked = false
var king_unlocked = false

# Dialogue de fin à afficher au retour sur le menu.
# Valeurs possibles : "", "explorer", "survivor", "king"
var pending_end_dialogue: String = ""

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

	# --- score ---
	score_system = ScoreSystem.new()
	add_child(score_system)

	# --- score screen ---
	score_screen = score_screen_scene.instantiate()
	add_child(score_screen)

	print(score_screen)

	score_screen.visible = false

	# --- fondu au chargement ---
	fade = fade_scene.instantiate()
	add_child(fade)
	fade.process_mode = Node.PROCESS_MODE_ALWAYS

	# --- Création du monde qui contiendra les niveaux ---
	_create_world()
	
	# --- Réinitialise les dialogues de session pour éviter les répétitions ---
	reset_session_dialogues()

	await get_tree().process_frame

	var has_progress = load_global_progress()

	if has_progress:
		difficulty = get_continue_difficulty()
	else:
		difficulty = "explorer"
		explorer_unlocked = false
		survivor_unlocked = false
		king_unlocked = false

	print("======================================")
	print("INITIALISATION DIFFICULTES")
	print("PROGRESSION TROUVEE : ", has_progress)
	print("DIFFICULTY : ", difficulty)
	print("EXPLORER : ", explorer_unlocked)
	print("SURVIVOR : ", survivor_unlocked)
	print("KING : ", king_unlocked)
	print("======================================")

	#await load_level("res://Levels/Test/test_scene.tscn")
	#await load_level("res://Levels/Loader/loader.tscn")
	#await load_level("res://Levels/IntroCinematic/intro_cinematic.tscn")
	await load_level("res://Levels/Lvl0/lvl_0.tscn")
	#await load_level("res://Levels/Lvl1/lvl_1.tscn")

	await get_tree().process_frame

func _process(_delta):
	if Input.is_action_just_pressed("break"):
		toggle_pause()

	if Input.is_action_just_pressed("gc_menu") or Input.is_action_just_pressed("menu"):
		if not is_menu_scene(current_level_path):
			load_level("res://Levels/Lvl0/lvl_0.tscn")


func _create_world():
	if world and is_instance_valid(world):
		world.queue_free()
	world = Node.new()
	world.name = "World"
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)

func set_player(p):
	player = p

	# Mémorise position pour pouvoir sauver depuis le menu
	if player:
		last_player_pos = player.global_position
		has_last_player_pos = true

	emit_signal("player_updated", p)

# Nouvelle partie
func restart_game():
	reset_progression()
	await load_level("res://Levels/Lvl1/lvl_1.tscn")

# Continuer
func continue_game():
	load_global_progress()

	reset_lives()

	has_pending_load = false
	pending_player_pos = Vector2.ZERO

	await load_level(unlocked_level_path)


# Load
func load_save():
	var loaded = await load_game()

	if loaded:
		await load_level(pending_level_path)
	else:
		await load_level("res://Levels/Lvl1/lvl_1.tscn")

func reset_session_dialogues():
	toucan_dialogue_seen = false

func _find_spawn(level):
	var direct = level.get_node_or_null("SpawnPoint")
	if direct:
		return direct
	for child in level.get_children():
		var found = _find_spawn(child)
		if found:
			return found
	return null

func is_menu_scene(scene_path):
	return scene_path.contains("menu") or scene_path.contains("Menu") or scene_path.contains("Lvl0") or scene_path.contains("lvl_0")


######################################################################################
#                                     SCORE                                          #
######################################################################################
func can_show_score_screen():
	if current_level_path == "res://Levels/Lvl1/lvl_1.tscn":
		return true

	return false

func show_score_screen():
	if not can_show_score_screen():
		return

	if player:
		player.can_be_damaged = false
		player.can_move = false
		player.velocity = Vector2.ZERO

	score_system.calculate_stars()
	apply_moko_evolution()
	score_screen.show_score(
		get_current_level_title(),
		score_system.enemies_killed,
		score_system.enemies_total,
		score_system.stars,
		score_system.get_medal(),
		score_system.get_kill_percent(),
		score_system.get_moko_evolution_bonus(),
		score_system.get_enemy_evolution_bonus()
	)

func setup_level_score(level):
	score_system.reset_level_score()
	score_evolution_applied = false

	var enemies = level.find_child("Enemies", true, false)
	var total_enemies = 0

	if enemies:
		total_enemies = score_system.count_enemies_in_node(enemies)

	score_system.set_enemies_total(total_enemies)

	if has_pending_load:
		score_system.enemies_killed = killed_enemy_ids.size()

	print("SCORE - Total ennemis :", total_enemies)
	print("SCORE - Ennemis déjà tués :", score_system.enemies_killed)

func get_current_level_title():
	if current_level_path == "res://Levels/Lvl1/lvl_1.tscn":
		return "Jungle Tropicale"

	return "Territoire Inconnu"

######################################################################################
#                                 EVOLUTION                                          #
######################################################################################
func apply_moko_evolution():
	if score_evolution_applied:
		return

	var bonus = score_system.get_moko_evolution_bonus()
	var enemy_bonus = score_system.get_enemy_evolution_bonus()

	moko_evolution_percent += bonus
	moko_damage_bonus_percent = moko_evolution_percent
	moko_hp_bonus_percent += bonus
	enemy_evolution_percent += enemy_bonus

	score_evolution_applied = true

	print("MOKO EVOLUTION - Dégâts +", bonus, "%")
	print("MOKO EVOLUTION - PV +", bonus, "%")
	print("MOKO TOTAL - Dégâts +", moko_damage_bonus_percent, "%")
	print("MOKO TOTAL - PV +", moko_hp_bonus_percent, "%")
	print("ENNEMIS TOTAL +", enemy_evolution_percent, "%")

func apply_moko_hp_evolution(player_instance):
	var multiplier = score_system.get_moko_hp_multiplier(moko_hp_bonus_percent)

	player_instance.max_pv = int(round(player_instance.max_pv * multiplier))
	player_instance.pv = player_instance.max_pv

	print("MOKO HP - Bonus total +", moko_hp_bonus_percent, "%")
	print("MOKO HP - PV max :", player_instance.max_pv)

######################################################################################
#                                DIFFICULTES
######################################################################################

func get_continue_difficulty():
	if king_unlocked:
		return "king"
	elif survivor_unlocked:
		return "survivor"
	else:
		return "explorer"


func validate_current_difficulty():
	print("======================================")
	print("DIFFICULTE TERMINEE : ", difficulty)

	if difficulty == "explorer":
		explorer_unlocked = true
		print("EXPLORATEUR VALIDE")

	elif difficulty == "survivor":
		survivor_unlocked = true
		print("SURVIVANT VALIDE")

	elif difficulty == "king":
		king_unlocked = true
		print("ROI DE L'ILE VALIDE")

	# Une difficulté terminée = Continuer repart toujours du Lvl1
	unlocked_level_path = "res://Levels/Lvl1/lvl_1.tscn"

	save_progress()

	print("CONTINUER DEPUIS : ", unlocked_level_path)
	print("EXPLORER : ", explorer_unlocked)
	print("SURVIVOR : ", survivor_unlocked)
	print("KING : ", king_unlocked)
	print("======================================")

# ============================================================================
# DEBLOQUE LA DIFFICULTE SUIVANTE
# Appelée APRES la validation, au moment du déblocage / cinématique
# ============================================================================
func unlock_next_difficulty():
	print("======================================")
	print("DEBLOCAGE APRES : ", difficulty)

	if difficulty == "explorer":
		explorer_unlocked = true
		double_jump_unlocked = true
		difficulty = "survivor"
		unlocked_level_path = "res://Levels/Lvl1/lvl_1.tscn"

		print("EXPLORATEUR VALIDE")
		print("DOUBLE JUMP DEBLOQUE")
		print("PROCHAIN RUN : SURVIVANT")

	elif difficulty == "survivor":
		survivor_unlocked = true
		fire_buff_unlocked = true
		difficulty = "king"
		unlocked_level_path = "res://Levels/Lvl1/lvl_1.tscn"

		print("SURVIVANT VALIDE")
		print("FIRE BUFF DEBLOQUE")
		print("PROCHAIN RUN : ROI DE L'ILE")

	elif difficulty == "king":
		king_unlocked = true
		unlocked_level_path = "res://Levels/Lvl1/lvl_1.tscn"
		
		print("ROI DE L'ILE VALIDE")
		print("TOUTES LES DIFFICULTES SONT TERMINEES")

	save_progress()

	print("NOUVELLE DIFFICULTE : ", difficulty)
	print("EXPLORER : ", explorer_unlocked)
	print("SURVIVOR : ", survivor_unlocked)
	print("KING : ", king_unlocked)
	print("======================================")


# --- Relié au bouton Nouvelle Partie du lvl_0 ---
func reset_progression():
	# ============================================================
	# DIFFICULTE
	# ============================================================
	difficulty = "explorer"

	explorer_unlocked = false
	survivor_unlocked = false
	king_unlocked = false

	# ============================================================
	# EVOLUTION MOKO / ENNEMIS
	# ============================================================
	moko_damage_bonus_percent = 0
	moko_hp_bonus_percent = 0
	moko_evolution_percent = 0
	enemy_evolution_percent = 0
	score_evolution_applied = false

	# ============================================================
	# PROGRESSION
	# ============================================================
	current_level_path = "res://Levels/Lvl1/lvl_1.tscn"
	unlocked_level_path = "res://Levels/Lvl1/lvl_1.tscn"

	# Inventaire, skills, quêtes, collectibles, etc.
	reinitialise()

	# Vies
	reset_lives()

	# Dialogues
	reset_session_dialogues()

	# ============================================================
	# ETAT DE CHARGEMENT
	# ============================================================
	last_player_pos = Vector2.ZERO
	has_last_player_pos = false

	has_pending_load = false
	pending_level_path = ""
	pending_player_pos = Vector2.ZERO

	# ============================================================
	# SUPPRESSION DES ANCIENNES SAUVEGARDES
	# ============================================================
	if FileAccess.file_exists(PROGRESS_PATH):
		DirAccess.remove_absolute(PROGRESS_PATH)

	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

	print("======================================")
	print("NOUVELLE PARTIE - RESET COMPLET")
	print("DIFFICULTY : ", difficulty)
	print("EXPLORER : ", explorer_unlocked)
	print("SURVIVOR : ", survivor_unlocked)
	print("KING : ", king_unlocked)
	print("======================================")

func load_global_progress():
	if not FileAccess.file_exists(PROGRESS_PATH):
		return false

	var file = FileAccess.open(PROGRESS_PATH, FileAccess.READ)
	var content = file.get_as_text()
	file.close()

	var json = JSON.new()
	var result = json.parse(content)
	if result != OK:
		return false

	var data = json.data

	unlocked_level_path = data.get("unlocked_level_path", "res://Levels/Lvl1/lvl_1.tscn")

	difficulty = data.get("difficulty", "explorer")
	explorer_unlocked = data.get("explorer_unlocked", false)
	survivor_unlocked = data.get("survivor_unlocked", false)
	king_unlocked = data.get("king_unlocked", false)

	moko_damage_bonus_percent = int(data.get("moko_damage_bonus_percent", 0))
	moko_hp_bonus_percent = int(data.get("moko_hp_bonus_percent", 0))
	moko_evolution_percent = int(data.get("moko_evolution_percent", 0))
	enemy_evolution_percent = int(data.get("enemy_evolution_percent", 0))
	double_jump_unlocked = data.get("double_jump_unlocked", false)
	fire_buff_unlocked = data.get("fire_buff_unlocked", false)

	banane_count = int(data.get("banane_count", 0))
	
	coco_count = int(data.get("coco_count", 0))
	can_fire_coco = data.get("can_fire_coco", false)

	print("LOAD GLOBAL PROGRESS")
	print("DIFFICULTY LOADED : ", difficulty)
	print("SURVIVOR LOADED : ", survivor_unlocked)
	print("KING LOADED : ", king_unlocked)

func load_level(scene_path):
	resume_game()
	await fade.fade_out()

	# Sauvegarde position du player 
	if player:
		last_player_pos = player.global_position
		has_last_player_pos = true

	emit_signal("player_updated", null)
	player = null

	for child in world.get_children():
		child.queue_free()

	await get_tree().process_frame

	var level = load(scene_path).instantiate()
	current_level = level
	world.add_child(level)

	# --- Cache l'écran de score ---
	if score_screen:
		score_screen.visible = false

	# --- Score ---
	setup_level_score(level)

	var spawn_point = null

	if spawn_point == null:
		spawn_point = _find_spawn(level)

	var is_menu = spawn_point == null

	if is_menu:
		load_global_progress()

	# HUD
	if is_menu:
		if hud:
			hud.visible = false
		if health_bar:
			health_bar.visible = false
	else:
		if hud == null:
			hud = hud_scene.instantiate()
			add_child(hud)
			hud.process_mode = Node.PROCESS_MODE_ALWAYS
			health_bar = hud.get_node("HealthBar")

		hud.visible = true

		if health_bar:
			health_bar.visible = true

	if not is_menu:
		current_level_path = scene_path
		reset_seed_tracking_from_scene()
		reset_loot_tracking_from_scene()

		var is_loading_save = has_pending_load

		var p = player_scene.instantiate()
		level.add_child(p)

		if is_loading_save:
			p.global_position = pending_player_pos
		else:
			p.global_position = spawn_point.global_position
			p.velocity = Vector2.ZERO

		if not is_loading_save:
			if p.has_method("reset_state"):
				p.reset_state()
			else:
				p.pv = p.max_pv

		if not is_loading_save:
			p.velocity = Vector2.ZERO
			p.can_move = false

			await get_tree().physics_frame

			var ray = RayCast2D.new()
			ray.target_position = Vector2(0, 600)
			ray.collision_mask = p.collision_mask
			p.add_child(ray)
			ray.force_raycast_update()

			if ray.is_colliding():
				p.global_position.y = ray.get_collision_point().y

			ray.queue_free()

			p.velocity = Vector2.ZERO
			p.anim.play("idle")
			p.can_move = true

		apply_moko_hp_evolution(p)

		if health_bar:
			health_bar.update_health_bar(p.pv, p.max_pv)

		set_player(p)

		p.coco_count = coco_count
		p.seed_count = seed_count
		p.can_fire_coco = can_fire_coco
		p.double_jump_unlocked = double_jump_unlocked

		p.heal_potions.clear()
		for i in range(banane_count):
			p.heal_potions.append("banane")

		if hud:
			hud.update_lives_display(lives)
			hud.update_seed_display(collected_seeds, total_seeds_in_level)

			print("======================================")
			print("HUD FIRE DEBUG")
			print("DIFFICULTY : ", difficulty)
			print("FIRE UNLOCKED : ", fire_buff_unlocked)
			print("======================================")

			if fire_buff_unlocked:
				hud._show_fire()

			hud.update_fire_display()
			hud.update_banane_display()
			hud.update_coco_display()

	await fade.fade_in()

# ===================================================================
#                          SAVE / LOAD
# ===================================================================

func save_game():
	# Il faut au minimum avoir déjà lancé une partie
	if current_level_path == "":
		return false

	# Position : player si dispo, sinon last_player_pos (quand on est au menu)
	var pos = null
	if player:
		pos = player.global_position
	elif has_last_player_pos:
		pos = last_player_pos
	else:
		return false

	var data = {}

	data["level_path"] = current_level_path
	data["unlocked_level_path"] = unlocked_level_path
	data["player_pos"] = {"x": pos.x, "y": pos.y}

	if player:
		banane_count = player.heal_potions.size()
		seed_count = player.seed_count

	data["banane_count"] = banane_count
	data["coco_count"] = coco_count
	data["seed_count"] = seed_count
	data["lives"] = lives
	data["can_fire_coco"] = can_fire_coco
	data["double_jump_unlocked"] = double_jump_unlocked
	data["fire_buff_unlocked"] = fire_buff_unlocked

	data["killed_enemy_ids"] = killed_enemy_ids

	data["collected_loot_ids"] = collected_loot_ids
	data["loot_level_path"] = loot_level_path

	data["has_key"] = has_key
	
	data["wood_collected"] = wood_collected

	
	data["lvl1_intro_seen"] = lvl1_intro_seen

	data["difficulty"] = difficulty
	data["explorer_unlocked"] = explorer_unlocked
	data["survivor_unlocked"] = survivor_unlocked
	data["king_unlocked"] = king_unlocked

	data["moko_damage_bonus_percent"] = moko_damage_bonus_percent
	data["moko_hp_bonus_percent"] = moko_hp_bonus_percent
	data["moko_evolution_percent"] = moko_evolution_percent
	data["enemy_evolution_percent"] = enemy_evolution_percent


	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

	save_progress()

	if player and player.popups_mod:
		player.popups_mod.show_info("💾 Partie sauvegardée")

	return true

func load_game():
	if not FileAccess.file_exists(SAVE_PATH):
		return false

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var content = file.get_as_text()
	file.close()

	var json = JSON.new()
	var result = json.parse(content)
	if result != OK:
		return false

	var data = json.data
	await apply_save_data(data)
	load_global_progress()
	return true


func apply_save_data(data):
	pending_level_path = data.get("level_path", "")

	var pos_dict = data.get("player_pos", null)
	if pos_dict:
		pending_player_pos = Vector2(pos_dict["x"], pos_dict["y"])
		has_pending_load = true
	else:
		has_pending_load = false

	unlocked_level_path = data.get("unlocked_level_path", "res://Levels/Lvl1/lvl_1.tscn")

	banane_count = int(data.get("banane_count", 0))
	coco_count = int(data.get("coco_count", 0))
	seed_count = int(data.get("seed_count", 0))
	lives = int(data.get("lives", max_lives))

	can_fire_coco = data.get("can_fire_coco", false)

	double_jump_unlocked = data.get("double_jump_unlocked", false)
	fire_buff_unlocked = data.get("fire_buff_unlocked", false)

	killed_enemy_ids = data.get("killed_enemy_ids", [])

	collected_loot_ids = data.get("collected_loot_ids", [])
	loot_level_path = data.get("loot_level_path", "")

	has_key = data.get("has_key", false)

	wood_collected = data.get("wood_collected", false)
	
	lvl1_intro_seen = data.get("lvl1_intro_seen", false)

	difficulty = data.get("difficulty", "explorer")
	explorer_unlocked = data.get("explorer_unlocked", false)
	survivor_unlocked = data.get("survivor_unlocked", false)
	king_unlocked = data.get("king_unlocked", false)

	moko_damage_bonus_percent = int(data.get("moko_damage_bonus_percent", 0))
	moko_hp_bonus_percent = int(data.get("moko_hp_bonus_percent", 0))
	moko_evolution_percent = int(data.get("moko_evolution_percent", 0))
	enemy_evolution_percent = int(data.get("enemy_evolution_percent", 0))


# ===================================================================
#                          SAVEGARDE DE LA PROGRESSION (continuer)
# ===================================================================
func save_progress():
	var data = {}

	data["unlocked_level_path"] = unlocked_level_path
	data["difficulty"] = difficulty
	data["explorer_unlocked"] = explorer_unlocked
	data["survivor_unlocked"] = survivor_unlocked
	data["king_unlocked"] = king_unlocked

	data["banane_count"] = banane_count
	data["coco_count"] = coco_count
	data["fire_buff_unlocked"] = fire_buff_unlocked
	data["can_fire_coco"] = can_fire_coco
	data["double_jump_unlocked"] = double_jump_unlocked
	data["wood_collected"] = wood_collected

	data["killed_enemy_ids"] = killed_enemy_ids
	data["collected_loot_ids"] = collected_loot_ids
	data["collected_seed_ids"] = collected_seed_ids

	data["moko_damage_bonus_percent"] = moko_damage_bonus_percent
	data["moko_hp_bonus_percent"] = moko_hp_bonus_percent
	data["moko_evolution_percent"] = moko_evolution_percent
	data["enemy_evolution_percent"] = enemy_evolution_percent

	var file = FileAccess.open(PROGRESS_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
# ===================================================================

# --- Vies ---
func reset_lives():
	lives = max_lives
	if hud:
		hud.update_lives_display(lives)


func gain_life():
	if lives < max_lives:
		lives += 1
		if hud:
			hud.update_lives_display(lives)
		if player:
			player.popups_mod.show_info("❤️ +1 vie (" + str(lives) + "/" + str(max_lives) + ")")
		return true
	else:
		if player:
			player.popups_mod.show_info("❤️ Vies déjà au maximum (" + str(max_lives) + ")")
		return false


func is_game_over():
	return lives <= 0


func lose_life():
	if lives > 0:
		lives -= 1

		if hud:
			hud.update_lives_display(lives)

		reset_after_death()
		request_reload_after_delay(0.5)

func reset_after_death():
	get_tree().paused = false
	is_paused = false

	if hud and hud.has_method("set_pause_visual"):
		hud.set_pause_visual(false)

	if hud:
		hud.update_seed_display(collected_seeds, total_seeds_in_level)
		hud.update_banane_display()
		hud.update_coco_display()
		hud.update_fire_display()


func request_reload_after_delay(delay = 0.5):
	await get_tree().create_timer(delay).timeout
	if lives <= 0:
		load_level("res://Menu/Game_over/game_over.tscn")
	else:
		load_level(current_level_path)

###############################################################################
#                             COLLECTE PERSISTANTE
###############################################################################
func reset_seed_tracking_from_scene():
	var seeds = current_level.get_tree().get_nodes_in_group("Seed")

	if seed_level_path != current_level_path:
		seed_level_path = current_level_path
		collected_seed_ids.clear()
		collected_seeds = 0
		seed_count = 0
		total_seeds_in_level = seeds.size()

	collected_seeds = collected_seed_ids.size()
	seed_count = collected_seeds
	if hud:
		hud.update_seed_display(collected_seeds, total_seeds_in_level)


func add_seed_collected(seed_id):
	if collected_seed_ids.has(seed_id):
		return

	collected_seed_ids.append(seed_id)
	collected_seeds = collected_seed_ids.size()
	seed_count = collected_seeds

	if hud:
		hud.update_seed_display(collected_seeds, total_seeds_in_level)

	if collected_seeds >= total_seeds_in_level:
		lvl1_seeds_done = true

		if hud:
			hud.update_lvl1_checklist()

		emit_signal("all_seeds_collected")

func add_enemy_killed(enemy_id):
	if killed_enemy_ids.has(enemy_id):
		return

	killed_enemy_ids.append(enemy_id)

func add_loot_collected(loot_id):
	if collected_loot_ids.has(loot_id):
		return

	collected_loot_ids.append(loot_id)

func reset_loot_tracking_from_scene():
	if loot_level_path == "":
		loot_level_path = current_level_path
		return

	if loot_level_path != current_level_path:
		loot_level_path = current_level_path
		collected_loot_ids.clear()


# --- Signaux ---
func signal_key_collected():
	emit_signal("key_collected")

func _input(_event):
	if Input.is_action_just_pressed("gc_menu") or Input.is_action_just_pressed("menu"):
		if not is_menu_scene(current_level_path):
			load_level("res://Levels/Lvl0/lvl_0.tscn")


# --- Reset inventaire ---
func reinitialise():
	banane_count = 0
	coco_count = 0
	seed_count = 0
	collected_seed_ids.clear()
	seed_level_path = ""
	collected_seeds = 0

	killed_enemy_ids.clear()
	collected_loot_ids.clear()
	loot_level_path = ""

	can_fire_coco = false
	fire_buff_unlocked = false

	has_key = false

	double_jump_unlocked = false

	wood_collected = false
	
	lvl1_intro_seen = false

	lvl1_quest_revealed = false
	lvl1_seeds_done = false
	lvl1_totem_done = false
	lvl1_key_done = false


	if hud:
		var gamepad = hud.get_node("Gamepad")
		hud.set_button_enabled(gamepad.get_node("Coco"), false)
		hud.set_button_enabled(gamepad.get_node("Health"), false)

		hud.update_seed_display(0, total_seeds_in_level)
		hud.update_banane_display()
		hud.update_coco_display()

	if hud and hud.has_method("reset_hud"):
		hud.reset_hud()


# --- Pause ---
func toggle_pause():
	if is_menu_scene(current_level_path):
		return
	is_paused = not is_paused
	get_tree().paused = is_paused

	if hud and hud.has_method("set_pause_visual"):
		hud.set_pause_visual(is_paused)


func resume_game():
	is_paused = false
	get_tree().paused = false
	if hud and hud.has_method("set_pause_visual"):
		hud.set_pause_visual(false)
