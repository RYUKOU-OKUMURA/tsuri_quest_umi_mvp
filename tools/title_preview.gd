extends Control
## タイトル画面の代表/高リスク状態を1280x720で実描画する。

const TitleScreen = preload("res://src/ui/title_screen.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")

const NORMAL_OUT := "/tmp/tsuri_title_normal.png"
const STORAGE_BLOCKED_OUT := "/tmp/tsuri_title_storage_blocked.png"
const INVALID_ARTIFACT_OUT := "/tmp/tsuri_title_invalid_artifact.png"
const EMPTY_OUT := "/tmp/tsuri_title_empty.png"
const OCCUPIED_OUT := "/tmp/tsuri_title_occupied.png"
const THREE_SLOT_OUT := "/tmp/tsuri_title_3slot.png"
const DIFFICULTY_OUT := "/tmp/tsuri_title_difficulty.png"
const OVERWRITE_OUT := "/tmp/tsuri_title_overwrite.png"


func _ready() -> void:
	theme = ThemeFactory.build_theme()
	var mode := OS.get_environment("TSURI_TITLE_PREVIEW_MODE")
	if mode in ["empty", "occupied", "3slot", "difficulty", "overwrite"]:
		if not _prepare_e7_fixture(mode):
			return
	if mode == "storage_blocked":
		PlayerProgress._save_storage_ready = false
		PlayerProgress._save_storage_block_message = (
			"旧版セーブの移行を完了できなかったため、セーブの読み書きを停止しました。"
			+ "ゲームを再起動してください。"
		)
	elif mode == "invalid_artifact":
		PlayerProgress._save_storage_ready = true
		PlayerProgress._save_storage_block_message = ""
		PlayerProgress.active_save_slot = PlayerProgress.DEFAULT_SAVE_SLOT
		var user_data_path := ProjectSettings.globalize_path("user://").simplify_path()
		if not is_mutation_root_allowed(
			user_data_path, OS.get_environment("TSURI_TITLE_PREVIEW_ALLOW_MUTATION")
		) or _mutation_root_is_symlink(user_data_path):
			_fail_preview("不正artifact previewのmutation guardを通過できませんでした。")
			return
		var mkdir_error := DirAccess.make_dir_recursive_absolute(PlayerProgress.SAVE_SLOT_ROOT + "/1")
		if mkdir_error != OK and mkdir_error != ERR_ALREADY_EXISTS:
			_fail_preview("不正artifact fixture用directoryを作成できませんでした（code %d）。" % mkdir_error)
			return
		_remove_all_slot_artifacts()
		if not _write_preview_save(PlayerProgress.current_save_path(), {"version": 1, "level": {}}):
			_fail_preview("不正artifact main fixtureを書き込めませんでした。")
			return
		if not _write_preview_save(PlayerProgress.current_backup_path(), {"version": 1, "inventory": []}):
			_fail_preview("不正artifact backup fixtureを書き込めませんでした。")
			return
		var invalid_summary := PlayerProgress.save_slot_summary(1)
		if (
			not bool(invalid_summary.get("invalid_artifact", false))
			or bool(invalid_summary.get("candidate_valid", true))
			or bool(invalid_summary.get("future_guarded", true))
		):
			_fail_preview("不正artifact preview fixtureが期待したsummaryになりませんでした。")
			return
	else:
		PlayerProgress._save_storage_ready = true
		PlayerProgress._save_storage_block_message = ""
		PlayerProgress.active_save_slot = PlayerProgress.DEFAULT_SAVE_SLOT

	var screen := TitleScreen.new()
	screen.configure({})
	add_child(screen)
	for _frame in range(4):
		await get_tree().process_frame
	if mode == "difficulty":
		screen._show_difficulty_modal()
	elif mode == "overwrite":
		screen._show_difficulty_modal()
		screen._on_difficulty_selected("hard")
	for _frame in range(2):
		await get_tree().process_frame
	if mode == "invalid_artifact":
		if (
			not screen._slot_buttons[0].text.contains("破損")
			or not screen._continue_button.disabled
			or not screen._new_button.disabled
		):
			_fail_preview("不正artifactのslot文言またはdisabled導線が成立していません。")
			return
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw

	var image := get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		push_error("タイトル画面の実スクショを取得できませんでした。")
		get_tree().quit(1)
		return
	if not _is_rendered_image_valid(image):
		_fail_preview("タイトル画面が空描画または黒矩形を含む不正captureになりました。")
		return
	var out := OS.get_environment("TSURI_TITLE_PREVIEW_OUT").strip_edges()
	if out.is_empty():
		var e7_outputs := {
			"empty": EMPTY_OUT,
			"occupied": OCCUPIED_OUT,
			"3slot": THREE_SLOT_OUT,
			"difficulty": DIFFICULTY_OUT,
			"overwrite": OVERWRITE_OUT,
		}
		out = String(e7_outputs.get(mode, (
			STORAGE_BLOCKED_OUT
			if mode == "storage_blocked"
			else INVALID_ARTIFACT_OUT
			if mode == "invalid_artifact"
			else NORMAL_OUT
		)))
	var save_error := image.save_png(out)
	if save_error != OK:
		push_error("タイトル画面の実スクショを保存できませんでした（code %d）。" % save_error)
		get_tree().quit(1)
		return
	print("title_preview: wrote %s" % out)
	get_tree().quit(0)


