extends Node

## セーブシステムの回帰テスト。
## 実際に user:// へ読み書きするため、必ず tools/save_system_verify.sh 経由
## （HOME 隔離 + TSURI_SAVE_SMOKE_ALLOW=1）で実行すること。

const MainScript = preload("res://src/main.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")
const TitleScreen = preload("res://src/ui/title_screen.gd")
const PlayerProgressScript = preload("res://src/autoload/player_progress.gd")

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
	_expect(typeof(saved.get("shark_bonds", {})) == TYPE_DICTIONARY, "saved data should include shark_bonds")
	_expect_eq(
		String(saved.get("selected_time_slot_id", "")),
		GameData.DEFAULT_TIME_SLOT_ID,
		"saved data should include default selected_time_slot_id"
	)

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

	# version欠損の疎な旧saveは従来どおり読み込める。
	_verify_versionless_sparse_save_is_allowed()
	_verify_unknown_version_type_guards()
	await _verify_title_future_slot_guard_ui()

	# 将来版を含むslotは、main / backup / tmpを一切変えずに利用を止める。
	_remove_all_save_files()
	var future_main := {
		"version": PlayerProgress.SAVE_VERSION + 0.5,
		"level": {},
		"money": [],
		"play_seconds": null,
		"future_main_payload": {"preserve": "main"},
	}
	var future_backup := {
		"version": PlayerProgress.SAVE_VERSION + 2,
		"level": 4,
		"money": 4343,
		"future_backup_payload": ["preserve", "backup"],
	}
	var future_tmp := {
		"version": PlayerProgress.SAVE_VERSION + 3,
		"future_tmp_payload": "preserve tmp",
	}
	_write_text(_slot_save_path(1), JSON.stringify(future_main, "\t"))
	_write_text(_slot_backup_path(1), JSON.stringify(future_backup, "\t"))
	_write_text(_slot_tmp_path(1), JSON.stringify(future_tmp, "\t"))
	var future_hashes := {
		"main": _file_hash(_slot_save_path(1)),
		"backup": _file_hash(_slot_backup_path(1)),
		"tmp": _file_hash(_slot_tmp_path(1)),
	}
	_expect(PlayerProgress.is_future_save_version_guarded(1), "future slot should be guarded")
	_expect_eq(
		float(PlayerProgress.future_save_guard_status(1).get("version", 0.0)),
		float(PlayerProgress.SAVE_VERSION) + 0.5,
		"future guard should report the main version"
	)
	_expect(not PlayerProgress.set_active_save_slot(1), "future slot should refuse activation")
	_expect_eq(PlayerProgress.money, 500, "future slot should not load its money")
	PlayerProgress.save_game()
	PlayerProgress.reset_game()
	_expect_future_slot_hashes(future_hashes, "guarded save/reset should preserve every source file")

	# 他slotは通常利用でき、対象slotへ戻るとguardを再評価する。
	_expect(not PlayerProgress.is_future_save_version_guarded(2), "other slot should not inherit guard")
	_expect(PlayerProgress.set_active_save_slot(2, false), "other slot should activate normally")
	PlayerProgress.reset_game()
	PlayerProgress.money = 2468
	PlayerProgress.save_game()
	_expect_eq(PlayerProgress.money, 2468, "other slot should remain saveable")
	_expect_future_slot_hashes(future_hashes, "other slot saves must not change guarded slot files")
	await _verify_title_future_slot_guard_ui()
	_expect(not PlayerProgress.set_active_save_slot(1), "switching back should re-evaluate the future guard")
	_expect_future_slot_hashes(future_hashes, "re-evaluating the guard must not change guarded slot files")
	_remove_all_save_files()
	_verify_future_guard_blocks_legacy_migration_on_startup()
	_remove_all_save_files()
	_expect(PlayerProgress.set_active_save_slot(1, false), "cleanup should restore slot 1 for later tests")

	# E10: shark_bonds は欠損時に補完され、JSON由来のfloat値はintへ正規化される
	_write_text(
		PlayerProgress.current_save_path(),
		JSON.stringify(
			{
				"version": PlayerProgress.SAVE_VERSION,
				"level": 30,
				"shark_bonds": {
					"nekozame": 8.0,
					"inuzame": 120.0,
					"nushi_danger_reef": 100.0,
				},
			}
		)
	)
	PlayerProgress.load_game()
	_expect_eq(int(PlayerProgress.shark_bonds.get("nekozame", 0)), 8, "shark bond should load as int")
	_expect_eq(int(PlayerProgress.shark_bonds.get("inuzame", 0)), 100, "shark bond should clamp on load")
	_expect(
		not PlayerProgress.shark_bonds.has("nushi_danger_reef"),
		"non-raiseable shark bond should be dropped on load"
	)

	# E5: selected_time_slot_id は欠損時に日中へ補完され、未解放値はロード時に戻される
	_write_text(
		PlayerProgress.current_save_path(),
		JSON.stringify({"version": PlayerProgress.SAVE_VERSION, "level": 20})
	)
	PlayerProgress.load_game()
	_expect_eq(
		PlayerProgress.selected_time_slot_id,
		GameData.DEFAULT_TIME_SLOT_ID,
		"missing selected_time_slot_id should default to daytime"
	)
	_expect(PlayerProgress.select_time_slot("night"), "Lv20 should be able to select night")
	_expect_eq(
		String(_read_json(PlayerProgress.current_save_path()).get("selected_time_slot_id", "")),
		"night",
		"selected night should be saved"
	)
	var night_stats := PlayerProgress.begin_fishing_trip()
	_expect_eq(String(night_stats.get("time_slot_id", "")), "night", "trip stats should include night")
	_expect_eq(String(night_stats.get("time_slot_label", "")), "夜釣り", "trip stats should include night label")
	_expect_eq(String(night_stats.get("surface_bgm_key", "")), "calm", "night should override surface BGM")

	_write_text(
		PlayerProgress.current_save_path(),
		JSON.stringify(
			{
				"version": PlayerProgress.SAVE_VERSION,
				"level": 1,
				"selected_time_slot_id": "night",
			}
		)
	)
	PlayerProgress.load_game()
	_expect_eq(
		PlayerProgress.selected_time_slot_id,
		GameData.DEFAULT_TIME_SLOT_ID,
		"locked selected_time_slot_id should fall back to daytime"
	)

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

	PlayerProgress._sandbox_mode = false
	# SAVE-02: 各I/O段階の失敗をfalse・signal・原本維持として呼出側へ返す。
	await _verify_save_failure_propagation()
	await _verify_title_stays_on_initial_save_failure()
	await _verify_common_save_failure_ui()

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


