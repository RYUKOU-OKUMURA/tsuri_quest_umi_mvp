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
	await _verify_e7_title_new_game_flow()
	_verify_save_slot_deletion_contract()

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
	_expect_eq(
		String(saved.get("difficulty_id", "")),
		GameData.DEFAULT_DIFFICULTY_ID,
		"saved data should include default difficulty_id"
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

	# SAVE-03: 構文正常でも意味破損したmainは、同じ検証を通ったbackupへfallbackする。
	await _verify_semantic_save_candidate_selection()
	_verify_safe_integer_and_outbound_contract()
	_verify_saturating_progress_mutations()
	_verify_fallback_lifecycle()
	_verify_difficulty_save_contract()

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


func _verify_save_slot_deletion_contract() -> void:
	_remove_all_save_files()
	var settings_path := "user://settings.json"
	_write_text(settings_path, "settings-byte-sentinel\n")
	var settings_hash := _file_hash(settings_path)

	# 3slotすべてについて、対象のmain / backup / tmpだけが消えることを確認する。
	for slot_id in range(1, PlayerProgress.SAVE_SLOT_COUNT + 1):
		_remove_all_save_files()
		var active_slot := 2 if slot_id == 1 else 1
		_expect(PlayerProgress.set_active_save_slot(active_slot, false), "deletion fixture should select a non-target active slot")
		for fixture_slot in range(1, PlayerProgress.SAVE_SLOT_COUNT + 1):
			_write_text(_slot_save_path(fixture_slot), "main-%d-%d" % [slot_id, fixture_slot])
			_write_text(_slot_backup_path(fixture_slot), "backup-%d-%d" % [slot_id, fixture_slot])
			_write_text(_slot_tmp_path(fixture_slot), "tmp-%d-%d" % [slot_id, fixture_slot])
		var untouched_hashes := {}
		for other_slot in range(1, PlayerProgress.SAVE_SLOT_COUNT + 1):
			if other_slot != slot_id:
				untouched_hashes[other_slot] = _slot_artifact_hashes(other_slot)
		var result := PlayerProgress.delete_save_slot(slot_id)
		_expect(bool(result.get("ok", false)), "slot %d deletion should succeed" % slot_id)
		_expect_eq(int(result.get("slot_id", -1)), slot_id, "deletion result should identify target slot")
		_expect(not bool(result.get("active_deleted", true)), "non-active deletion should report non-active")
		_expect(not FileAccess.file_exists(_slot_save_path(slot_id)), "target main should be deleted")
		_expect(not FileAccess.file_exists(_slot_backup_path(slot_id)), "target backup should be deleted")
		_expect(not FileAccess.file_exists(_slot_tmp_path(slot_id)), "target tmp should be deleted")
		for other_slot in untouched_hashes:
			_expect_slot_artifact_hashes(other_slot, untouched_hashes[other_slot], "non-target slot must remain byte-identical")
		_expect_eq(_file_hash(settings_path), settings_hash, "settings must remain byte-identical")

	var repeated := PlayerProgress.delete_save_slot(3)
	_expect(bool(repeated.get("ok", false)), "deleting an empty slot should be idempotent")
	# main / backup / tmpの一部だけが残る欠損状態でも、残存物だけを安全に削除する。
	for artifact_kind in ["main", "backup", "tmp"]:
		_remove_all_save_files()
		var artifact_path := _slot_save_path(3)
		if artifact_kind == "backup":
			artifact_path = _slot_backup_path(3)
		elif artifact_kind == "tmp":
			artifact_path = _slot_tmp_path(3)
		_write_text(artifact_path, "partial-%s" % artifact_kind)
		var partial_result := PlayerProgress.delete_save_slot(3)
		_expect(bool(partial_result.get("ok", false)), "partial %s deletion should succeed" % artifact_kind)
		_expect(not FileAccess.file_exists(artifact_path), "partial %s artifact should be deleted" % artifact_kind)
		_expect_eq(_file_hash(settings_path), settings_hash, "partial deletion must preserve settings")

	# 無効ID用fixtureを全slotへ再配置する。
	for fixture_slot in range(1, PlayerProgress.SAVE_SLOT_COUNT + 1):
		_write_text(_slot_save_path(fixture_slot), "invalid-main-%d" % fixture_slot)
		_write_text(_slot_backup_path(fixture_slot), "invalid-backup-%d" % fixture_slot)
		_write_text(_slot_tmp_path(fixture_slot), "invalid-tmp-%d" % fixture_slot)
	var all_hashes := {}
	for slot_id in range(1, PlayerProgress.SAVE_SLOT_COUNT + 1):
		all_hashes[slot_id] = _slot_artifact_hashes(slot_id)
	for invalid_slot in [0, -1, PlayerProgress.SAVE_SLOT_COUNT + 1, 999]:
		var invalid_result := PlayerProgress.delete_save_slot(invalid_slot)
		_expect(not bool(invalid_result.get("ok", true)), "invalid slot must be rejected")
		_expect_eq(String(invalid_result.get("reason", "")), "invalid_slot", "invalid slot reason")
	for slot_id in all_hashes:
		_expect_slot_artifact_hashes(slot_id, all_hashes[slot_id], "invalid IDs must preserve every slot")
	_expect_eq(_file_hash(settings_path), settings_hash, "invalid and repeated deletion must preserve settings")

	# 3slotそれぞれをactiveとして削除し、非対象2slotをbyte不変で保持する。
	for target_slot in range(1, PlayerProgress.SAVE_SLOT_COUNT + 1):
		_remove_all_save_files()
		_expect(PlayerProgress.set_active_save_slot(target_slot, false), "active deletion fixture should select target")
		PlayerProgress.reset_game()
		PlayerProgress.money = 9876
		PlayerProgress.save_game()
		_write_text(_slot_tmp_path(target_slot), "active-delete-tmp-%d" % target_slot)
		var other_hashes := {}
		for other_slot in range(1, PlayerProgress.SAVE_SLOT_COUNT + 1):
			if other_slot == target_slot:
				continue
			_write_text(_slot_save_path(other_slot), "active-other-main-%d" % other_slot)
			_write_text(_slot_backup_path(other_slot), "active-other-backup-%d" % other_slot)
			_write_text(_slot_tmp_path(other_slot), "active-other-tmp-%d" % other_slot)
			other_hashes[other_slot] = _slot_artifact_hashes(other_slot)
		var active_result := PlayerProgress.delete_save_slot(target_slot)
		_expect(bool(active_result.get("ok", false)), "active slot deletion should succeed")
		_expect(bool(active_result.get("active_deleted", false)), "active deletion should be reported")
		_expect_eq(PlayerProgress.money, 500, "active deletion should reset runtime state")
		_expect(PlayerProgress.is_active_slot_save_suppressed(), "active deletion should suppress automatic saves")
		_expect(not PlayerProgress.save_game(), "suppressed save should report false")
		_expect(not FileAccess.file_exists(_slot_save_path(target_slot)), "suppressed save must not recreate main")
		_expect(not FileAccess.file_exists(_slot_backup_path(target_slot)), "suppressed save must not recreate backup")
		_expect(not FileAccess.file_exists(_slot_tmp_path(target_slot)), "suppressed save must not recreate tmp")
		for other_slot in other_hashes:
			_expect_slot_artifact_hashes(other_slot, other_hashes[other_slot], "active deletion must preserve non-target slots")
		_expect_eq(_file_hash(settings_path), settings_hash, "active deletion must preserve settings")

		_expect(PlayerProgress.reset_game(), "explicit new game should recreate the active slot")
		_expect(not PlayerProgress.is_active_slot_save_suppressed(), "new game should clear save suppression")
		_expect(FileAccess.file_exists(_slot_save_path(target_slot)), "explicit new game should create main")
	_remove_if_exists(settings_path)


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


func _verify_e7_title_new_game_flow() -> void:
	# empty: 難易度選択後の初回save成功後にだけ遷移する。
	_remove_all_save_files()
	PlayerProgress.set_active_save_slot(1, false)
	var empty_viewport := SubViewport.new()
	empty_viewport.size = Vector2i(1280, 720)
	empty_viewport.disable_3d = true
	add_child(empty_viewport)
	var empty_title: TitleScreen = TitleScreen.new()
	empty_title.theme = ThemeFactory.build_theme()
	empty_viewport.add_child(empty_title)
	await get_tree().process_frame
	await get_tree().process_frame
	var empty_navigations: Array[String] = []
	empty_title.navigate_requested.connect(
		func(screen_id: String, _payload: Dictionary) -> void: empty_navigations.append(screen_id)
	)
	empty_title._on_new_game_pressed()
	_expect(empty_title._modal_layer.visible, "empty new game should open difficulty modal")
	_expect(empty_title._difficulty_buttons.size() == 3, "difficulty modal should expose exactly three choices")
	for button in empty_title._slot_buttons:
		_expect(button.focus_mode == Control.FOCUS_NONE, "difficulty modal should contain focus away from slot buttons")
	_expect(empty_title._continue_button.focus_mode == Control.FOCUS_NONE, "modal should block continue focus")
	_expect(empty_title._new_button.focus_mode == Control.FOCUS_NONE, "modal should block new-game focus")
	PlayerProgress._save_failure_injection_stage = "tmp_open"
	empty_title._on_difficulty_selected("hard")
	PlayerProgress._save_failure_injection_stage = ""
	_expect(empty_navigations.is_empty(), "SAVE-02 initial save failure should keep the player on title")
	_expect(not FileAccess.file_exists(_slot_save_path(1)), "SAVE-02 initial save failure should not create a slot")
	empty_title._on_new_game_pressed()
	empty_title._on_difficulty_selected("easy")
	_expect_eq(empty_navigations, ["harbor"], "empty difficulty selection should navigate after save")
	_expect(FileAccess.file_exists(_slot_save_path(1)), "empty difficulty selection should create selected slot")
	_expect_eq(String(_read_json(_slot_save_path(1)).get("difficulty_id", "")), "easy", "empty start should persist selected difficulty")
	empty_viewport.queue_free()
	await get_tree().process_frame

	# occupied: 難易度選択の後にだけ1回の最終確認を出し、他slotを変更しない。
	_remove_all_save_files()
	PlayerProgress.set_active_save_slot(1, false)
	_expect(PlayerProgress.reset_game("normal"), "occupied fixture slot 1 should save")
	PlayerProgress.level = 12
	PlayerProgress.play_seconds = 45240.0
	_expect(PlayerProgress.save_game(), "occupied fixture slot 1 values should save")
	PlayerProgress.set_active_save_slot(2, false)
	_expect(PlayerProgress.reset_game("easy"), "other slot fixture should save")
	PlayerProgress.money = 2222
	_expect(PlayerProgress.save_game(), "slot 2 backup generation should save")
	PlayerProgress.set_active_save_slot(3, false)
	_expect(PlayerProgress.reset_game("hard"), "third slot fixture should save")
	PlayerProgress.money = 3333
	_expect(PlayerProgress.save_game(), "slot 3 backup generation should save")
	var slot_2_hashes := _slot_artifact_hashes(2)
	var slot_3_hashes := _slot_artifact_hashes(3)
	PlayerProgress.set_active_save_slot(1)
	var occupied_viewport := SubViewport.new()
	occupied_viewport.size = Vector2i(1280, 720)
	occupied_viewport.disable_3d = true
	add_child(occupied_viewport)
	var occupied_title: TitleScreen = TitleScreen.new()
	occupied_title.theme = ThemeFactory.build_theme()
	occupied_viewport.add_child(occupied_title)
	await get_tree().process_frame
	await get_tree().process_frame
	var occupied_navigations: Array[String] = []
	occupied_title.navigate_requested.connect(
		func(screen_id: String, _payload: Dictionary) -> void: occupied_navigations.append(screen_id)
	)
	occupied_title._on_new_game_pressed()
	_expect(occupied_title._difficulty_panel.visible, "occupied flow must select difficulty before confirmation")
	_expect(not occupied_title._overwrite_panel.visible, "old pre-difficulty confirmation must not appear")
	occupied_title._on_difficulty_selected("hard")
	_expect(occupied_title._overwrite_panel.visible, "occupied difficulty selection should show one final confirmation")
	var details := occupied_title._overwrite_detail_label.text
	for required in ["スロット: 1", "Lv.12", "12時間34分", "むずかしい", "元には戻せません"]:
		_expect(details.contains(required), "overwrite confirmation should include %s" % required)
	_expect(occupied_title.get_viewport().gui_get_focus_owner() == occupied_title._overwrite_cancel_button, "overwrite confirmation should focus cancel first")
	_expect(occupied_navigations.is_empty(), "occupied flow should not navigate before final confirmation")
	occupied_title._confirm_overwrite()
	_expect_eq(occupied_navigations, ["harbor"], "occupied final confirmation should navigate once")
	_expect_eq(String(_read_json(_slot_save_path(1)).get("difficulty_id", "")), "hard", "confirmed overwrite should persist hard")
	_expect_slot_artifact_hashes(2, slot_2_hashes, "occupied overwrite must preserve slot 2 artifacts")
	_expect_slot_artifact_hashes(3, slot_3_hashes, "occupied overwrite must preserve slot 3 artifacts")
	occupied_viewport.queue_free()
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
	main.size = Vector2(1280.0, 720.0)
	add_child(main)
	await get_tree().create_timer(0.4).timeout
	_expect(not get_tree().auto_accept_quit, "main should disable automatic close request acceptance")
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
	PlayerProgress._save_failure_injection_stage = "tmp_open"
	var title_screen = main._current_screen
	var gameplay_screen := ScreenBase.new()
	main._current_screen = gameplay_screen
	main._notification(NOTIFICATION_WM_CLOSE_REQUEST)
	PlayerProgress._save_failure_injection_stage = ""
	main._current_screen = title_screen
	gameplay_screen.free()
	_expect(main._save_exit_dialog != null, "close request save failure should show a retry dialog")
	_expect(main._save_exit_dialog.visible, "close request save failure dialog should remain visible")
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


func _verify_difficulty_save_contract() -> void:
	_remove_all_save_files()
	_expect(
		PlayerProgress._is_valid_save_candidate(
			{"version": PlayerProgress.SAVE_VERSION, "difficulty_id": "hard"}
		),
		"difficulty-only sparse save should remain valid"
	)
	_expect(
		not PlayerProgress._is_valid_save_candidate(
			{"version": PlayerProgress.SAVE_VERSION, "difficulty_id": ["hard"]}
		),
		"non-String difficulty_id should be rejected"
	)

	# E7以前のsaveはnormalへ補完し、次回saveで明示的に永続化する。
	_write_text(
		_slot_save_path(1),
		JSON.stringify({"version": PlayerProgress.SAVE_VERSION, "level": 7, "money": 321})
	)
	_expect(PlayerProgress.set_active_save_slot(1), "legacy difficulty save should load")
	_expect_eq(
		PlayerProgress.difficulty_id,
		GameData.DEFAULT_DIFFICULTY_ID,
		"legacy save should default to normal"
	)
	_expect_eq(
		String(PlayerProgress.save_slot_summary(1).get("difficulty_id", "")),
		GameData.DEFAULT_DIFFICULTY_ID,
		"legacy slot summary should default to normal"
	)
	_expect(PlayerProgress.save_game(), "legacy difficulty default should save")
	_expect_eq(
		String(_read_json(_slot_save_path(1)).get("difficulty_id", "")),
		GameData.DEFAULT_DIFFICULTY_ID,
		"normal default should persist on next save"
	)

	# 未知のString IDはsave候補として保ち、ロード正規化だけでnormalへ戻す。
	_remove_all_save_files()
	_write_text(
		_slot_save_path(1),
		JSON.stringify({"version": PlayerProgress.SAVE_VERSION, "difficulty_id": "future-mode"})
	)
	_expect(PlayerProgress.set_active_save_slot(1), "unknown difficulty String should stay loadable")
	_expect_eq(
		PlayerProgress.difficulty_id,
		GameData.DEFAULT_DIFFICULTY_ID,
		"unknown difficulty String should normalize to normal"
	)

	# 選択slotだけをhardで初期化し、他2slotの全artifactを変更しない。
	_remove_all_save_files()
	var initial_difficulties := {1: "easy", 2: "normal", 3: "easy"}
	for slot_id in range(1, PlayerProgress.SAVE_SLOT_COUNT + 1):
		_expect(PlayerProgress.set_active_save_slot(slot_id, false), "slot %d should activate" % slot_id)
		_expect(
			PlayerProgress.reset_game(String(initial_difficulties[slot_id])),
			"slot %d difficulty reset should save" % slot_id
		)
		PlayerProgress.money = 1000 + slot_id
		_expect(PlayerProgress.save_game(), "slot %d second generation should save" % slot_id)
	var slot_1_hashes := _slot_artifact_hashes(1)
	var slot_3_hashes := _slot_artifact_hashes(3)
	_expect(PlayerProgress.set_active_save_slot(2), "slot 2 should activate for reset validation")
	var slot_2_hashes := _slot_artifact_hashes(2)
	var slot_2_money_before := PlayerProgress.money
	_expect(not PlayerProgress.reset_game("typo"), "unknown difficulty should refuse reset")
	_expect_slot_artifact_hashes(2, slot_2_hashes, "unknown difficulty should preserve slot 2")
	_expect_eq(PlayerProgress.money, slot_2_money_before, "unknown difficulty should preserve runtime")
	_expect_eq(PlayerProgress.difficulty_id, "normal", "unknown reset should preserve difficulty")
	_expect(PlayerProgress.reset_game("hard"), "slot 2 hard reset should save")
	_expect_slot_artifact_hashes(1, slot_1_hashes, "slot 2 reset should preserve slot 1")
	_expect_slot_artifact_hashes(3, slot_3_hashes, "slot 2 reset should preserve slot 3")
	_expect_eq(
		String(_read_json(_slot_save_path(2)).get("difficulty_id", "")),
		"hard",
		"selected slot should persist hard"
	)
	_expect(PlayerProgress.set_active_save_slot(2), "hard slot should reload")
	_expect_eq(PlayerProgress.difficulty_id, "hard", "hard difficulty should round-trip")
	_expect(PlayerProgress.set_active_save_slot(1), "easy slot should reload")
	_expect_eq(PlayerProgress.difficulty_id, "easy", "other slot difficulty should remain unchanged")

	_remove_all_save_files()
	PlayerProgress._reset_runtime_state()
	_expect(PlayerProgress.set_active_save_slot(1, false), "difficulty cleanup should restore slot 1")


func _verify_semantic_save_candidate_selection() -> void:
	_remove_all_save_files()
	var max_safe := PlayerProgress.MAX_SAFE_JSON_INTEGER
	var invalid_main := {"version": PlayerProgress.SAVE_VERSION, "level": {}, "money": 9999}
	var valid_backup := {
		"version": PlayerProgress.SAVE_VERSION,
		"level": 8,
		"money": 4321,
		"play_seconds": 98.5,
		"spot_caught_counts": {"harbor_pier": {"aji": 2, "iwashi": 1}},
		"quest_board": [
			{
				"template_id": "bulk_common",
				"kind": "delivery",
				"fish_id": "aji",
				"count": 5,
				"reward_money": 960,
				"text": "アジを5匹届けてほしい",
			},
			{"kind": "delivery", "fish_id": "legacy_unknown", "text": "unknown"},
			{"kind": "delivery", "fish_id": "nekozame", "text": "shark"},
			{"kind": "record", "fish_id": "nushi_deep_ocean", "text": "boss"},
		],
	}
	_write_text(_slot_save_path(1), JSON.stringify(invalid_main, "\t"))
	_write_text(_slot_backup_path(1), JSON.stringify(valid_backup, "\t"))
	var summary := PlayerProgress.save_slot_summary(1)
	_expect(bool(summary.get("has_save", false)), "valid backup should make the slot available")
	_expect_eq(int(summary.get("level", -1)), 8, "summary should select semantically valid backup")
	_expect_eq(int(summary.get("money", -1)), 4321, "summary money should come from selected backup")
	_expect_eq(float(summary.get("play_seconds", -1.0)), 98.5, "summary time should come from selected backup")
	PlayerProgress.money = 0
	PlayerProgress.load_game()
	_expect_eq(PlayerProgress.level, 8, "load should select the same valid backup as summary")
	_expect_eq(PlayerProgress.money, 4321, "load money should match backup summary")
	_expect_eq(PlayerProgress.quest_board.size(), 3, "fallback load should repair board to three quests")
	_expect_eq(
		String(PlayerProgress.quest_board[0].get("template_id", "")),
		"bulk_common",
		"fallback repair should preserve the valid quest in place"
	)
	for quest in PlayerProgress.quest_board:
		_expect(
			not GameData.is_quest_excluded_fish_id(String(quest.get("fish_id", ""))),
			"fallback repair should remove unknown, shark, and boss quests"
		)
	_expect_eq(
		int(PlayerProgress.spot_caught_counts.get("harbor_pier", {}).get("aji", 0)),
		2,
		"nested spot catch counts should load from the selected backup"
	)
	# fallback直後のfinal rename失敗でも、不正mainと唯一の正常backupを両方維持する。
	var fallback_hashes := {
		"main": _file_hash(_slot_save_path(1)),
		"backup": _file_hash(_slot_backup_path(1)),
	}
	PlayerProgress._save_failure_injection_stage = "final_rename"
	_expect(not PlayerProgress.save_game(), "fallback save final rename failure should be reported")
	PlayerProgress._save_failure_injection_stage = ""
	_expect_eq(_file_hash(_slot_save_path(1)), fallback_hashes["main"], "fallback failure preserves invalid main original")
	_expect_eq(_file_hash(_slot_backup_path(1)), fallback_hashes["backup"], "fallback failure preserves valid backup")
	_expect_eq(int(PlayerProgress.save_slot_summary(1).get("level", -1)), 8, "valid backup remains selectable after failed save")

	# nested釣果を持つ正常mainもbackupへ巻き戻さず、そのまま選択する。
	var valid_main := {
		"version": PlayerProgress.SAVE_VERSION,
		"level": 9,
		"money": 5432,
		"spot_caught_counts": {"rocky_shore": {"kasago": 3}},
	}
	_write_text(_slot_save_path(1), JSON.stringify(valid_main, "\t"))
	var main_summary := PlayerProgress.save_slot_summary(1)
	_expect_eq(int(main_summary.get("level", -1)), 9, "nested spot counts should keep valid main selected")
	PlayerProgress.load_game()
	_expect_eq(PlayerProgress.money, 5432, "valid nested main should load instead of backup")
	_expect_eq(
		int(PlayerProgress.spot_caught_counts.get("rocky_shore", {}).get("kasago", 0)),
		3,
		"valid nested main spot count should load"
	)

	# 内側Dictionary、fish ID、countの型・範囲破損は候補から除外する。
	var invalid_spot_count_cases: Array[Dictionary] = [
		{"spot_caught_counts": {"harbor_pier": []}},
		{"spot_caught_counts": {"harbor_pier": {"": 1}}},
		{"spot_caught_counts": {"harbor_pier": {"aji": []}}},
		{"spot_caught_counts": {"harbor_pier": {"aji": -1}}},
	]
	for invalid_spot_counts in invalid_spot_count_cases:
		var invalid_nested_main := {"version": PlayerProgress.SAVE_VERSION, "level": 40}
		invalid_nested_main.merge(invalid_spot_counts)
		_write_text(_slot_save_path(1), JSON.stringify(invalid_nested_main, "\t"))
		var nested_summary := PlayerProgress.save_slot_summary(1)
		_expect_eq(
			int(nested_summary.get("level", -1)),
			8,
			"invalid nested spot count should fall back to valid backup"
		)
		PlayerProgress.load_game()
		_expect_eq(PlayerProgress.level, 8, "invalid nested spot count should not load")

	# 整数fieldのfraction、空root、未知keyだけのrootは正常backupより先に採用しない。
	var invalid_root_cases: Array[Dictionary] = [
		{},
		{"unknown_only": true},
		{"version": PlayerProgress.SAVE_VERSION, "level": 8.5},
		{"version": PlayerProgress.SAVE_VERSION, "money": 0.5},
		{"version": PlayerProgress.SAVE_VERSION, "inventory": {"aji": 1.5}},
		{"version": PlayerProgress.SAVE_VERSION, "sea_chart_fragments": 1.5},
		{"version": PlayerProgress.SAVE_VERSION, "shark_bonds": {"nekozame": 1.5}},
		{"version": PlayerProgress.SAVE_VERSION, "money": 1e100},
		{"version": PlayerProgress.SAVE_VERSION, "caught_counts": {"aji": 1e100}},
		{"version": PlayerProgress.SAVE_VERSION, "inventory": {"aji": max_safe, "mejina": 1}},
		{"version": PlayerProgress.SAVE_VERSION, "caught_counts": {"aji": max_safe, "mejina": 1}},
		{"version": PlayerProgress.SAVE_VERSION, "eaten_recipes": {"aji:salt_grill": 0.5}},
		{
			"version": PlayerProgress.SAVE_VERSION,
			"eaten_recipes": {"aji:salt_grill": max_safe, "mejina:salt_grill": 1},
		},
	]
	for invalid_root in invalid_root_cases:
		_write_text(_slot_save_path(1), JSON.stringify(invalid_root, "\t"))
		_expect_eq(
			int(PlayerProgress.save_slot_summary(1).get("level", -1)),
			8,
			"empty, unknown-only, or fractional main should fall back to backup"
		)

	# 両候補が意味不正なら通知し、main / backup原本とruntime値を維持する。
	_write_text(_slot_save_path(1), JSON.stringify(invalid_main, "\t"))
	var invalid_backup := {"version": PlayerProgress.SAVE_VERSION, "inventory": []}
	_write_text(_slot_backup_path(1), JSON.stringify(invalid_backup, "\t"))
	var original_hashes := {
		"main": _file_hash(_slot_save_path(1)),
		"backup": _file_hash(_slot_backup_path(1)),
	}
	var failure_messages: Array[String] = []
	var collect_failure := func(message: String) -> void: failure_messages.append(message)
	PlayerProgress.save_failed.connect(collect_failure)
	PlayerProgress.money = 7654
	PlayerProgress.load_game()
	PlayerProgress.save_failed.disconnect(collect_failure)
	_expect_eq(PlayerProgress.money, 7654, "invalid candidates should preserve runtime state")
	_expect_eq(failure_messages.size(), 1, "invalid candidates should notify the user once")
	_expect(not failure_messages[0].is_empty(), "invalid candidate notification should explain the failure")
	_expect_eq(_file_hash(_slot_save_path(1)), original_hashes["main"], "invalid main original hash")
	_expect_eq(_file_hash(_slot_backup_path(1)), original_hashes["backup"], "invalid backup original hash")
	PlayerProgress.money = 8765
	_expect(not PlayerProgress.save_game(), "direct save should refuse two invalid artifacts")
	_expect_eq(PlayerProgress.money, 8765, "refused direct save should preserve runtime state")
	_expect_eq(_file_hash(_slot_save_path(1)), original_hashes["main"], "refused direct save preserves invalid main")
	_expect_eq(_file_hash(_slot_backup_path(1)), original_hashes["backup"], "refused direct save preserves invalid backup")
	_expect(not PlayerProgress.reset_game(), "direct reset should refuse two invalid artifacts")
	_expect_eq(PlayerProgress.money, 8765, "refused direct reset should preserve runtime state")
	_expect_eq(_file_hash(_slot_save_path(1)), original_hashes["main"], "refused direct reset preserves invalid main")
	_expect_eq(_file_hash(_slot_backup_path(1)), original_hashes["backup"], "refused direct reset preserves invalid backup")
	_write_text(_slot_save_path(2), JSON.stringify(invalid_main, "\t"))
	_write_text(_slot_backup_path(2), JSON.stringify(invalid_backup, "\t"))
	var invalid_slot_2_hashes := {
		"main": _file_hash(_slot_save_path(2)),
		"backup": _file_hash(_slot_backup_path(2)),
	}
	_expect(not PlayerProgress.set_active_save_slot(2), "direct slot switch should refuse invalid artifacts")
	_expect_eq(PlayerProgress.active_save_slot, 1, "refused slot switch should preserve active slot")
	_expect_eq(PlayerProgress.money, 8765, "refused slot switch should preserve runtime state")
	_expect_eq(_file_hash(_slot_save_path(2)), invalid_slot_2_hashes["main"], "refused slot switch preserves invalid main")
	_expect_eq(_file_hash(_slot_backup_path(2)), invalid_slot_2_hashes["backup"], "refused slot switch preserves invalid backup")
	var invalid_summary := PlayerProgress.save_slot_summary(1)
	_expect(bool(invalid_summary.get("has_save", false)), "invalid artifacts should not look like an empty slot")
	_expect(bool(invalid_summary.get("invalid_artifact", false)), "summary should persist invalid artifact state")
	_expect(not bool(invalid_summary.get("candidate_valid", true)), "invalid summary should expose no valid candidate")
	await _verify_title_invalid_slot_is_blocked(original_hashes)

	# version 1だけの疎saveも正常候補で、欠損値はデフォルト補完する。
	_remove_all_save_files()
	_write_text(_slot_save_path(1), JSON.stringify({"version": PlayerProgress.SAVE_VERSION}))
	_expect(bool(PlayerProgress.save_slot_summary(1).get("has_save", false)), "version-only sparse save should be valid")
	_expect_eq(int(PlayerProgress.save_slot_summary(1).get("money", -1)), 500, "version-only summary should match load default money")
	PlayerProgress.load_game()
	_expect_eq(PlayerProgress.level, 1, "version-only sparse save should default level")
	_expect_eq(PlayerProgress.money, 500, "version-only sparse save should default money")
	_remove_all_save_files()


func _verify_title_invalid_slot_is_blocked(expected_hashes: Dictionary) -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.disable_3d = true
	add_child(viewport)
	var title: TitleScreen = TitleScreen.new()
	title.theme = ThemeFactory.build_theme()
	viewport.add_child(title)
	await get_tree().process_frame
	await get_tree().process_frame
	title._select_slot(1)
	_expect(title._continue_button.disabled, "invalid slot should disable continue")
	_expect(title._new_button.disabled, "invalid slot should disable new game overwrite")
	_expect(title._slot_buttons[0].text.contains("破損"), "invalid slot should persist a damaged label")
	_expect(title._slot_status_label.text.contains("原本は変更していません"), "title should explain invalid artifact preservation")
	title._start_new_game()
	_expect_eq(_file_hash(_slot_save_path(1)), expected_hashes["main"], "blocked title start preserves invalid main")
	_expect_eq(_file_hash(_slot_backup_path(1)), expected_hashes["backup"], "blocked title start preserves invalid backup")
	viewport.queue_free()
	await get_tree().process_frame


func _verify_safe_integer_and_outbound_contract() -> void:
	var max_safe := PlayerProgress.MAX_SAFE_JSON_INTEGER
	var accepted_boundaries: Array[Dictionary] = [
		{"version": 1, "money": max_safe},
		{"version": 1, "inventory": {"aji": max_safe}},
		{"version": 1, "caught_counts": {"aji": max_safe}},
		{"version": 1, "eaten_recipes": {"aji:salt_grill": max_safe}},
		{"version": 1, "spot_caught_counts": {"harbor_pier": {"aji": max_safe}}},
		{"version": 1, "quest_board": [{"count": max_safe, "reward_money": max_safe}]},
		{"version": 1, "shark_bonds": {"nekozame": max_safe}},
	]
	var rejected_boundaries: Array[Dictionary] = [
		{"version": 1, "money": max_safe + 1},
		{"version": 1, "inventory": {"aji": max_safe + 1}},
		{"version": 1, "inventory": {"aji": max_safe, "mejina": 1}},
		{"version": 1, "caught_counts": {"aji": max_safe + 1}},
		{"version": 1, "caught_counts": {"aji": max_safe, "mejina": 1}},
		{"version": 1, "eaten_recipes": {"aji:salt_grill": max_safe + 1}},
		{"version": 1, "eaten_recipes": {"aji:salt_grill": max_safe, "mejina:salt_grill": 1}},
		{"version": 1, "eaten_recipes": {"aji:salt_grill": 0.5}},
		{"version": 1, "spot_caught_counts": {"harbor_pier": {"aji": max_safe + 1}}},
		{"version": 1, "quest_board": [{"count": max_safe + 1}]},
		{"version": 1, "shark_bonds": {"nekozame": max_safe + 1}},
	]
	for candidate in accepted_boundaries:
		_expect(PlayerProgress._is_valid_save_candidate(candidate), "2^53-1 should be accepted on every integer path")
	for candidate in rejected_boundaries:
		_expect(not PlayerProgress._is_valid_save_candidate(candidate), "2^53 should be rejected on every integer path")

	_remove_all_save_files()
	PlayerProgress.set_active_save_slot(1, false)
	PlayerProgress.money = max_safe
	_expect(PlayerProgress.save_game(), "MAX_SAFE_JSON_INTEGER outbound save should succeed")
	PlayerProgress.load_game()
	_expect_eq(PlayerProgress.money, max_safe, "MAX_SAFE_JSON_INTEGER should round-trip")
	PlayerProgress.gain_trip_event_money(1)
	_expect_eq(PlayerProgress.money, max_safe, "normal money gain should saturate at JSON safe integer max")
	_expect_eq(int(_read_json(_slot_save_path(1)).get("money", -1)), max_safe, "saturated money save should remain valid")
	PlayerProgress.load_game()
	_expect_eq(PlayerProgress.money, max_safe, "saturated money should reload without backup rollback")
	PlayerProgress.money = 500
	PlayerProgress.gain_trip_event_money(9223372036854775807)
	_expect_eq(PlayerProgress.money, max_safe, "extreme money gain should saturate before int64 addition overflow")

	var hashes_before_invalid_outbound := {
		"main": _file_hash(_slot_save_path(1)),
		"backup": _file_hash(_slot_backup_path(1)),
		"tmp": _file_hash(_slot_tmp_path(1)),
	}
	var outbound_failures: Array[String] = []
	var collect_failure := func(message: String) -> void: outbound_failures.append(message)
	PlayerProgress.save_failed.connect(collect_failure)
	PlayerProgress.money = max_safe + 1
	_expect(not PlayerProgress.save_game(), "2^53 outbound data should be refused before tmp write")
	PlayerProgress.save_failed.disconnect(collect_failure)
	_expect_eq(outbound_failures.size(), 1, "invalid outbound save should notify once")
	_expect_eq(_file_hash(_slot_save_path(1)), hashes_before_invalid_outbound["main"], "invalid outbound preserves main")
	_expect_eq(_file_hash(_slot_backup_path(1)), hashes_before_invalid_outbound["backup"], "invalid outbound preserves backup")
	_expect_eq(_file_hash(_slot_tmp_path(1)), hashes_before_invalid_outbound["tmp"], "invalid outbound preserves tmp")
	_remove_all_save_files()


func _verify_saturating_progress_mutations() -> void:
	var max_safe := PlayerProgress.MAX_SAFE_JSON_INTEGER
	var overflow_sell_amount := 1281023894007608
	_expect_eq(PlayerProgress._saturating_add_nonnegative(500, 250), 750, "normal addition should remain exact")
	_expect_eq(PlayerProgress._saturating_multiply_nonnegative(120, 3), 360, "normal multiplication should remain exact")
	_expect_eq(
		PlayerProgress._saturating_multiply_nonnegative(50000, max_safe),
		max_safe,
		"MAX sell price times MAX_SAFE must saturate before int64 multiplication"
	)

	# Dictionary総和が上限のsaveから新魚を釣っても、所持・捕獲・spot値を範囲外へ出さない。
	var initial_hash := _prepare_saturation_fixture(
		{
			"inventory": {"aji": max_safe},
			"caught_counts": {"aji": max_safe},
			"spot_caught_counts": {"harbor_pier": {"mejina": max_safe}},
		},
		"record_catch saturation"
	)
	var catch_result := PlayerProgress.record_catch("mejina", 42.0, "harbor_pier")
	_expect(not bool(catch_result.get("first_catch", true)), "global caught cap must not claim an unrecorded first catch")
	_expect(not PlayerProgress.inventory.has("mejina"), "global inventory cap must not add a new counter")
	_expect(not PlayerProgress.caught_counts.has("mejina"), "global caught cap must not add a new counter")
	_expect_eq(
		int(PlayerProgress.spot_caught_counts.get("harbor_pier", {}).get("mejina", -1)),
		max_safe,
		"spot catch counter should saturate"
	)
	_expect_saturation_generation(initial_hash, "record_catch saturation")
	PlayerProgress.load_game()
	_expect_eq(int(PlayerProgress.inventory.get("aji", -1)), max_safe, "record_catch saturated inventory reload")

	# 初捕獲ヌシの報酬は所持金上限で止まり、inventory総和上限も維持する。
	initial_hash = _prepare_saturation_fixture(
		{
			"money": max_safe,
			"inventory": {"aji": max_safe},
			"caught_counts": {},
		},
		"boss reward saturation"
	)
	var boss_result := PlayerProgress.record_catch("nushi_deep_ocean", 300.0, "deep_ocean")
	_expect(bool(boss_result.get("first_catch", false)), "recordable boss should remain a first catch")
	_expect(not Dictionary(boss_result.get("boss_first_clear_reward", {})).is_empty(), "boss reward should still be awarded")
	_expect_eq(PlayerProgress.money, max_safe, "boss reward money should saturate")
	_expect(not PlayerProgress.inventory.has("nushi_deep_ocean"), "boss catch must respect global inventory cap")
	_expect_saturation_generation(initial_hash, "boss reward saturation")
	PlayerProgress.load_game()
	_expect_eq(PlayerProgress.money, max_safe, "boss reward saturated money should reload")
	_expect_eq(int(PlayerProgress.caught_counts.get("nushi_deep_ocean", 0)), 1, "boss catch count should reload")
	_expect(not PlayerProgress.inventory.has("nushi_deep_ocean"), "boss inventory cap should persist after reload")

	# 14,400 × 1,281,023,894,007,608 はint64積を作らず、income/moneyをsafe上限へ送る。
	initial_hash = _prepare_saturation_fixture(
		{
			"money": 500,
			"inventory": {"nushi_deep_ocean": overflow_sell_amount},
		},
		"single sell overflow saturation"
	)
	var sell_result := PlayerProgress.sell_fish("nushi_deep_ocean", overflow_sell_amount)
	_expect(bool(sell_result.get("ok", false)), "safe-count single sell should succeed")
	_expect_eq(int(sell_result.get("income", -1)), max_safe, "single sell income should saturate")
	_expect_eq(PlayerProgress.money, max_safe, "single sell money should saturate")
	_expect_eq(PlayerProgress.fish_count("nushi_deep_ocean"), 0, "single sell should consume inventory")
	_expect_saturation_generation(initial_hash, "single sell overflow saturation")
	PlayerProgress.load_game()
	_expect_eq(PlayerProgress.money, max_safe, "single sell saturated money should reload")

	# batchは各item積、income、total_amount、moneyをすべてsafe範囲へ保つ。
	var remaining_batch_amount := max_safe - overflow_sell_amount
	initial_hash = _prepare_saturation_fixture(
		{
			"money": 500,
			"inventory": {
				"nushi_deep_ocean": overflow_sell_amount,
				"aji": remaining_batch_amount,
			},
		},
		"batch sell overflow saturation"
	)
	var batch_result := PlayerProgress.sell_fish_batch(
		{
			"nushi_deep_ocean": overflow_sell_amount,
			"aji": remaining_batch_amount,
		}
	)
	_expect(bool(batch_result.get("ok", false)), "safe-count batch sell should succeed")
	_expect_eq(int(batch_result.get("income", -1)), max_safe, "batch income should saturate")
	_expect_eq(int(batch_result.get("total_amount", -1)), max_safe, "batch total amount should stay safe")
	_expect_eq(PlayerProgress.money, max_safe, "batch money should saturate")
	var sold: Dictionary = batch_result.get("sold", {})
	_expect_eq(
		int(Dictionary(sold.get("nushi_deep_ocean", {})).get("income", -1)),
		max_safe,
		"batch item income should saturate before multiplication"
	)
	_expect_saturation_generation(initial_hash, "batch sell overflow saturation")
	PlayerProgress.load_game()
	_expect_eq(PlayerProgress.money, max_safe, "batch saturated money should reload")
	_expect_eq(PlayerProgress.fish_count("nushi_deep_ocean"), 0, "batch sold boss inventory should reload")
	_expect_eq(PlayerProgress.fish_count("aji"), 0, "batch sold regular inventory should reload")

	# 依頼報酬と達成累計は上限で止まり、納品後saveも正常候補のままにする。
	initial_hash = _prepare_saturation_fixture(
		{
			"money": 500,
			"inventory": {"aji": max_safe},
			"quest_completed_count": max_safe,
			"quest_board": [
				{
					"template_id": "saturation_delivery",
					"kind": "delivery",
					"fish_id": "aji",
					"count": 1,
					"reward_money": max_safe,
					"text": "アジを1匹届けてほしい",
				},
				{
					"template_id": "saturation_record_a",
					"kind": "record",
					"fish_id": "mejina",
					"target_size_cm": 9999.0,
					"reward_money": 0,
					"text": "fixture a",
				},
				{
					"template_id": "saturation_record_b",
					"kind": "record",
					"fish_id": "kasago",
					"target_size_cm": 9999.0,
					"reward_money": 0,
					"text": "fixture b",
				},
			],
		},
		"quest reward saturation"
	)
	var quest_result := PlayerProgress.deliver_quest(0)
	_expect(bool(quest_result.get("ok", false)), "MAX_SAFE quest should deliver")
	_expect_eq(PlayerProgress.money, max_safe, "quest reward money should saturate")
	_expect_eq(PlayerProgress.quest_completed_count, max_safe, "quest completed count should saturate")
	_expect_eq(PlayerProgress.fish_count("aji"), max_safe - 1, "quest should consume one fish safely")
	_expect_saturation_generation(initial_hash, "quest reward saturation")
	PlayerProgress.load_game()
	_expect_eq(PlayerProgress.money, max_safe, "quest saturated money should reload")
	_expect_eq(PlayerProgress.quest_completed_count, max_safe, "quest saturated count should reload")
	_expect_eq(PlayerProgress.fish_count("aji"), max_safe - 1, "quest inventory should reload")
	_expect_eq(PlayerProgress.quest_board.size(), 3, "quest replacement board should reload")

	# 料理回数の総和が上限なら増分だけを止め、EXP加算もint64 overflow前にsaturateする。
	initial_hash = _prepare_saturation_fixture(
		{
			"level": 1,
			"exp": max_safe,
			"inventory": {"aji": 1},
			"eaten_recipes": {
				"aji:salt_grill": max_safe - 1,
				"mejina:salt_grill": 1,
			},
		},
		"cooking count and exp saturation"
	)
	var capped_cooking_preview := PlayerProgress.cooking_exp_preview("aji", "salt_grill")
	_expect(
		not bool(capped_cooking_preview.get("first_time", true)),
		"cooking preview should drop first bonus when the recipe counter cannot grow"
	)
	_expect_eq(
		int(capped_cooking_preview.get("total_exp", -1)),
		int(capped_cooking_preview.get("base_exp", -2)),
		"capped cooking preview total should match the actual base-only award"
	)
	var cooking_result := PlayerProgress.cook_and_eat("aji", "salt_grill")
	_expect(bool(cooking_result.get("ok", false)), "MAX_SAFE cooking fixture should succeed")
	_expect_eq(
		int(PlayerProgress.eaten_recipes.get("aji:salt_grill", -1)),
		max_safe - 1,
		"cooking count should stop when dictionary total reaches MAX_SAFE"
	)
	_expect_eq(PlayerProgress.level, GameData.MAX_LEVEL, "saturated EXP should resolve levels without overflow")
	_expect_eq(PlayerProgress.exp, 0, "max-level EXP should normalize to zero")
	_expect_saturation_generation(initial_hash, "cooking count and exp saturation")
	PlayerProgress.load_game()
	_expect_eq(PlayerProgress.level, GameData.MAX_LEVEL, "saturated cooking save should reload")
	_remove_all_save_files()


func _prepare_saturation_fixture(data: Dictionary, label: String) -> String:
	_remove_all_save_files()
	_expect(PlayerProgress.set_active_save_slot(1, false), "%s should activate slot 1" % label)
	var fixture := data.duplicate(true)
	fixture["version"] = PlayerProgress.SAVE_VERSION
	_expect(PlayerProgress._is_valid_save_candidate(fixture), "%s fixture should satisfy SAVE-03" % label)
	_write_text(_slot_save_path(1), JSON.stringify(fixture, "\t"))
	var initial_hash := _file_hash(_slot_save_path(1))
	PlayerProgress.load_game()
	return initial_hash


func _expect_saturation_generation(initial_hash: String, label: String) -> void:
	_expect(FileAccess.file_exists(_slot_save_path(1)), "%s should write a main save" % label)
	_expect(FileAccess.file_exists(_slot_backup_path(1)), "%s should preserve a backup generation" % label)
	_expect_eq(_file_hash(_slot_backup_path(1)), initial_hash, "%s backup should retain pre-operation bytes" % label)
	var saved := _read_json(_slot_save_path(1))
	_expect(PlayerProgress._is_valid_save_candidate(saved), "%s main should remain a valid SAVE-03 candidate" % label)
	_expect(not FileAccess.file_exists(_slot_tmp_path(1)), "%s should not leave a tmp file" % label)


func _verify_fallback_lifecycle() -> void:
	_remove_all_save_files()
	PlayerProgress.set_active_save_slot(1, false)
	var invalid_main := {"version": 1, "money": -1}
	var valid_backup := {"version": 1, "level": 12, "money": 2468}
	_write_text(_slot_save_path(1), JSON.stringify(invalid_main, "\t"))
	_write_text(_slot_backup_path(1), JSON.stringify(valid_backup, "\t"))
	PlayerProgress.load_game()
	_expect_eq(PlayerProgress.money, 2468, "fallback lifecycle should load backup")
	var valid_backup_hash := _file_hash(_slot_backup_path(1))

	# 不正main削除後のrename失敗実経路では、backupをmainへcopy復元する。
	PlayerProgress._save_failure_injection_stage = "fallback_final_rename_after_remove"
	_expect(not PlayerProgress.save_game(), "post-remove fallback final rename failure should return false")
	PlayerProgress._save_failure_injection_stage = ""
	_expect_eq(_file_hash(_slot_backup_path(1)), valid_backup_hash, "post-remove failure preserves valid backup")
	_expect_eq(_file_hash(_slot_save_path(1)), valid_backup_hash, "post-remove failure restores valid backup to main")
	_expect(not FileAccess.file_exists(_slot_tmp_path(1)), "post-remove failure cleans tmp")

	# fallbackからの通常save成功は新mainと旧正常backupの2世代を残す。
	_write_text(_slot_save_path(1), JSON.stringify(invalid_main, "\t"))
	PlayerProgress.load_game()
	PlayerProgress.money = 3579
	_expect(PlayerProgress.save_game(), "fallback normal save should succeed")
	_expect_eq(int(_read_json(_slot_save_path(1)).get("money", -1)), 3579, "fallback save writes new valid main")
	_expect_eq(_file_hash(_slot_backup_path(1)), valid_backup_hash, "fallback save keeps old valid backup")

	# main消失＋valid backup＋tmp残置のクラッシュ相当から再ロード・次回saveで復旧する。
	_remove_if_exists(_slot_save_path(1))
	_write_text(_slot_tmp_path(1), JSON.stringify({"version": 1, "money": 9999}, "\t"))
	PlayerProgress.money = 0
	PlayerProgress.load_game()
	_expect_eq(PlayerProgress.money, 2468, "missing main crash state should reload valid backup")
	PlayerProgress.money = 4680
	_expect(PlayerProgress.save_game(), "save after missing-main crash state should recover")
	_expect_eq(int(_read_json(_slot_save_path(1)).get("money", -1)), 4680, "crash recovery should create valid main")
	_expect_eq(_file_hash(_slot_backup_path(1)), valid_backup_hash, "crash recovery should retain valid backup")
	_expect(not FileAccess.file_exists(_slot_tmp_path(1)), "crash recovery should replace stale tmp")
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
		_expect_eq(int(summary.get("money", -1)), 500, "%s summary should use default money" % label)
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


func _expect_future_slot_hashes(expected_hashes: Dictionary, message: String) -> void:
	_expect_slot_artifact_hashes(1, expected_hashes, message)


func _slot_artifact_hashes(slot_id: int) -> Dictionary:
	return {
		"main": _file_hash(_slot_save_path(slot_id)),
		"backup": _file_hash(_slot_backup_path(slot_id)),
		"tmp": _file_hash(_slot_tmp_path(slot_id)),
	}


func _expect_slot_artifact_hashes(
	slot_id: int, expected_hashes: Dictionary, message: String
) -> void:
	_expect_eq(
		_file_hash(_slot_save_path(slot_id)),
		String(expected_hashes.get("main", "")),
		"%s (main)" % message
	)
	_expect_eq(
		_file_hash(_slot_backup_path(slot_id)),
		String(expected_hashes.get("backup", "")),
		"%s (backup)" % message
	)
	_expect_eq(
		_file_hash(_slot_tmp_path(slot_id)),
		String(expected_hashes.get("tmp", "")),
		"%s (tmp)" % message
	)


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
