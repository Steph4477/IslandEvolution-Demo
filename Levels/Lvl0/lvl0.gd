extends Node2D

@onready var toucan_dialogue = $ToucanDialogue

@onready var environment_sprite = $Background/AnimatedSprite2D
@onready var smoke_ceiling = $Background/SmokeCeilling
@onready var fire_fx = $Background/FireFx

@onready var moko = $Background/Moko
@onready var moko_anim: AnimationPlayer = $Background/Moko/AnimationPlayer

var gs
var player = null


# ============================================================================
#                              DIALOGUES
# ============================================================================

const WELCOME_DIALOGUE: Array[String] = [
	"Bienvenue Moko sur l'Île de l'Évolution.",
	"Les créatures évoluent sans cesse.",
	"Mais toi aussi tu peux évoluer.",
	"Ton aventure commence maintenant."
]


const EXPLORER_END_DIALOGUE: Array[String] = [
	"Bravo, Moko !",
	"Tu as triomphé de la Jungle.",
	"Mais l’île va évoluer…",
	"Tu peux maintenant utiliser le Double Saut !",
	"Mode Survivant débloqué !"
]


const SURVIVOR_END_DIALOGUE: Array[String] = [
	"Impressionnant, Moko !",
	"Tu as survécu à une île bien plus dangereuse.",
	"Mais elle va encore évoluer…",
	"Tu peux maintenant utiliser le pouvoir du Feu !",
	"Mode Roi de l’île débloqué !"
]


const KING_END_DIALOGUE: Array[String] = [
	"Tu l’as fait, Moko !",
	"L’île t’a tout donné.",
	"Tu as affronté sa forme ultime…",
	"Et tu es toujours debout.",
	"Tu es le Roi de l’île !"
]


# ============================================================================
#                              INITIALISATION
# ============================================================================

func _ready():
	$sound/dijee.play()

	gs = get_node_or_null("/root/GameState")

	if not gs:
		push_error("LVL0 : GameState introuvable")
		return

	# ------------------------------------------------------------------------
	# Moko démarre toujours en idle
	# ------------------------------------------------------------------------

	if moko_anim.has_animation("idle"):
		moko_anim.play("idle")

	# ------------------------------------------------------------------------
	# Progression
	# ------------------------------------------------------------------------

	gs.load_global_progress()

	# ------------------------------------------------------------------------
	# Mise à jour visuelle du menu
	# ------------------------------------------------------------------------

	refresh_difficulty_buttons()
	_apply_environment_difficulty()

	await get_tree().process_frame

	# ------------------------------------------------------------------------
	# Gestion du Toucan / récompense
	# ------------------------------------------------------------------------

	await _handle_toucan_dialogue()


# ============================================================================
#                         GESTION DU TOUCAN
# ============================================================================

func _handle_toucan_dialogue():
	# ------------------------------------------------------------------------
	# PRIORITÉ 1 :
	# Le joueur vient de terminer une difficulté.
	# ------------------------------------------------------------------------

	if gs.pending_end_dialogue != "":
		var completed_difficulty: String = gs.pending_end_dialogue

		# L'événement est consommé immédiatement.
		# Il ne sera pas rejoué lors du prochain retour au menu.
		gs.pending_end_dialogue = ""

		_set_menu_buttons_enabled(false)

		await _play_end_sequence(completed_difficulty)

		_set_menu_buttons_enabled(true)

		return

	# ------------------------------------------------------------------------
	# PRIORITÉ 2 :
	# Première arrivée dans le jeu.
	# ------------------------------------------------------------------------

	if _is_first_game_state():
		_set_menu_buttons_enabled(false)

		await toucan_dialogue.play_dialogue(WELCOME_DIALOGUE)

		_set_menu_buttons_enabled(true)


# ============================================================================
#                    PREMIÈRE ARRIVÉE DANS LE JEU
# ============================================================================

func _is_first_game_state() -> bool:
	return (
		not gs.explorer_unlocked
		and not gs.survivor_unlocked
		and not gs.king_unlocked
	)


# ============================================================================
#                       SÉQUENCE DE FIN DE RUN
# ============================================================================

func _play_end_sequence(completed_difficulty: String):
	var dialogue_lines: Array[String] = []

	match completed_difficulty:

		"explorer":
			dialogue_lines = EXPLORER_END_DIALOGUE

		"survivor":
			dialogue_lines = SURVIVOR_END_DIALOGUE

		"king":
			dialogue_lines = KING_END_DIALOGUE

		_:
			push_warning(
				"LVL0 : difficulté inconnue pour le dialogue : "
				+ completed_difficulty
			)
			return


	print("======================================")
	print("MENU - SÉQUENCE FIN DE RUN")
	print("DIFFICULTÉ : ", completed_difficulty)
	print("======================================")


	# ========================================================================
	# 1. TOUCAN : INTRO + SPEECH COMPLET
	# ========================================================================

	await toucan_dialogue.play_dialogue(dialogue_lines)


	# ========================================================================
	# 2. TOUCAN RESTE PRÉSENT
	#    MOKO REÇOIT SA RÉCOMPENSE
	# ========================================================================

	await _play_moko_reward(completed_difficulty)


	# ========================================================================
	# 3. MOKO EST REVENU EN IDLE
	#    LE TOUCAN PEUT MAINTENANT PARTIR
	# ========================================================================

	await toucan_dialogue.fly_away()


	# ========================================================================
	# 1. LE TOUCAN FAIT TOUT SON SPEECH
	# ========================================================================

	await toucan_dialogue.play_dialogue(dialogue_lines)


	# ========================================================================
	# 2. SPEECH TERMINÉ -> MOKO REÇOIT SA RÉCOMPENSE
	# ========================================================================

	await _play_moko_reward(completed_difficulty)


