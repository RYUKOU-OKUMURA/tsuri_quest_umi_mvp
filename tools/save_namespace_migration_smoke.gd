extends Node

const Migrator = preload("res://src/autoload/save_namespace_migrator.gd")
const PlayerProgressScript = preload("res://src/autoload/player_progress.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")
const TitleScreen = preload("res://src/ui/title_screen.gd")

# production helperから生成せず、移行契約の12 artifactをtest側で固定する。
const ARTIFACT_RELATIVE_PATHS: Array[String] = [
	"tsuri_quest_save.json",
	"tsuri_quest_save.json.bak",
	"tsuri_quest_save.json.tmp",
	"slots/1/tsuri_quest_save.json",
	"slots/1/tsuri_quest_save.json.bak",
	"slots/1/tsuri_quest_save.json.tmp",
	"slots/2/tsuri_quest_save.json",
	"slots/2/tsuri_quest_save.json.bak",
	"slots/2/tsuri_quest_save.json.tmp",
	"slots/3/tsuri_quest_save.json",
	"slots/3/tsuri_quest_save.json.bak",
	"slots/3/tsuri_quest_save.json.tmp",
]
const FILE_NAMES: Array[String] = [
	"tsuri_quest_save.json", "tsuri_quest_save.json.bak", "tsuri_quest_save.json.tmp"
]

var _failed := false


func _ready() -> void:
	_expect(PlayerProgress.is_sandbox_mode(), "tools scene should keep autoload save sandboxed")
	if OS.get_environment("TSURI_SAVE_MIGRATION_SMOKE_ALLOW") != "1":
		push_error("save_namespace_migration_smoke は専用verify経由で実行してください。")
		get_tree().quit(1)
		return
	_verify_three_slot_copy_and_root_precedence()
	_verify_root_copy_normalization_and_no_resurrection()
	_verify_root_normalization_failure_retry()
	_verify_nonempty_destination_skip()
	_verify_future_and_unknown_version_copy()
	_verify_in_progress_resume_from_literal_marker()
	_verify_artifact_io_failure_resume()
	_verify_mismatch_blocks_player_storage()
	_verify_source_change_before_complete()
	_verify_orphan_tmp_and_invalid_marker_block_storage()
	_verify_terminal_fast_path_skips_foreign_lock()
	_verify_lock_freshness_expiry_and_token_race()
	await _verify_title_storage_block_contract()
	_cleanup()
	if _failed:
		return
	print("save_namespace_migration_smoke: ok")
	get_tree().quit(0)


func _verify_three_slot_copy_and_root_precedence() -> void:
	_cleanup()
	var expected := {}
	for relative_path in ARTIFACT_RELATIVE_PATHS.slice(3):
		var text := JSON.stringify(
			{"version": 1, "money": 100 + ARTIFACT_RELATIVE_PATHS.find(relative_path), "path": relative_path}
		)
		_write(_old_path(relative_path), text)
		expected[relative_path] = _hash(_old_path(relative_path))
	_write(_old_path(FILE_NAMES[0]), JSON.stringify({"version": 1, "money": 9999}))
	var ignored_root_hash := _hash(_old_path(FILE_NAMES[0]))
	_expect(bool(Migrator.new().run().get("ok", false)), "three-slot namespace copy should succeed")
	_expect_eq(String(_marker().get("state", "")), "complete", "three-slot marker state")
	for relative_path_variant in expected:
		var relative_path := String(relative_path_variant)
		_expect_eq(_hash(_new_path(relative_path)), expected[relative_path], "copied hash %s" % relative_path)
		_expect_eq(_hash(_old_path(relative_path)), expected[relative_path], "source hash %s" % relative_path)
	_expect_eq(_hash(_old_path(FILE_NAMES[0])), ignored_root_hash, "slot 1 should preserve duplicate old root")
	_expect(not FileAccess.file_exists(_new_path(FILE_NAMES[0])), "slot 1 should exclude duplicate root main")