func _prepare_e7_fixture(mode: String) -> bool:
	PlayerProgress._save_storage_ready = true
	PlayerProgress._save_storage_block_message = ""
	PlayerProgress.active_save_slot = PlayerProgress.DEFAULT_SAVE_SLOT
	var user_data_path := ProjectSettings.globalize_path("user://").simplify_path()
	if not is_mutation_root_allowed(
		user_data_path, OS.get_environment("TSURI_TITLE_PREVIEW_ALLOW_MUTATION")
	) or _mutation_root_is_symlink(user_data_path):
		_fail_preview("E7 title previewのmutation guardを通過できませんでした。")
		return false
	for slot_id in range(1, PlayerProgress.SAVE_SLOT_COUNT + 1):
		var mkdir_error := DirAccess.make_dir_recursive_absolute(PlayerProgress.SAVE_SLOT_ROOT + "/%d" % slot_id)
		if mkdir_error != OK and mkdir_error != ERR_ALREADY_EXISTS:
			_fail_preview("E7 fixture用directoryを作成できませんでした。")
			return false
	_remove_all_slot_artifacts()
	if mode in ["occupied", "overwrite"]:
		return _write_preview_save(PlayerProgress.current_save_path(), _occupied_save(12, 45240.0, "normal"))
	if mode == "3slot":
		return (
			_write_preview_save(PlayerProgress.current_save_path(), _occupied_save(12, 45240.0, "normal"))
			and _write_preview_save(PlayerProgress.SAVE_SLOT_ROOT + "/2/" + PlayerProgress.SAVE_FILE_NAME, _occupied_save(5, 7380.0, "easy"))
			and _write_preview_save(PlayerProgress.SAVE_SLOT_ROOT + "/3/" + PlayerProgress.SAVE_FILE_NAME, _occupied_save(28, 359940.0, "hard"))
		)
	return true


func _occupied_save(level: int, play_seconds: float, difficulty_id: String) -> Dictionary:
	return {
		"version": PlayerProgress.SAVE_VERSION,
		"level": level,
		"money": 12450,
		"play_seconds": play_seconds,
		"difficulty_id": difficulty_id,
	}


func _write_preview_save(path: String, data: Dictionary) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "\t"))
	var write_error := file.get_error()
	file.close()
	return write_error == OK


func _remove_preview_save(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func _remove_all_slot_artifacts() -> void:
	for slot_id in range(1, PlayerProgress.SAVE_SLOT_COUNT + 1):
		for path in PlayerProgress._slot_save_paths(slot_id):
			_remove_preview_save(path)


static func is_mutation_root_allowed(user_data_path: String, allow_value: String) -> bool:
	if allow_value != "1":
		return false
	var normalized := user_data_path.simplify_path()
	var relative := ""
	if normalized.begins_with("/private/tmp/"):
		relative = normalized.trim_prefix("/private/tmp/")
	elif normalized.begins_with("/tmp/"):
		relative = normalized.trim_prefix("/tmp/")
	else:
		return false
	var root_component := relative.get_slice("/", 0)
	if (
		not root_component.begins_with("tsuri_title_")
		or root_component.length() <= 12
		or root_component.contains("..")
	):
		return false
	for character in root_component:
		var code := String(character).unicode_at(0)
		var allowed := (
			(code >= 48 and code <= 57)
			or (code >= 65 and code <= 90)
			or (code >= 97 and code <= 122)
			or character == "_"
			or character == "-"
		)
		if not allowed:
			return false
	return true


func _mutation_root_is_symlink(user_data_path: String) -> bool:
	var normalized := user_data_path.simplify_path()
	var parent := "/private/tmp" if normalized.begins_with("/private/tmp/") else "/tmp"
	var relative := normalized.trim_prefix(parent + "/")
	var current := parent
	for component in relative.split("/", false):
		var parent_dir := DirAccess.open(current)
		if parent_dir == null or parent_dir.is_link(component):
			return true
		current = current.path_join(component)
	return false


func _is_rendered_image_valid(image: Image) -> bool:
	if image.get_width() != 1280 or image.get_height() != 720:
		return false
	var sampled := 0
	var near_black := 0
	var transparent := 0
	for y in range(0, image.get_height(), 4):
		for x in range(0, image.get_width(), 4):
			var pixel := image.get_pixel(x, y)
			sampled += 1
			if pixel.a < 0.9:
				transparent += 1
			if maxf(pixel.r, maxf(pixel.g, pixel.b)) <= 0.03:
				near_black += 1
	return transparent == 0 and near_black <= int(sampled * 0.01)


func _fail_preview(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
