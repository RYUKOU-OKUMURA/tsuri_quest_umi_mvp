extends Control
## 依頼ボード画面の1280x720表示確認用キャプチャ。

const QuestBoardScreen = preload("res://src/ui/quest_board_screen.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")

const VW := Vector2i(1280, 720)
const OUT := "/tmp/tsuri_quest_board.png"
const LONG_TEXT_A_OUT := "/tmp/tsuri_quest_board_long_text_a.png"
const LONG_TEXT_B_OUT := "/tmp/tsuri_quest_board_long_text_b.png"

var _had_capture_error := false


func _ready() -> void:
	var preview_mode := OS.get_environment("QUEST_BOARD_PREVIEW_MODE")
	match preview_mode:
		"long_text_a":
			_seed_long_text_progress_a()
			await _capture_plain(LONG_TEXT_A_OUT)
		"long_text_b":
			_seed_long_text_progress_b()
			await _capture_plain(LONG_TEXT_B_OUT)
		_:
			_seed_progress()
			await _capture_plain(OUT)
	print("quest_board_preview:")
	print(_output_path_for_mode(preview_mode))
	get_tree().quit(1 if _had_capture_error else 0)


func _output_path_for_mode(preview_mode: String) -> String:
	match preview_mode:
		"long_text_a":
			return LONG_TEXT_A_OUT
		"long_text_b":
			return LONG_TEXT_B_OUT
		_:
			return OUT


func _seed_progress() -> void:
	PlayerProgress.reset_game()
	PlayerProgress.level = 9
	PlayerProgress.exp = 72
	PlayerProgress.money = 12450
	PlayerProgress.owned_rods = ["starter", "iso", "offshore"]
	PlayerProgress.equipped_rod_id = "offshore"
	PlayerProgress.owned_boats = ["skiff", "offshore_boat"]
	PlayerProgress.owned_rigs = [GameData.DEFAULT_RIG_ID]
	PlayerProgress.equipped_rig_id = GameData.DEFAULT_RIG_ID
	PlayerProgress.quest_completed_count = 9
	PlayerProgress.inventory = {
		"aji": 2,
		"kasago": 1,
	}
	PlayerProgress.caught_counts = {
		"aji": 8,
		"kasago": 2,
		"mejina": 3,
	}
	PlayerProgress.best_sizes = {
		"mejina": 47.2,
	}
	PlayerProgress.quest_board = [
		{
			"template_id": "bulk_common",
			"kind": "delivery",
			"fish_id": "aji",
			"count": 5,
			"reward_money": 960,
			"text": "アジを5匹届けてほしい",
		},
		{
			"template_id": "size_record",
			"kind": "record",
			"fish_id": "mejina",
			"target_size_cm": 45.0,
			"posted_best_cm": 32.0,
			"reward_money": 1250,
			"text": "45cm以上のメジナを釣り上げてくれ",
		},
		{
			"template_id": "cuisine",
			"kind": "delivery",
			"fish_id": "kasago",
			"recipe_id": "soup",
			"count": 1,
			"reward_money": 420,
			"text": "磯の活力丼にするカサゴを1匹",
		},
	]
	PlayerProgress._remember_current_titles()


func _seed_long_text_progress_a() -> void:
	_seed_progress()
	var fish_name := String(GameData.get_fish("takenokomebaru").get("name", "タケノコメバル"))
	var longest_recipe := _longest_recipe()
	var recipe_id := String(longest_recipe.get("id", "soup"))
	var recipe_name := String(longest_recipe.get("name", "つみれ汁"))
	PlayerProgress.inventory = {"takenokomebaru": 5}
	PlayerProgress.quest_board = [
		{
			"template_id": "bulk_common",
			"kind": "delivery",
			"fish_id": "takenokomebaru",
			"count": 5,
			"reward_money": 896,
			"text": "%sを5匹届けてほしい" % fish_name,
		},
		{
			"template_id": "bulk_uncommon",
			"kind": "delivery",
			"fish_id": "takenokomebaru",
			"count": 3,
			"reward_money": 1008,
			"text": "%sを3匹。上物を頼む" % fish_name,
		},
		{
			"template_id": "cuisine",
			"kind": "delivery",
			"fish_id": "takenokomebaru",
			"recipe_id": recipe_id,
			"count": 1,
			"reward_money": 1120,
			"text": "%sにする%sを1匹" % [recipe_name, fish_name],
		},
	]
	PlayerProgress._remember_current_titles()


func _seed_long_text_progress_b() -> void:
	_seed_progress()
	var fish_name := String(GameData.get_fish("takenokomebaru").get("name", "タケノコメバル"))
	PlayerProgress.best_sizes = {"takenokomebaru": 20.0}
	PlayerProgress.quest_board = [
		{
			"template_id": "size_record",
			"kind": "record",
			"fish_id": "takenokomebaru",
			"target_size_cm": 35.0,
			"posted_best_cm": 20.0,
			"reward_money": 1400,
			"text": "35cm以上の%sを釣り上げてくれ" % fish_name,
		},
		{
			"template_id": "rare_order",
			"kind": "delivery",
			"fish_id": "takenokomebaru",
			"count": 1,
			"reward_money": 1232,
			"text": "%sを探している。金は弾む" % fish_name,
		},
		{
			"template_id": "bulk_common",
			"kind": "delivery",
			"fish_id": "takenokomebaru",
			"count": 5,
			"reward_money": 896,
			"text": "%sを5匹届けてほしい" % fish_name,
		},
	]
	PlayerProgress._remember_current_titles()


func _longest_recipe() -> Dictionary:
	var longest_recipe := {}
	var longest_name := ""
	for recipe_id_variant in GameData.RECIPES.keys():
		var recipe := GameData.get_recipe(String(recipe_id_variant))
		var recipe_name := String(recipe.get("name", ""))
		if recipe_name.length() > longest_name.length():
			longest_recipe = recipe
			longest_name = recipe_name
	return longest_recipe


func _capture_plain(out_path: String) -> void:
	var screen: Control = await _make_screen(VW)
	await _capture_screen(screen, out_path)


func _make_screen(viewport_size: Vector2i) -> Control:
	var vp := SubViewport.new()
	vp.disable_3d = true
	vp.transparent_bg = false
	vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.size = viewport_size
	add_child(vp)
	await get_tree().process_frame
	await get_tree().process_frame

	var screen := QuestBoardScreen.new()
	screen.theme = ThemeFactory.build_theme()
	screen.configure({})
	screen.size = Vector2(viewport_size)
	vp.add_child(screen)

	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	return screen


func _capture_screen(screen: Control, out_path: String) -> void:
	await get_tree().create_timer(0.60).timeout
	RenderingServer.force_draw()
	await get_tree().process_frame
	await get_tree().process_frame
	RenderingServer.force_draw()
	await get_tree().process_frame

	var vp := screen.get_parent() as SubViewport
	if FileAccess.file_exists(out_path):
		DirAccess.remove_absolute(out_path)
	var img := vp.get_texture().get_image()
	if img == null or img.is_empty():
		_had_capture_error = true
		push_error("SubViewport get_image() returned null for %s" % out_path)
	else:
		img.save_png(out_path)
	vp.queue_free()
	await get_tree().process_frame