func _verify_root_copy_normalization_and_no_resurrection() -> void:
	_cleanup()
	var expected := {}
	for file_name in FILE_NAMES:
		_write(_old_path(file_name), JSON.stringify({"version": 1, "level": 6, "money": 606, "file": file_name}))
		expected[file_name] = _hash(_old_path(file_name))
	_expect(bool(Migrator.new().run().get("ok", false)), "root copy should succeed")
	for file_name_variant in expected:
		var file_name := String(file_name_variant)
		_expect_eq(_hash(_new_path("slots/1/%s" % file_name)), expected[file_name], "root should normalize")
		_expect_eq(_hash(_old_path(file_name)), expected[file_name], "old root should remain")
		_remove(_new_path("slots/1/%s" % file_name))
	_expect(bool(Migrator.new().run().get("ok", false)), "complete marker fast path should remain ready")
	for file_name in FILE_NAMES:
		_expect(
			not FileAccess.file_exists(_new_path("slots/1/%s" % file_name)),
			"complete marker should prevent root resurrection"
		)


func _verify_root_normalization_failure_retry() -> void:
	_cleanup()
	_write(_old_path(FILE_NAMES[0]), JSON.stringify({"version": 1, "money": 808}))
	var source_hash := _hash(_old_path(FILE_NAMES[0]))
	var failing := Migrator.new()
	failing.failure_injection_stage = "legacy_main_rename"
	_expect(not bool(failing.run().get("ok", true)), "root rename failure should fail migration")
	_expect_eq(String(_marker().get("state", "")), "copied", "rename failure should remain copied")
	_expect_eq(_hash(_new_path(FILE_NAMES[0])), source_hash, "failed normalization should keep copied root")
	_expect(not FileAccess.file_exists(_new_path("slots/1/%s" % FILE_NAMES[0])), "failed normalization no slot")
	_expect(bool(Migrator.new().run().get("ok", false)), "next run should retry root normalization")
	_expect_eq(String(_marker().get("state", "")), "complete", "retry should mark complete")
	_expect_eq(_hash(_new_path("slots/1/%s" % FILE_NAMES[0])), source_hash, "retry slot hash")


func _verify_nonempty_destination_skip() -> void:
	_cleanup()
	var relative_path := "slots/1/%s" % FILE_NAMES[0]
	_write(_old_path(relative_path), JSON.stringify({"version": 1, "money": 111}))
	_write(_new_path(relative_path), JSON.stringify({"version": 1, "money": 222}))
	var old_hash := _hash(_old_path(relative_path))
	var new_hash := _hash(_new_path(relative_path))
	_expect(bool(Migrator.new().run().get("ok", false)), "nonempty destination should safely skip")
	_expect_eq(String(_marker().get("state", "")), "skipped", "nonempty marker state")
	_expect_eq(String(_marker().get("reason", "")), "destination_nonempty", "nonempty skip reason")
	_expect_eq(_hash(_old_path(relative_path)), old_hash, "skip source hash")
	_expect_eq(_hash(_new_path(relative_path)), new_hash, "skip destination hash")
	_remove(_new_path(relative_path))
	_expect(bool(Migrator.new().run().get("ok", false)), "skipped marker should be terminal")
	_expect(not FileAccess.file_exists(_new_path(relative_path)), "skipped marker should prevent resurrection")


func _verify_future_and_unknown_version_copy() -> void:
	_cleanup()
	var fixtures := {
		"slots/1/%s" % FILE_NAMES[0]: {"version": 2, "future": "main"},
		"slots/1/%s" % FILE_NAMES[1]: {"version": "v2", "future": "backup"},
		"slots/1/%s" % FILE_NAMES[2]: {"version": 3, "future": "tmp"},
		"slots/2/%s" % FILE_NAMES[0]: {"version": {"major": 2}, "future": "unknown"},
	}
	var hashes := {}
	for relative_path_variant in fixtures:
		var relative_path := String(relative_path_variant)
		_write(_old_path(relative_path), JSON.stringify(fixtures[relative_path]))
		hashes[relative_path] = _hash(_old_path(relative_path))
	_expect(bool(Migrator.new().run().get("ok", false)), "future artifacts should byte-copy")
	var progress := PlayerProgressScript.new()
	progress._sandbox_mode = false
	progress._initialize_save_storage()
	_expect(progress._save_storage_ready, "future guard should not be a migration failure")
	_expect(progress.is_future_save_version_guarded(1), "future slot 1 should guard")
	_expect(progress.is_future_save_version_guarded(2), "unknown slot 2 should guard")
	_expect(not progress.save_game(), "future slot should refuse save")
	for relative_path_variant in hashes:
		var relative_path := String(relative_path_variant)
		_expect_eq(_hash(_old_path(relative_path)), hashes[relative_path], "future source hash")
		_expect_eq(_hash(_new_path(relative_path)), hashes[relative_path], "future destination hash")
	progress.free()


