extends Node

## セーブシステムの回帰テスト。
## 実際に user:// へ読み書きするため、必ず tools/save_system_verify.sh 経由
## （HOME 隔離 + TSURI_SAVE_SMOKE_ALLOW=1）で実行すること。

const MainScript = preload("res://src/main.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")
const TitleScreen = preload("res://src/ui/title_screen.gd")

var _failed := false


func _ready() -> void:
	# tools/ 配下のシーン起動なので、まずサンドボックス検出自体を確認
	_expect(PlayerProgress.is_sandbox_mode(), "tools scene launch should enable sandbox mode")

	if OS.get_environment("TSURI_SAVE_SMOKE_ALLOW") != "1":
		push_error(
			"save_system_smoke はディスクへ書き込みます。tools/save_system_verify.sh から実行してください。"
		)
		get_tree().quit(1)
		return

	# ここから先は隔離された HOME の user:// を実際に読み書きする
	PlayerProgress._sandbox_mode = false
	_remove_all_save_files()
	PlayerProgress.set_active_save_slot(1, false)
	_expect(not PlayerProgress.has_save_file(), "clean slate should report no save file")
	await _verify_title_empty_slot_selection_is_non_committal()

	# 旧単一セーブはslot 1へ自動移行される
	_write_text(
		PlayerProgress.LEGACY_SAVE_PATH,
		JSON.stringify({"version": PlayerProgress.SAVE_VERSION, "level": 4, "money": 888})
	)
	_write_text(
		PlayerProgress.LEGACY_SAVE_BACKUP_PATH,
		JSON.stringify({"version": PlayerProgress.SAVE_VERSION, "level": 3, "money": 777})
	)
	PlayerProgress._migrate_legacy_save_files()
	_expect(FileAccess.file_exists(_slot_save_path(1)), "legacy main save should migrate to slot 1")
	_expect(
		FileAccess.file_exists(_slot_backup_path(1)),
		"legacy backup save should migrate to slot 1"
	)
	_expect(not FileAccess.file_exists(PlayerProgress.LEGACY_SAVE_PATH), "legacy main should move away")
	PlayerProgress.set_active_save_slot(1)
	_expect_eq(PlayerProgress.level, 4, "migrated slot should load level")
	_expect_eq(PlayerProgress.money, 888, "migrated slot should load money")

	# slot 2はslot 1と独立して保存される
	_remove_all_save_files()
	PlayerProgress.set_active_save_slot(2, false)
	PlayerProgress.reset_game()
	_expect(FileAccess.file_exists(_slot_save_path(2)), "slot 2 reset_game should write slot 2 save")
	_expect(not FileAccess.file_exists(_slot_save_path(1)), "slot 2 save should not write slot 1")
	PlayerProgress.money = 2468
	PlayerProgress.save_game()
	PlayerProgress.set_active_save_slot(1)
	_expect(not PlayerProgress.has_save_file(), "empty slot 1 should stay empty after slot 2 save")
	PlayerProgress.set_active_save_slot(2)
	_expect_eq(PlayerProgress.money, 2468, "slot 2 should load its own money")

	_remove_all_save_files()
	PlayerProgress.set_active_save_slot(1, false)

	# 初回保存
	PlayerProgress.reset_game()
	_expect(FileAccess.file_exists(PlayerProgress.current_save_path()), "reset_game should write save file")
	var saved := _read_json(PlayerProgress.current_save_path())
	_expect_eq(int(saved.get("version", -1)), PlayerProgress.SAVE_VERSION, "saved version")
	_expect_eq(int(saved.get("money", -1)), 500, "saved initial money")

	# 2回目の保存でバックアップ世代が残る
	PlayerProgress.money = 1234
	PlayerProgress.save_game()
	_expect(
		FileAccess.file_exists(PlayerProgress.current_backup_path()),
		"second save should keep .bak generation"
	)
	_expect_eq(int(_read_json(PlayerProgress.current_save_path()).get("money", -1)), 1234, "main save money")
	_expect_eq(
		int(_read_json(PlayerProgress.current_backup_path()).get("money", -1)),
		500,
		"backup should hold previous generation"
	)
	_expect(
		not FileAccess.file_exists(PlayerProgress.current_tmp_path()),
		"tmp file should not remain after save"
	)

	# 本体破損 → バックアップから復元
	_write_text(PlayerProgress.current_save_path(), "{{{ corrupted json")
	PlayerProgress.money = 0
	PlayerProgress.load_game()
	_expect_eq(PlayerProgress.money, 500, "corrupt main should fall back to backup")

	# 本体・バックアップとも読めない → メモリ上の値を維持（初期値運用）
	_write_text(PlayerProgress.current_save_path(), "{{{ corrupted json")
	_remove_if_exists(PlayerProgress.current_backup_path())
	PlayerProgress.money = 777
	PlayerProgress.load_game()
	_expect_eq(PlayerProgress.money, 777, "both corrupt should keep in-memory values")

	# 未知の将来バージョンも読み込みは試みる（前方互換）
	_write_text(
		PlayerProgress.current_save_path(),
		JSON.stringify({"version": 99, "money": 4242, "level": 3})
	)
	PlayerProgress.load_game()
	_expect_eq(PlayerProgress.money, 4242, "future version should still load")
	_expect_eq(PlayerProgress.level, 3, "future version should still load level")

	# V2 E0: 旧上限だったLv10セーブは維持され、Lv11以降へ進行できる
	_write_text(
		PlayerProgress.current_save_path(),
		JSON.stringify(
			{"version": PlayerProgress.SAVE_VERSION, "level": 10, "exp": 459, "money": 4242}
		)
	)
	PlayerProgress.load_game()
	_expect_eq(PlayerProgress.level, 10, "Lv10 save should load as Lv10")
	_expect_eq(PlayerProgress.exp, 459, "Lv10 save should preserve EXP")
	_expect_eq(PlayerProgress.exp_to_next_level(), 460, "Lv10 should require EXP toward Lv11")
	var leveled_to := PlayerProgress.add_exp(1)
	_expect_eq(PlayerProgress.level, 11, "Lv10 save should be able to advance to Lv11")
	_expect_eq(PlayerProgress.exp, 0, "Lv11 should consume exact overflow EXP")
	_expect(
		leveled_to.size() == 1 and int(leveled_to[0]) == 11,
		"Lv10 add_exp should report Lv11"
	)

	# サンドボックス中はディスクに一切触れない
	PlayerProgress._sandbox_mode = true
	PlayerProgress.money = 9999
	PlayerProgress.save_game()
	_expect_eq(
		int(_read_json(PlayerProgress.current_save_path()).get("money", -1)),
		4242,
		"sandbox save_game must not touch disk"
	)
	PlayerProgress.load_game()
	_expect_eq(PlayerProgress.money, 9999, "sandbox load_game must not touch memory")

	if _failed:
		return
	print("save_system_smoke: ok")
	get_tree().quit(0)