# ============================================================================
#                         RÉCOMPENSE DE MOKO
# ============================================================================
func _play_moko_reward(completed_difficulty: String):
	match completed_difficulty:

		# --------------------------------------------------------------------
		# EXPLORER -> DOUBLE SAUT
		# --------------------------------------------------------------------

		"explorer":
			if moko_anim.has_animation("loot_skill"):
				print("✨ MOKO - LOOT DOUBLE SAUT")

				moko_anim.play("loot_skill")
				await moko_anim.animation_finished

			else:
				push_warning(
					"LVL0 : animation 'loot_skill' introuvable"
				)


		# --------------------------------------------------------------------
		# SURVIVOR -> POUVOIR DU FEU
		# --------------------------------------------------------------------

		"survivor":
			if moko_anim.has_animation("fire_buff"):
				print("🔥 MOKO - FIRE BUFF")

				moko_anim.play("fire_buff")
				await moko_anim.animation_finished

			else:
				push_warning(
					"LVL0 : animation 'fire_buff' introuvable"
				)


		# --------------------------------------------------------------------
		# KING -> PAS DE NOUVEAU POUVOIR
		# --------------------------------------------------------------------

		"king":
			print("🏆 MOKO - ROI DE L'ÎLE")


	# ------------------------------------------------------------------------
	# Toujours revenir en idle
	# ------------------------------------------------------------------------

	if moko_anim.has_animation("idle"):
		moko_anim.play("idle")


# ============================================================================
#                         ACTIVATION DES BOUTONS
# ============================================================================

func _set_menu_buttons_enabled(enabled: bool):
	var mouse_filter_value: int

	if enabled:
		mouse_filter_value = Control.MOUSE_FILTER_STOP
	else:
		mouse_filter_value = Control.MOUSE_FILTER_IGNORE

	# ------------------------------------------------------------------------
	# Boutons principaux
	# ------------------------------------------------------------------------

	var menu_controls = [
		$Load/Load,
		$Save/Save,
		$Continue/Continue,
		$Restart/Options,
		$Restart/Restart,
		$Restart/Quitter
	]

	for control in menu_controls:
		if control is Control:
			control.mouse_filter = mouse_filter_value

	# ------------------------------------------------------------------------
	# Difficultés
	#
	# On désactive également les boutons contenus dans ces groupes.
	# ------------------------------------------------------------------------

	_set_controls_recursive(
		$DifficultyButtons,
		enabled
	)


func _set_controls_recursive(node: Node, enabled: bool):
	for child in node.get_children():

		if child is BaseButton:
			child.disabled = not enabled

		elif child is Control:
			if enabled:
				child.mouse_filter = Control.MOUSE_FILTER_STOP
			else:
				child.mouse_filter = Control.MOUSE_FILTER_IGNORE

		_set_controls_recursive(child, enabled)


# ============================================================================
#                         ENVIRONNEMENT DU MENU
# ============================================================================

func _apply_environment_difficulty():
	environment_sprite.visible = true

	# Reset FX
	smoke_ceiling.visible = false
	fire_fx.visible = false


	# ------------------------------------------------------------------------
	# KING
	# Survivor terminé = King débloqué
	# ------------------------------------------------------------------------

	if gs.survivor_unlocked or gs.king_unlocked:
		environment_sprite.play("environment_king")

		smoke_ceiling.visible = true
		fire_fx.visible = true


	# ------------------------------------------------------------------------
	# SURVIVOR
	# Explorer terminé = Survivor débloqué
	# ------------------------------------------------------------------------

	elif gs.explorer_unlocked:
		environment_sprite.play("environment_survivor")

		smoke_ceiling.visible = true
		fire_fx.visible = false


	# ------------------------------------------------------------------------
	# EXPLORER
	# ------------------------------------------------------------------------

	else:
		environment_sprite.play("environment_explorer")


# ============================================================================
#                         AFFICHAGE DIFFICULTÉS
# ============================================================================

func refresh_difficulty_buttons():

	# ------------------------------------------------------------------------
	# EXPLORER
	# ------------------------------------------------------------------------

	$DifficultyButtons/Unlocked/Explorer.visible = gs.explorer_unlocked
	$DifficultyButtons/Locked/Explorer.visible = not gs.explorer_unlocked


	# ------------------------------------------------------------------------
	# SURVIVOR
	# ------------------------------------------------------------------------

	$DifficultyButtons/Unlocked/Survivor.visible = gs.survivor_unlocked
	$DifficultyButtons/Locked/Survivor.visible = not gs.survivor_unlocked


	# ------------------------------------------------------------------------
	# KING
	# ------------------------------------------------------------------------

	$DifficultyButtons/Unlocked/King.visible = gs.king_unlocked
	$DifficultyButtons/Locked/King.visible = not gs.king_unlocked


# ============================================================================
#                              OPTIONS
# ============================================================================

func _on_options_pressed():
	await gs.load_level(
		"res://Interface/Configuration/configuration.tscn"
	)


# ============================================================================
#                           NOUVELLE PARTIE
# ============================================================================

func _on_restart_pressed():
	await gs.restart_game()


# ============================================================================
#                               CHARGER
# ============================================================================

func _on_load_pressed():
	await gs.load_save()


# ============================================================================
#                              SAUVEGARDER
# ============================================================================

func _on_save_pressed():
	gs.save_game()


# ============================================================================
#                               CONTINUER
# ============================================================================

func _on_continue_pressed():
	await gs.continue_game()


# ============================================================================
#                                QUITTER
# ============================================================================

func _on_quitter_pressed():
	get_tree().quit()