func _verify_in_progress_resume_from_literal_marker() -> void:
	_cleanup()
	var artifacts: Array[Dictionary] = []
	for slot_id in range(1, 4):
		var relative_path := "slots/%d/%s" % [slot_id, FILE_NAMES[0]]
		_write(_old_path(relative_path), JSON.stringify({"version": 1, "money": slot_id * 101}))
		artifacts.append({"relative_path": relative_path, "sha256": _hash(_old_path(relative_path))})
	# production marker builderを使わず、disk schemaをtest literalで固定する。
	_write(
		_new_path(Migrator.MARKER_FILE_NAME),
		JSON.stringify(
			{
				"migration_version": 1,
				"source_project_name": "釣りクエスト ～海釣り編～ MVP",
				"state": "in_progress",
				"reason": "",
				"artifacts": artifacts,
			},
			"\t"
		)
	)
	_copy(_old_path(artifacts[0]["relative_path"]), _new_path(artifacts[0]["relative_path"]))
	_copy(
		_old_path(artifacts[0]["relative_path"]),
		_new_path(artifacts[0]["relative_path"]) + Migrator.COPY_TMP_SUFFIX
	)
	_copy(
		_old_path(artifacts[1]["relative_path"]),
		_new_path(artifacts[1]["relative_path"]) + Migrator.COPY_TMP_SUFFIX
	)
	_expect(bool(Migrator.new().run().get("ok", false)), "literal in-progress marker should resume")
	_expect_eq(String(_marker().get("state", "")), "complete", "resumed marker complete")
	for artifact in artifacts:
		_expect_eq(_hash(_new_path(artifact["relative_path"])), artifact["sha256"], "resumed hash")
		_expect(
			not FileAccess.file_exists(_new_path(artifact["relative_path"]) + Migrator.COPY_TMP_SUFFIX),
			"resume should remove copy tmp"
		)


func _verify_artifact_io_failure_resume() -> void:
	var relative_path := "slots/1/%s" % FILE_NAMES[0]
	_cleanup()
	_write(_old_path(relative_path), JSON.stringify({"version": 1, "money": 303}))
	var copy_failure := Migrator.new()
	copy_failure.failure_injection_stage = "artifact_copy"
	_expect(not bool(copy_failure.run().get("ok", true)), "artifact copy failure should block")
	_expect_eq(String(_marker().get("state", "")), "in_progress", "copy failure marker")
	_expect(not FileAccess.file_exists(_new_path(relative_path)), "copy failure should not create final")
	_expect(bool(Migrator.new().run().get("ok", false)), "copy failure should resume next run")
	_expect_eq(_hash(_new_path(relative_path)), _hash(_old_path(relative_path)), "resumed copy hash")

	_cleanup()
	_write(_old_path(relative_path), JSON.stringify({"version": 1, "money": 404}))
	var rename_failure := Migrator.new()
	rename_failure.failure_injection_stage = "artifact_final_rename"
	_expect(not bool(rename_failure.run().get("ok", true)), "artifact final rename failure should block")
	_expect(not FileAccess.file_exists(_new_path(relative_path)), "rename failure should not create final")
	_expect(
		FileAccess.file_exists(_new_path(relative_path) + Migrator.COPY_TMP_SUFFIX),
		"rename failure should retain verified copy tmp"
	)
	_expect(bool(Migrator.new().run().get("ok", false)), "rename failure should resume from copy tmp")
	_expect_eq(_hash(_new_path(relative_path)), _hash(_old_path(relative_path)), "resumed rename hash")

	_cleanup()
	_write(_old_path(relative_path), JSON.stringify({"version": 1, "money": 505}))
	var artifact := {"relative_path": relative_path, "sha256": _hash(_old_path(relative_path))}
	_write(_new_path(Migrator.MARKER_FILE_NAME), JSON.stringify(_literal_marker([artifact])))
	_write(_new_path(relative_path) + Migrator.COPY_TMP_SUFFIX, "mismatched helper tmp")
	_expect(bool(Migrator.new().run().get("ok", false)), "mismatched helper tmp should be recopied")
	_expect_eq(_hash(_new_path(relative_path)), artifact["sha256"], "recopied mismatched tmp hash")