func _verify_title_empty_slot_selection_is_non_committal() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var title := TitleScreen.new()
	title.theme = ThemeFactory.build_theme()
	viewport.add_child(title)
	await get_tree().process_frame
	await get_tree().process_frame
	title._select_slot(2)
	await get_tree().process_frame
	_expect_eq(PlayerProgress.active_save_slot, 1, "selecting an empty title slot should not activate it")
	_expect(not FileAccess.file_exists(_slot_save_path(2)), "selecting an empty title slot should not create a save")
	var main := MainScript.new()
	main._current_screen = title
	_expect(not main._should_save_on_close(), "closing on title should not auto-save")
	main.free()
	viewport.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


func _remove_if_exists(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func _remove_all_save_files() -> void:
	for slot_id in range(1, PlayerProgress.SAVE_SLOT_COUNT + 1):
		_remove_if_exists(_slot_save_path(slot_id))
		_remove_if_exists(_slot_backup_path(slot_id))
		_remove_if_exists(_slot_tmp_path(slot_id))
	_remove_if_exists(PlayerProgress.LEGACY_SAVE_PATH)
	_remove_if_exists(PlayerProgress.LEGACY_SAVE_BACKUP_PATH)
	_remove_if_exists(PlayerProgress.LEGACY_SAVE_TMP_PATH)


func _slot_save_path(slot_id: int) -> String:
	return "%s/%d/%s" % [PlayerProgress.SAVE_SLOT_ROOT, slot_id, PlayerProgress.SAVE_FILE_NAME]


func _slot_backup_path(slot_id: int) -> String:
	return "%s/%d/%s" % [PlayerProgress.SAVE_SLOT_ROOT, slot_id, PlayerProgress.SAVE_BACKUP_FILE_NAME]


func _slot_tmp_path(slot_id: int) -> String:
	return "%s/%d/%s" % [PlayerProgress.SAVE_SLOT_ROOT, slot_id, PlayerProgress.SAVE_TMP_FILE_NAME]


func _write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


func _expect(condition: bool, message: String) -> void:
	if condition or _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)


func _expect_eq(actual: Variant, expected: Variant, message: String) -> void:
	_expect(actual == expected, "%s got=%s expected=%s" % [message, str(actual), str(expected)])