func _verify_save_failure_propagation() -> void:
	_remove_all_save_files()
	PlayerProgress.set_active_save_slot(1, false)
	_expect(PlayerProgress.reset_game(), "reset_game should return initial save success")
	PlayerProgress.money = 1357
	_expect(PlayerProgress.save_game(), "baseline save should succeed")
	var baseline_main_hash := _file_hash(PlayerProgress.current_save_path())
	var baseline_backup_hash := _file_hash(PlayerProgress.current_backup_path())
	var failure_messages: Array[String] = []
	var collect_failure := func(message: String) -> void: failure_messages.append(message)
	PlayerProgress.save_failed.connect(collect_failure)
	for stage in ["tmp_open", "write_unavailable", "backup_rename", "final_rename"]:
		PlayerProgress._save_failure_injection_stage = stage
		PlayerProgress.money += 1
		var message_count_before := failure_messages.size()
		_expect(not PlayerProgress.save_game(), "%s failure should return false" % stage)
		_expect_eq(
			failure_messages.size(),
			message_count_before + 1,
			"%s failure should emit save_failed once" % stage
		)
		_expect(not failure_messages[-1].is_empty(), "%s failure should include a message" % stage)
		_expect_eq(
			_file_hash(PlayerProgress.current_save_path()),
			baseline_main_hash,
			"%s failure should preserve main" % stage
		)
		var expected_backup_hash := baseline_main_hash if stage == "final_rename" else baseline_backup_hash
		_expect_eq(
			_file_hash(PlayerProgress.current_backup_path()),
			expected_backup_hash,
			"%s failure should preserve a valid backup generation" % stage
		)
		if stage == "final_rename":
			baseline_backup_hash = expected_backup_hash
		_expect(
			not FileAccess.file_exists(PlayerProgress.current_tmp_path()),
			"%s failure should clean tmp" % stage
		)
	PlayerProgress._save_failure_injection_stage = "tmp_open"
	_expect(not PlayerProgress.reset_game(), "reset_game should return initial save failure")
	PlayerProgress._save_failure_injection_stage = ""
	PlayerProgress.save_failed.disconnect(collect_failure)
	_expect(PlayerProgress.save_game(), "save should recover after failure injection is cleared")


func _verify_common_save_failure_ui() -> void:
	var main := MainScript.new()
	add_child(main)
	await get_tree().create_timer(0.4).timeout
	main._on_save_failed("保存失敗テスト")
	_expect(
		main._current_screen._common_notification != null,
		"save_failed should reach the current screen common notification"
	)
	_expect_eq(
		main._current_screen._common_notification.text,
		"保存失敗テスト",
		"common notification should show the failure reason"
	)
	main._show_save_exit_dialog()
	_expect(main._save_exit_dialog != null, "close failure should show a retry dialog")
	_expect_eq(main._save_exit_dialog.ok_button_text, "再試行", "close dialog should offer retry")
	var has_quit_without_save := false
	for child in main._save_exit_dialog.find_children("*", "Button", true, false):
		if String(child.text) == "保存せず終了":
			has_quit_without_save = true
	_expect(has_quit_without_save, "close dialog should offer quit without saving")
	main.queue_free()
	await get_tree().process_frame