func _verify_mismatch_blocks_player_storage() -> void:
	_cleanup()
	var relative_path := "slots/1/%s" % FILE_NAMES[0]
	_write(_old_path(relative_path), JSON.stringify({"version": 1, "money": 313}))
	var artifact := {"relative_path": relative_path, "sha256": _hash(_old_path(relative_path))}
	_write(_new_path(Migrator.MARKER_FILE_NAME), JSON.stringify(_literal_marker([artifact])))
	_write(_new_path(relative_path), JSON.stringify({"version": 99, "money": 919}))
	var old_hash := _hash(_old_path(relative_path))
	var mismatch_hash := _hash(_new_path(relative_path))
	var progress := PlayerProgressScript.new()
	progress._sandbox_mode = false
	progress._initialize_save_storage()
	_expect(not progress._save_storage_ready, "destination mismatch should block PlayerProgress")
	_expect_eq(progress.money, 500, "blocked PlayerProgress should keep defaults")
	_expect(not progress.has_save_file(), "blocked PlayerProgress should hide partial save")
	_expect(not progress.is_future_save_version_guarded(), "blocked storage should hide partial future guard")
	_expect(not progress.save_game(), "blocked PlayerProgress should refuse save")
	_expect(not progress.reset_game(), "blocked PlayerProgress should refuse reset")
	_expect(not progress.set_active_save_slot(2), "blocked PlayerProgress should refuse slot")
	_expect_eq(_hash(_old_path(relative_path)), old_hash, "mismatch old hash")
	_expect_eq(_hash(_new_path(relative_path)), mismatch_hash, "mismatch new hash")
	progress.free()


func _verify_source_change_before_complete() -> void:
	_cleanup()
	var relative_path := "slots/1/%s" % FILE_NAMES[0]
	var original := JSON.stringify({"version": 1, "money": 616})
	_write(_old_path(relative_path), original)
	var original_hash := _hash(_old_path(relative_path))
	var migrator := Migrator.new()
	migrator.before_complete_test_hook = func() -> void:
		_write(_old_path(relative_path), JSON.stringify({"version": 1, "money": 717}))
	_expect(not bool(migrator.run().get("ok", true)), "source change before complete should fail")
	_expect_eq(String(_marker().get("state", "")), "in_progress", "source change marker stays in progress")
	_expect_eq(_hash(_new_path(relative_path)), original_hash, "verified copied generation remains")
	_write(_old_path(relative_path), original)
	_expect(bool(Migrator.new().run().get("ok", false)), "restored source should resume")
	_expect_eq(String(_marker().get("state", "")), "complete", "restored source complete")


func _verify_terminal_fast_path_skips_foreign_lock() -> void:
	_cleanup()
	var relative_path := "slots/1/%s" % FILE_NAMES[0]
	_write(_old_path(relative_path), JSON.stringify({"version": 1, "money": 838}))
	_expect(bool(Migrator.new().run().get("ok", false)), "fast-path fixture migration should complete")
	var lock_dir := _new_path(Migrator.LOCK_DIR_NAME)
	_expect(DirAccess.make_dir_absolute(lock_dir) == OK, "foreign lock dir fixture")
	_write(
		lock_dir.path_join(Migrator.LOCK_OWNER_FILE_NAME),
		JSON.stringify({"token": "fresh-foreign", "created_at": int(Time.get_unix_time_from_system())})
	)
	var owner_hash := _hash(lock_dir.path_join(Migrator.LOCK_OWNER_FILE_NAME))
	_expect(bool(Migrator.new().run().get("ok", false)), "terminal marker should not acquire lock")
	_expect_eq(_hash(lock_dir.path_join(Migrator.LOCK_OWNER_FILE_NAME)), owner_hash, "fast path leaves foreign lock")


