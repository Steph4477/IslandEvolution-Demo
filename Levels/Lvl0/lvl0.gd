extends Node2D

@onready var toucan_dialogue = $ToucanDialogue

var gs
var player = null


func _ready():
	$sound/dijee.play()

	gs = get_node("/root/GameState")

	# Recharge la progression sauvegardée
	gs.load_global_progress()

	# Met à jour l'affichage des difficultés
	refresh_difficulty_buttons()


# ============================================================================
#                         AFFICHAGE DIFFICULTÉS
# ============================================================================

func refresh_difficulty_buttons():
	# ------------------------------------------------------------------------
	# EXPLORATEUR
	# ------------------------------------------------------------------------
	$DifficultyButtons/Unlocked/Explorer.visible = gs.explorer_unlocked
	$DifficultyButtons/Locked/Explorer.visible = not gs.explorer_unlocked

	# ------------------------------------------------------------------------
	# SURVIVANT
	# ------------------------------------------------------------------------
	$DifficultyButtons/Unlocked/Survivor.visible = gs.survivor_unlocked
	$DifficultyButtons/Locked/Survivor.visible = not gs.survivor_unlocked

	# ------------------------------------------------------------------------
	# ROI DE L'ÎLE
	# ------------------------------------------------------------------------
	$DifficultyButtons/Unlocked/King.visible = gs.king_unlocked
	$DifficultyButtons/Locked/King.visible = not gs.king_unlocked

	# DEBUG
	print("======================================")
	print("MENU - ETAT DES DIFFICULTES")
	print("EXPLORER : ", gs.explorer_unlocked)
	print("SURVIVOR : ", gs.survivor_unlocked)
	print("KING : ", gs.king_unlocked)
	print("======================================")


# ============================================================================
#                              OPTIONS
# ============================================================================

func _on_options_pressed():
	await gs.load_level("res://Interface/Configuration/configuration.tscn")


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