func _verify_title_stays_on_initial_save_failure() -> void:
	_remove_all_save_files()
	PlayerProgress.set_active_save_slot(1, false)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.disable_3d = true
	add_child(viewport)
	var title: TitleScreen = TitleScreen.new()
	title.theme = ThemeFactory.build_theme()
	viewport.add_child(title)
	await get_tree().process_frame
	await get_tree().process_frame
	var navigations: Array[String] = []
	title.navigate_requested.connect(
		func(screen_id: String, _payload: Dictionary) -> void: navigations.append(screen_id)
	)
	PlayerProgress._save_failure_injection_stage = "tmp_open"
	title._start_new_game()
	PlayerProgress._save_failure_injection_stage = ""
	_expect(navigations.is_empty(), "initial save failure should keep the player on title")
	_expect(not FileAccess.file_exists(_slot_save_path(1)), "initial save failure should not create a slot save")
	viewport.queue_free()
	await get_tree().process_frame


func _verify_title_future_slot_guard_ui() -> void:
	var guarded_hashes := {
		"main": _file_hash(_slot_save_path(1)),
		"backup": _file_hash(_slot_backup_path(1)),
		"tmp": _file_hash(_slot_tmp_path(1)),
	}
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var title: TitleScreen = TitleScreen.new()
	title.theme = ThemeFactory.build_theme()
	viewport.add_child(title)
	await get_tree().process_frame
	await get_tree().process_frame
	_expect_eq(title._slot_buttons.size(), PlayerProgress.SAVE_SLOT_COUNT, "title should update all save slots")
	_expect(title._slot_buttons[1].text.contains("Lv."), "title should render the safe occupied slot")
	_expect(title._slot_buttons[2].text.contains("空き"), "title should render the empty slot")
	title._select_slot(1)
	_expect(title._continue_button.disabled, "future slot should disable continue in title UI")
	_expect(title._new_button.disabled, "future slot should disable new game in title UI")
	_expect(title._slot_buttons[0].text.contains("対応版"), "future slot should render a guarded slot label")
	_expect(
		title._slot_status_label.text.contains("新しい版")
		and title._slot_status_label.text.contains("対応版"),
		"future slot should show a compatible-version notice"
	)
	title._select_slot(2)
	_expect(not title._continue_button.disabled, "safe slot should enable continue in title UI")
	_expect(not title._new_button.disabled, "safe slot should re-enable new game in title UI")
	title._continue_selected_slot()
	_expect_eq(PlayerProgress.active_save_slot, 2, "safe slot should remain usable from title UI")
	_expect_future_slot_hashes(guarded_hashes, "title refresh should preserve guarded files")
	viewport.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


func _verify_versionless_sparse_save_is_allowed() -> void:
	_remove_all_save_files()
	_write_text(
		_slot_save_path(1),
		JSON.stringify({"level": 7, "money": 321, "sparse_payload": "keep compatible"})
	)
	_expect(
		not PlayerProgress.is_future_save_version_guarded(1),
		"versionless sparse save should remain compatible"
	)
	_expect(PlayerProgress.set_active_save_slot(1), "versionless sparse save should load")
	_expect_eq(PlayerProgress.level, 7, "versionless sparse save should preserve level")
	_expect_eq(PlayerProgress.money, 321, "versionless sparse save should preserve money")
	_remove_all_save_files()