func _verify_orphan_tmp_and_invalid_marker_block_storage() -> void:
	_cleanup()
	var relative_path := "slots/1/%s" % FILE_NAMES[0]
	_write(_old_path(relative_path), JSON.stringify({"version": 1, "money": 848}))
	_write(
		_new_path(relative_path) + Migrator.COPY_TMP_SUFFIX,
		JSON.stringify({"version": 1, "partial": true})
	)
	var orphan_progress := PlayerProgressScript.new()
	orphan_progress._sandbox_mode = false
	orphan_progress._initialize_save_storage()
	_expect(not orphan_progress._save_storage_ready, "orphan copy tmp should block storage")
	_expect(not orphan_progress.save_game(), "orphan copy tmp should block save")
	_expect(not orphan_progress.reset_game(), "orphan copy tmp should block reset")
	_expect(not orphan_progress.set_active_save_slot(2), "orphan copy tmp should block slot")
	_expect(not FileAccess.file_exists(_new_path(Migrator.MARKER_FILE_NAME)), "orphan tmp should not become skipped")
	orphan_progress.free()

	_cleanup()
	_write(
		_new_path(Migrator.MARKER_FILE_NAME),
		JSON.stringify(
			{
				"migration_version": 1,
				"source_project_name": "釣りクエスト ～海釣り編～ MVP",
				"state": "complete",
				"reason": "copied_and_normalized"
			}
		)
	)
	var invalid_progress := PlayerProgressScript.new()
	invalid_progress._sandbox_mode = false
	invalid_progress._initialize_save_storage()
	_expect(not invalid_progress._save_storage_ready, "complete marker without artifacts should block")
	_expect(not invalid_progress.save_game(), "invalid complete marker should block save")
	invalid_progress.free()

	_cleanup()
	_write(_old_path(relative_path), JSON.stringify({"version": 1, "money": 858}))
	var copied_artifact := {
		"relative_path": relative_path,
		"sha256": _hash(_old_path(relative_path)),
	}
	# copiedのreason不整合とdestination欠落を、terminal状態として信用しない。
	_write(
		_new_path(Migrator.MARKER_FILE_NAME),
		JSON.stringify(_literal_marker([copied_artifact], "copied"))
	)
	var invalid_copied := PlayerProgressScript.new()
	invalid_copied._sandbox_mode = false
	invalid_copied._initialize_save_storage()
	_expect(not invalid_copied._save_storage_ready, "copied marker with invalid reason should block")
	_expect(not FileAccess.file_exists(_new_path(relative_path)), "invalid copied marker should not invent final")
	invalid_copied.free()


func _verify_lock_freshness_expiry_and_token_race() -> void:
	_cleanup()
	var lock_dir := _new_path(Migrator.LOCK_DIR_NAME)
	_expect(DirAccess.make_dir_absolute(lock_dir) == OK, "owner-less lock fixture")
	_expect(not Migrator.new()._acquire_lock(), "fresh owner-less lock should block")
	_cleanup()
	_expect(DirAccess.make_dir_absolute(lock_dir) == OK, "fresh owner lock fixture")
	_write(
		lock_dir.path_join(Migrator.LOCK_OWNER_FILE_NAME),
		JSON.stringify({"token": "fresh", "created_at": int(Time.get_unix_time_from_system())})
	)
	_expect(not Migrator.new()._acquire_lock(), "fresh foreign owner should block without PID lookup")
	_cleanup()
	_expect(DirAccess.make_dir_absolute(lock_dir) == OK, "expired lock fixture")
	_write(
		lock_dir.path_join(Migrator.LOCK_OWNER_FILE_NAME),
		JSON.stringify(
			{"token": "expired", "created_at": int(Time.get_unix_time_from_system()) - 301}
		)
	)
	var recovery := Migrator.new()
	_expect(recovery._acquire_lock(), "expired lock should recover by age")
	recovery._release_lock()
	_expect(not DirAccess.dir_exists_absolute(lock_dir), "recovered lock should release")

	_expect(DirAccess.make_dir_absolute(lock_dir) == OK, "token race fixture")
	_write(
		lock_dir.path_join(Migrator.LOCK_OWNER_FILE_NAME),
		JSON.stringify({"token": "old", "created_at": int(Time.get_unix_time_from_system()) - 301})
	)
	var racer := Migrator.new()
	racer.before_stale_lock_remove_test_hook = func() -> void:
		_write(
			lock_dir.path_join(Migrator.LOCK_OWNER_FILE_NAME),
			JSON.stringify({"token": "new", "created_at": int(Time.get_unix_time_from_system())})
		)
	_expect(not racer._acquire_lock(), "owner token replacement should cancel stale removal")
	_expect_eq(String(_read(lock_dir.path_join(Migrator.LOCK_OWNER_FILE_NAME)).get("token", "")), "new", "new owner remains")


