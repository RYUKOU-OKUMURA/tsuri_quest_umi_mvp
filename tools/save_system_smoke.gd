extends Node

## セーブシステムの回帰テスト。
## 実際に user:// へ読み書きするため、必ず tools/save_system_verify.sh 経由
## （HOME 隔離 + TSURI_SAVE_SMOKE_ALLOW=1）で実行すること。

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
	_remove_if_exists(PlayerProgress.SAVE_PATH)
	_remove_if_exists(PlayerProgress.SAVE_BACKUP_PATH)
	_remove_if_exists(PlayerProgress.SAVE_TMP_PATH)
	_expect(not PlayerProgress.has_save_file(), "clean slate should report no save file")

	# 初回保存
	PlayerProgress.reset_game()
	_expect(FileAccess.file_exists(PlayerProgress.SAVE_PATH), "reset_game should write save file")
	var saved := _read_json(PlayerProgress.SAVE_PATH)
	_expect_eq(int(saved.get("version", -1)), PlayerProgress.SAVE_VERSION, "saved version")
	_expect_eq(int(saved.get("money", -1)), 500, "saved initial money")

	# 2回目の保存でバックアップ世代が残る
	PlayerProgress.money = 1234
	PlayerProgress.save_game()
	_expect(
		FileAccess.file_exists(PlayerProgress.SAVE_BACKUP_PATH),
		"second save should keep .bak generation"
	)
	_expect_eq(int(_read_json(PlayerProgress.SAVE_PATH).get("money", -1)), 1234, "main save money")
	_expect_eq(
		int(_read_json(PlayerProgress.SAVE_BACKUP_PATH).get("money", -1)),
		500,
		"backup should hold previous generation"
	)
	_expect(
		not FileAccess.file_exists(PlayerProgress.SAVE_TMP_PATH),
		"tmp file should not remain after save"
	)

	# 本体破損 → バックアップから復元
	_write_text(PlayerProgress.SAVE_PATH, "{{{ corrupted json")
	PlayerProgress.money = 0
	PlayerProgress.load_game()
	_expect_eq(PlayerProgress.money, 500, "corrupt main should fall back to backup")

	# 本体・バックアップとも読めない → メモリ上の値を維持（初期値運用）
	_write_text(PlayerProgress.SAVE_PATH, "{{{ corrupted json")
	_remove_if_exists(PlayerProgress.SAVE_BACKUP_PATH)
	PlayerProgress.money = 777
	PlayerProgress.load_game()
	_expect_eq(PlayerProgress.money, 777, "both corrupt should keep in-memory values")

	# 未知の将来バージョンも読み込みは試みる（前方互換）
	_write_text(
		PlayerProgress.SAVE_PATH,
		JSON.stringify({"version": 99, "money": 4242, "level": 3})
	)
	PlayerProgress.load_game()
	_expect_eq(PlayerProgress.money, 4242, "future version should still load")
	_expect_eq(PlayerProgress.level, 3, "future version should still load level")

	# V2 E0: 旧上限だったLv10セーブは維持され、Lv11以降へ進行できる
	_write_text(
		PlayerProgress.SAVE_PATH,
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
		int(_read_json(PlayerProgress.SAVE_PATH).get("money", -1)),
		4242,
		"sandbox save_game must not touch disk"
	)
	PlayerProgress.load_game()
	_expect_eq(PlayerProgress.money, 9999, "sandbox load_game must not touch memory")

	if _failed:
		return
	print("save_system_smoke: ok")
	get_tree().quit(0)


func _remove_if_exists(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


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