func _verify_unknown_version_type_guards() -> void:
	var invalid_cases: Array[Dictionary] = [
		{"label": "String", "version": "future-v2"},
		{"label": "null", "version": null},
		{"label": "Array", "version": [PlayerProgress.SAVE_VERSION + 1]},
		{"label": "Dictionary", "version": {"major": PlayerProgress.SAVE_VERSION + 1}},
		{"label": "bool", "version": true},
	]
	for invalid_case in invalid_cases:
		var label := String(invalid_case["label"])
		var invalid_version = invalid_case["version"]
		_remove_all_save_files()
		_write_text(
			_slot_save_path(1),
			JSON.stringify(
				{
					"version": invalid_version,
					"level": {},
					"money": [],
					"play_seconds": null,
					"unknown_version_payload": label,
				}
			)
		)
		# 不正mainに加えて数値future backupを置いても、slot全体を安全側で停止する。
		_write_text(
			_slot_backup_path(1),
			JSON.stringify({"version": PlayerProgress.SAVE_VERSION + 2, "future_backup_payload": label})
		)
		_write_text(
			_slot_tmp_path(1),
			JSON.stringify({"version": PlayerProgress.SAVE_VERSION + 3, "future_tmp_payload": label})
		)
		var guarded_hashes := {
			"main": _file_hash(_slot_save_path(1)),
			"backup": _file_hash(_slot_backup_path(1)),
			"tmp": _file_hash(_slot_tmp_path(1)),
		}
		var guard_status := PlayerProgress.future_save_guard_status(1)
		_expect(bool(guard_status.get("guarded", false)), "%s version should guard the slot" % label)
		_expect_eq(
			String(guard_status.get("reason", "")),
			"unknown_version_type",
			"%s version should report unknown type" % label
		)
		_expect_eq(
			int(guard_status.get("version_type", -1)),
			typeof(invalid_version),
			"%s version should preserve its type in guard status" % label
		)
		var summary := PlayerProgress.save_slot_summary(1)
		_expect(bool(summary.get("future_guarded", false)), "%s version should not break slot summary" % label)
		_expect_eq(int(summary.get("level", -1)), 1, "%s summary should use safe level" % label)
		_expect_eq(int(summary.get("money", -1)), 0, "%s summary should use safe money" % label)
		_expect_eq(float(summary.get("play_seconds", -1.0)), 0.0, "%s summary should use safe play time" % label)
		_expect_eq(
			typeof(summary.get("future_version", null)),
			typeof(invalid_version),
			"%s version should not be coerced in slot summary" % label
		)
		_expect(not PlayerProgress.set_active_save_slot(1), "%s version should refuse activation" % label)
		PlayerProgress.save_game()
		PlayerProgress.reset_game()
		_expect_future_slot_hashes(guarded_hashes, "%s version should preserve guarded files" % label)
		_expect(not PlayerProgress.is_future_save_version_guarded(2), "%s guard should not affect slot 2" % label)
		_expect(PlayerProgress.set_active_save_slot(2, false), "%s case should activate slot 2" % label)
		PlayerProgress.reset_game()
		PlayerProgress.money = 2000 + invalid_cases.find(invalid_case)
		PlayerProgress.save_game()
		_expect_future_slot_hashes(guarded_hashes, "%s case should keep slot 1 unchanged after slot 2 save" % label)
		_expect(not PlayerProgress.set_active_save_slot(1), "%s guard should re-evaluate on slot switch" % label)
		_expect_future_slot_hashes(guarded_hashes, "%s case should keep slot 1 unchanged after re-evaluation" % label)


func _verify_future_guard_blocks_legacy_migration_on_startup() -> void:
	# 起動時にbackup / tmpだけで将来版を検出しても、legacyをslotへ移動させない。
	_write_text(
		PlayerProgress.LEGACY_SAVE_PATH,
		JSON.stringify({"version": PlayerProgress.SAVE_VERSION, "money": 999, "legacy_payload": "keep"})
	)
	_write_text(
		_slot_backup_path(1),
		JSON.stringify({"version": PlayerProgress.SAVE_VERSION + 1, "future_backup_payload": "keep"})
	)
	_write_text(
		_slot_tmp_path(1),
		JSON.stringify({"version": PlayerProgress.SAVE_VERSION + 2, "future_tmp_payload": "keep"})
	)
	var legacy_hash := _file_hash(PlayerProgress.LEGACY_SAVE_PATH)
	var backup_hash := _file_hash(_slot_backup_path(1))
	var tmp_hash := _file_hash(_slot_tmp_path(1))
	var startup_progress := PlayerProgressScript.new()
	startup_progress._sandbox_mode = false
	startup_progress._initialize_save_storage()
	_expect(
		startup_progress.is_future_save_version_guarded(1),
		"startup should guard a slot when only backup/tmp is future version"
	)
	_expect(not FileAccess.file_exists(_slot_save_path(1)), "startup guard should not create a main save")
	_expect_eq(_file_hash(PlayerProgress.LEGACY_SAVE_PATH), legacy_hash, "startup guard should preserve legacy main")
	_expect_eq(_file_hash(_slot_backup_path(1)), backup_hash, "startup guard should preserve future backup")
	_expect_eq(_file_hash(_slot_tmp_path(1)), tmp_hash, "startup guard should preserve future tmp")
	startup_progress.free()


func _expect_future_slot_hashes(expected_hashes: Dictionary, message: String) -> void:
	_expect_eq(_file_hash(_slot_save_path(1)), String(expected_hashes.get("main", "")), "%s (main)" % message)
	_expect_eq(_file_hash(_slot_backup_path(1)), String(expected_hashes.get("backup", "")), "%s (backup)" % message)
	_expect_eq(_file_hash(_slot_tmp_path(1)), String(expected_hashes.get("tmp", "")), "%s (tmp)" % message)


func _file_hash(path: String) -> String:
	return FileAccess.get_sha256(path)


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
