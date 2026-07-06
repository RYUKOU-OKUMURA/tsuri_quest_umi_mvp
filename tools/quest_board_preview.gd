extends Control
## 依頼ボード画面の1280x720表示確認用キャプチャ。

const QuestBoardScreen = preload("res://src/ui/quest_board_screen.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")

const VW := Vector2i(1280, 720)
const OUT := "/tmp/tsuri_quest_board.png"

var _had_capture_error := false


func _ready() -> void:
	_seed_progress()
	await _capture_plain(OUT)
	print("quest_board_preview:")
	print(OUT)
	get_tree().quit(1 if _had_capture_error else 0)


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
	await get_tree().create_timer(0.35).timeout
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