func _verify_title_storage_block_contract() -> void:
	PlayerProgress._save_storage_ready = false
	PlayerProgress._save_storage_block_message = "移行テスト: ゲームを再起動してください。"
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
	_expect(title._continue_button.disabled, "blocked title should disable continue")
	_expect(title._new_button.disabled, "blocked title should disable new game")
	_expect(title._new_button.text.contains("再起動"), "blocked title new button should explain restart")
	_expect(title._slot_status_label.text.contains("再起動"), "blocked title status should explain restart")
	for button in title._slot_buttons:
		_expect(button.disabled, "blocked title should disable every slot")
		_expect(button.text.contains("利用不可"), "blocked slot should not render as empty")
	var navigations: Array[String] = []
	title.navigate_requested.connect(func(screen_id: String, _payload: Dictionary) -> void: navigations.append(screen_id))
	title._on_new_game_pressed()
	_expect(navigations.is_empty(), "blocked title new game should not navigate")
	_expect(title._common_notification != null, "blocked title action should show persistent migration message")
	_expect(
		title._common_notification.text.contains("再起動"),
		"blocked title notification should request restart"
	)
	PlayerProgress._save_storage_ready = true
	PlayerProgress._save_storage_block_message = ""
	title._refresh_slot_ui()
	_expect(not title._new_button.disabled, "recovered empty title should enable new game")
	_expect(title._new_button.text == "ゲームを始める", "recovered title should restore new-game text")
	_expect(title._slot_status_label.text.contains("新しく始められます"), "recovered status should restore")
	for button in title._slot_buttons:
		_expect(not button.disabled, "recovered title should enable slots")
		_expect(button.text.contains("空き"), "recovered slot should render empty again")
	viewport.queue_free()
	await get_tree().process_frame


func _literal_marker(artifacts: Array, state := "in_progress") -> Dictionary:
	return {
		"migration_version": 1,
		"source_project_name": "釣りクエスト ～海釣り編～ MVP",
		"state": state,
		"reason": "",
		"artifacts": artifacts,
	}


func _old_root() -> String:
	return OS.get_data_dir().path_join("Godot/app_userdata/釣りクエスト ～海釣り編～ MVP")


func _old_path(relative_path: String) -> String:
	return _old_root().path_join(relative_path)


func _new_path(relative_path: String) -> String:
	return OS.get_user_data_dir().path_join(relative_path)


func _marker() -> Dictionary:
	return _read(_new_path(Migrator.MARKER_FILE_NAME))


func _cleanup() -> void:
	for relative_path in ARTIFACT_RELATIVE_PATHS:
		_remove(_old_path(relative_path))
		_remove(_new_path(relative_path))
		_remove(_new_path(relative_path) + Migrator.COPY_TMP_SUFFIX)
	_remove(_new_path(Migrator.MARKER_FILE_NAME))
	_remove(_new_path(Migrator.MARKER_TMP_FILE_NAME))
	var lock_dir := _new_path(Migrator.LOCK_DIR_NAME)
	_remove(lock_dir.path_join(Migrator.LOCK_OWNER_FILE_NAME))
	if DirAccess.dir_exists_absolute(lock_dir):
		DirAccess.remove_absolute(lock_dir)


func _write(path: String, text: String) -> void:
	var dir_err := DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	_expect(dir_err == OK or dir_err == ERR_ALREADY_EXISTS, "fixture dir: %s" % path)
	var file := FileAccess.open(path, FileAccess.WRITE)
	_expect(file != null, "fixture open: %s" % path)
	if file == null:
		return
	file.store_string(text)
	file.close()


func _copy(from_path: String, to_path: String) -> void:
	var dir_err := DirAccess.make_dir_recursive_absolute(to_path.get_base_dir())
	_expect(dir_err == OK or dir_err == ERR_ALREADY_EXISTS, "copy dir: %s" % to_path)
	_expect(DirAccess.copy_absolute(from_path, to_path) == OK, "copy fixture: %s" % to_path)


func _remove(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func _hash(path: String) -> String:
	return FileAccess.get_sha256(path)


func _read(path: String) -> Dictionary:
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
