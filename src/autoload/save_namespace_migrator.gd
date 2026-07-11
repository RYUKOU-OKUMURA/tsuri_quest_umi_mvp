extends RefCounted

## 旧MVPのGodot標準user data namespaceから、固定namespaceへsave artifactだけを移す。
## ゲーム進行状態は扱わず、copy/marker/hash/排他と旧root→slot 1正規化だけを担当する。

const LEGACY_PROJECT_NAME := "釣りクエスト ～海釣り編～ MVP"
const MARKER_FILE_NAME := "namespace_migration_v1.json"
const MARKER_TMP_FILE_NAME := "namespace_migration_v1.json.tmp"
const COPY_TMP_SUFFIX := ".namespace_migration.tmp"
const MARKER_VERSION := 1
const LOCK_DIR_NAME := "save_storage_v1.lock"
const LOCK_OWNER_FILE_NAME := "owner.json"
const LOCK_CREATION_GRACE_SECONDS := 10
const LOCK_MAX_AGE_SECONDS := 300

const DEFAULT_FAILURE_MESSAGE := (
	"旧版セーブの移行を完了できなかったため、セーブの読み書きを停止しました。ゲームを再起動してください。"
)
const BUSY_MESSAGE := "別のゲームプロセスがセーブを使用中です。少し待ってから再起動してください。"

var slot_count := 3
var default_slot := 1
var save_version := 1
var save_file_name := "tsuri_quest_save.json"
var backup_file_name := "tsuri_quest_save.json.bak"
var tmp_file_name := "tsuri_quest_save.json.tmp"

# migration専用smokeのfailure injection。通常実行では未設定。
var failure_injection_stage := ""
var before_complete_test_hook := Callable()
var before_stale_lock_remove_test_hook := Callable()

var _source_root := ""
var _destination_root := ""
var _lock_token := ""


func _init(config := {}) -> void:
	if typeof(config) != TYPE_DICTIONARY:
		return
	slot_count = int(config.get("slot_count", slot_count))
	default_slot = int(config.get("default_slot", default_slot))
	save_version = int(config.get("save_version", save_version))
	save_file_name = String(config.get("save_file_name", save_file_name))
	backup_file_name = String(config.get("backup_file_name", backup_file_name))
	tmp_file_name = String(config.get("tmp_file_name", tmp_file_name))


func run() -> Dictionary:
	_source_root = legacy_namespace_root()
	_destination_root = OS.get_user_data_dir()
	if _source_root.simplify_path() == _destination_root.simplify_path():
		if not _acquire_lock():
			return _result(false, BUSY_MESSAGE)
		var normalized := true
		if not _default_slot_is_future_guarded():
			normalized = _normalize_root_artifacts()
		_release_lock()
		return _result(normalized)

	if _terminal_fast_path_is_ready():
		return _result(true)
	if not _acquire_lock():
		return _result(false, BUSY_MESSAGE)

	var prepared := _prepare_namespace_copy_with_lock()
	if prepared and not _default_slot_is_future_guarded():
		prepared = _normalize_root_artifacts()
	if prepared:
		prepared = _finish_copied_marker_if_ready()
	_release_lock()
	return _result(prepared)


func _result(ok: bool, message := "") -> Dictionary:
	return {"ok": ok, "message": message if not message.is_empty() else DEFAULT_FAILURE_MESSAGE}


func _terminal_fast_path_is_ready() -> bool:
	if not FileAccess.file_exists(marker_path()):
		return false
	var marker := _read_dictionary(marker_path())
	if not _marker_is_valid(marker):
		return false
	var state := String(marker.get("state", ""))
	if state != "complete" and state != "skipped":
		return false
	return not _has_pending_root_normalization()


func _prepare_namespace_copy_with_lock() -> bool:
	var marker_result := _load_marker()
	if bool(marker_result.get("exists", false)):
		if not bool(marker_result.get("valid", false)):
			push_warning("旧namespace移行markerが不正なため、移行を停止します。")
			return false
		var marker: Dictionary = marker_result.get("data", {})
		var state := String(marker.get("state", ""))
		if state == "complete" or state == "skipped" or state == "copied":
			return true
		return _resume_copy(marker)

	var snapshot := source_snapshot()
	if not bool(snapshot.get("ok", false)):
		push_warning("旧namespaceのセーブを検査できないため、移行を停止します。")
		return false
	if _destination_has_artifact():
		return _store_marker(_marker_data("skipped", [], "destination_nonempty"))
	if _destination_has_copy_tmp():
		push_warning("移行markerのない一時コピーがあるため、移行を停止します。")
		return false

	var artifacts: Array = snapshot.get("artifacts", [])
	if artifacts.is_empty():
		return _store_marker(_marker_data("skipped", [], "source_empty"))
	var marker := _marker_data("in_progress", artifacts)
	if not _store_marker(marker):
		return false
	return _resume_copy(marker)


func _resume_copy(marker: Dictionary) -> bool:
	var marker_artifacts_result := _marker_artifacts(marker)
	if not bool(marker_artifacts_result.get("ok", false)):
		return false
	var expected: Array = marker_artifacts_result.get("artifacts", [])
	var current := source_snapshot()
	if not bool(current.get("ok", false)) or not _artifacts_match(
		expected, current.get("artifacts", [])
	):
		push_warning("旧namespaceのセーブが移行開始後に変化したため、移行を停止します。")
		return false

	var expected_by_path := _artifact_map(expected)
	for relative_path in artifact_relative_paths():
		var destination_path := _destination_root.path_join(relative_path)
		var copy_tmp_path := destination_path + COPY_TMP_SUFFIX
		if not expected_by_path.has(relative_path):
			if FileAccess.file_exists(destination_path) or FileAccess.file_exists(copy_tmp_path):
				return false
			continue
		var expected_hash := String(expected_by_path[relative_path])
		if FileAccess.file_exists(destination_path):
			if FileAccess.get_sha256(destination_path) != expected_hash:
				return false
			if FileAccess.file_exists(copy_tmp_path) and FileAccess.get_sha256(copy_tmp_path) != expected_hash:
				if DirAccess.remove_absolute(copy_tmp_path) != OK:
					return false
		elif FileAccess.file_exists(copy_tmp_path) and FileAccess.get_sha256(copy_tmp_path) != expected_hash:
			# helper専有tmpはsource/markerが一致する場合だけ破棄し、同じartifactを再copyする。
			if DirAccess.remove_absolute(copy_tmp_path) != OK:
				return false

	for artifact_variant in expected:
		var artifact: Dictionary = artifact_variant
		var relative_path := String(artifact.get("relative_path", ""))
		var expected_hash := String(artifact.get("sha256", ""))
		var source_path := _source_root.path_join(relative_path)
		var destination_path := _destination_root.path_join(relative_path)
		var copy_tmp_path := destination_path + COPY_TMP_SUFFIX
		if FileAccess.file_exists(destination_path):
			if FileAccess.get_sha256(destination_path) != expected_hash:
				return false
			if FileAccess.file_exists(copy_tmp_path) and DirAccess.remove_absolute(copy_tmp_path) != OK:
				return false
			continue
		var dir_err := DirAccess.make_dir_recursive_absolute(destination_path.get_base_dir())
		if dir_err != OK and dir_err != ERR_ALREADY_EXISTS:
			return false
		if not FileAccess.file_exists(copy_tmp_path):
			var copy_err := (
				ERR_CANT_CREATE
				if failure_injection_stage == "artifact_copy"
				else DirAccess.copy_absolute(source_path, copy_tmp_path)
			)
			if copy_err != OK:
				return false
		if FileAccess.get_sha256(copy_tmp_path) != expected_hash:
			return false
		if FileAccess.file_exists(destination_path):
			if FileAccess.get_sha256(destination_path) != expected_hash:
				return false
			if DirAccess.remove_absolute(copy_tmp_path) != OK:
				return false
			continue
		var rename_err := (
			ERR_CANT_CREATE
			if failure_injection_stage == "artifact_final_rename"
			else DirAccess.rename_absolute(copy_tmp_path, destination_path)
		)
		if rename_err != OK:
			return false
		if FileAccess.get_sha256(destination_path) != expected_hash:
			return false

	if before_complete_test_hook.is_valid():
		before_complete_test_hook.call()
	var final_snapshot := source_snapshot()
	if not bool(final_snapshot.get("ok", false)) or not _artifacts_match(
		expected, final_snapshot.get("artifacts", [])
	):
		return false
	var copied_marker := marker.duplicate(true)
	copied_marker["state"] = "copied"
	copied_marker["reason"] = "copied"
	return _store_marker(copied_marker)


func _finish_copied_marker_if_ready() -> bool:
	var marker_result := _load_marker()
	if not bool(marker_result.get("exists", false)) or not bool(marker_result.get("valid", false)):
		return false
	var marker: Dictionary = marker_result.get("data", {})
	if String(marker.get("state", "")) != "copied":
		return true
	# future guardでroot正規化を保留した場合はcopiedのまま次回再確認する。
	if _has_pending_root_normalization():
		return true
	marker["state"] = "complete"
	marker["reason"] = "copied_and_normalized"
	return _store_marker(marker)


func source_snapshot() -> Dictionary:
	var artifacts: Array[Dictionary] = []
	for slot_id in range(1, slot_count + 1):
		for file_name in file_names():
			var relative_path := "slots/%d/%s" % [slot_id, file_name]
			if not _append_source_artifact(artifacts, relative_path):
				return {"ok": false, "artifacts": []}
	for file_name in file_names():
		var root_relative_path := file_name
		var root_path := _source_root.path_join(file_name)
		var slot_path := _source_root.path_join("slots/%d/%s" % [default_slot, file_name])
		if FileAccess.file_exists(root_path) and not FileAccess.file_exists(slot_path):
			if not _append_source_artifact(artifacts, root_relative_path):
				return {"ok": false, "artifacts": []}
	return {"ok": true, "artifacts": artifacts}


func _append_source_artifact(artifacts: Array[Dictionary], relative_path: String) -> bool:
	var path := _source_root.path_join(relative_path)
	if not FileAccess.file_exists(path):
		return true
	var hash := FileAccess.get_sha256(path)
	if hash.is_empty():
		return false
	artifacts.append({"relative_path": relative_path, "sha256": hash})
	return true


func file_names() -> Array[String]:
	return [save_file_name, backup_file_name, tmp_file_name]


func artifact_relative_paths() -> Array[String]:
	var paths := file_names()
	for slot_id in range(1, slot_count + 1):
		for file_name in file_names():
			paths.append("slots/%d/%s" % [slot_id, file_name])
	return paths


func _destination_has_artifact() -> bool:
	for relative_path in artifact_relative_paths():
		if FileAccess.file_exists(_destination_root.path_join(relative_path)):
			return true
	return false


func _destination_has_copy_tmp() -> bool:
	for relative_path in artifact_relative_paths():
		if FileAccess.file_exists(_destination_root.path_join(relative_path) + COPY_TMP_SUFFIX):
			return true
	return false


func _marker_data(state: String, artifacts: Array, reason := "") -> Dictionary:
	return {
		"migration_version": MARKER_VERSION,
		"source_project_name": LEGACY_PROJECT_NAME,
		"state": state,
		"reason": reason,
		"artifacts": artifacts.duplicate(true),
	}


func _load_marker() -> Dictionary:
	var path := marker_path()
	if not FileAccess.file_exists(path):
		if not FileAccess.file_exists(marker_tmp_path()):
			return {"exists": false, "valid": false, "data": {}}
		path = marker_tmp_path()
	var marker := _read_dictionary(path)
	if not _marker_is_valid(marker):
		return {"exists": true, "valid": false, "data": marker}
	if path == marker_tmp_path() and DirAccess.rename_absolute(path, marker_path()) != OK:
		return {"exists": true, "valid": false, "data": marker}
	return {"exists": true, "valid": true, "data": marker}


func _marker_is_valid(marker: Dictionary) -> bool:
	var version = marker.get("migration_version", null)
	if typeof(version) != TYPE_INT and typeof(version) != TYPE_FLOAT:
		return false
	if float(version) != float(MARKER_VERSION):
		return false
	if String(marker.get("source_project_name", "")) != LEGACY_PROJECT_NAME:
		return false
	var state := String(marker.get("state", ""))
	var artifact_result := _marker_artifacts(marker)
	if not bool(artifact_result.get("ok", false)):
		return false
	var artifacts: Array = artifact_result.get("artifacts", [])
	if state == "skipped":
		return artifacts.is_empty() and String(marker.get("reason", "")) in [
			"destination_nonempty", "source_empty"
		]
	if artifacts.is_empty():
		return false
	var reason := String(marker.get("reason", ""))
	return (
		(state == "in_progress" and reason.is_empty())
		or (state == "copied" and reason == "copied")
		or (state == "complete" and reason == "copied_and_normalized")
	)


func _marker_artifacts(marker: Dictionary) -> Dictionary:
	var raw = marker.get("artifacts", null)
	if typeof(raw) != TYPE_ARRAY:
		return {"ok": false, "artifacts": []}
	var allowed := artifact_relative_paths()
	var seen := {}
	var artifacts: Array[Dictionary] = []
	for item in raw:
		if typeof(item) != TYPE_DICTIONARY:
			return {"ok": false, "artifacts": []}
		var relative_path := String(item.get("relative_path", ""))
		var hash := String(item.get("sha256", ""))
		if relative_path not in allowed or seen.has(relative_path) or not _is_sha256(hash):
			return {"ok": false, "artifacts": []}
		seen[relative_path] = true
		artifacts.append({"relative_path": relative_path, "sha256": hash})
	return {"ok": true, "artifacts": artifacts}


func _artifact_map(artifacts: Array) -> Dictionary:
	var result := {}
	for item in artifacts:
		result[String(item.get("relative_path", ""))] = String(item.get("sha256", ""))
	return result


func _artifacts_match(expected: Array, current: Array) -> bool:
	return expected.size() == current.size() and _artifact_map(expected) == _artifact_map(current)


func _is_sha256(value: String) -> bool:
	if value.length() != 64:
		return false
	for index in range(value.length()):
		var code := value.unicode_at(index)
		if not ((code >= 48 and code <= 57) or (code >= 97 and code <= 102)):
			return false
	return true


func _store_marker(marker: Dictionary) -> bool:
	if FileAccess.file_exists(marker_tmp_path()) and DirAccess.remove_absolute(marker_tmp_path()) != OK:
		return false
	var file := FileAccess.open(marker_tmp_path(), FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(marker, "\t"))
	var write_err := file.get_error()
	file.close()
	if write_err != OK:
		return false
	if FileAccess.file_exists(marker_path()) and DirAccess.remove_absolute(marker_path()) != OK:
		return false
	return DirAccess.rename_absolute(marker_tmp_path(), marker_path()) == OK


func _default_slot_is_future_guarded() -> bool:
	for path in _slot_artifact_paths(default_slot):
		var data := _read_dictionary(path)
		if not data.has("version"):
			continue
		var version = data["version"]
		if (typeof(version) != TYPE_INT and typeof(version) != TYPE_FLOAT) or float(version) > save_version:
			return true
	return false


func _normalize_root_artifacts() -> bool:
	var slot_dir := _destination_root.path_join("slots/%d" % default_slot)
	var dir_err := DirAccess.make_dir_recursive_absolute(slot_dir)
	if dir_err != OK and dir_err != ERR_ALREADY_EXISTS:
		return false
	var results: Array[bool] = []
	var injection_stages := ["legacy_main_rename", "legacy_backup_rename", "legacy_tmp_rename"]
	var names := file_names()
	for file_index in range(names.size()):
		var file_name := names[file_index]
		results.append(
			_move_root_artifact(
				_destination_root.path_join(file_name),
				slot_dir.path_join(file_name),
				String(injection_stages[file_index])
			)
		)
	return not false in results


func _move_root_artifact(from_path: String, to_path: String, injection_stage: String) -> bool:
	if not FileAccess.file_exists(from_path) or FileAccess.file_exists(to_path):
		return true
	var err := (
		ERR_CANT_CREATE
		if failure_injection_stage == injection_stage
		else DirAccess.rename_absolute(from_path, to_path)
	)
	return err == OK


func _has_pending_root_normalization() -> bool:
	for file_name in file_names():
		if FileAccess.file_exists(_destination_root.path_join(file_name)) and not FileAccess.file_exists(
			_destination_root.path_join("slots/%d/%s" % [default_slot, file_name])
		):
			return true
	return false


func _slot_artifact_paths(slot_id: int) -> Array[String]:
	var paths: Array[String] = []
	for file_name in file_names():
		paths.append(_destination_root.path_join("slots/%d/%s" % [slot_id, file_name]))
	return paths


func _acquire_lock() -> bool:
	if not _lock_token.is_empty():
		return false
	for _attempt in range(2):
		var err := DirAccess.make_dir_absolute(lock_dir())
		if err == OK:
			_lock_token = "%d:%d:%d" % [OS.get_process_id(), get_instance_id(), Time.get_ticks_usec()]
			var owner := {
				"token": _lock_token,
				"created_at": int(Time.get_unix_time_from_system()),
			}
			var file := FileAccess.open(lock_owner_path(), FileAccess.WRITE)
			if file == null:
				_cleanup_just_created_lock()
				return false
			file.store_string(JSON.stringify(owner, "\t"))
			var write_err := file.get_error()
			file.close()
			if write_err == OK:
				return true
			_cleanup_just_created_lock()
			return false
		if err != ERR_ALREADY_EXISTS or not _remove_stale_lock():
			return false
	return false


func _remove_stale_lock() -> bool:
	var first_owner := _read_dictionary(lock_owner_path())
	var first_token := String(first_owner.get("token", ""))
	var created_value = first_owner.get("created_at", null)
	var created_type := typeof(created_value)
	var created_at := int(created_value) if created_type == TYPE_INT or created_type == TYPE_FLOAT else 0
	var now := int(Time.get_unix_time_from_system())
	var owner_is_valid := not first_token.is_empty() and created_at > 0
	var base_time := created_at if owner_is_valid else int(FileAccess.get_modified_time(lock_dir()))
	if base_time <= 0:
		return false
	var age := now - base_time
	var threshold := LOCK_MAX_AGE_SECONDS if owner_is_valid else LOCK_CREATION_GRACE_SECONDS
	if age < threshold:
		return false
	if before_stale_lock_remove_test_hook.is_valid():
		before_stale_lock_remove_test_hook.call()
	var second_owner := _read_dictionary(lock_owner_path())
	if String(second_owner.get("token", "")) != first_token or int(
		second_owner.get("created_at", 0)
	) != created_at:
		return false
	var access := DirAccess.open(lock_dir())
	if access == null:
		return false
	access.list_dir_begin()
	var entry := access.get_next()
	while not entry.is_empty():
		if entry != LOCK_OWNER_FILE_NAME:
			access.list_dir_end()
			return false
		entry = access.get_next()
	access.list_dir_end()
	if FileAccess.file_exists(lock_owner_path()) and DirAccess.remove_absolute(lock_owner_path()) != OK:
		return false
	return DirAccess.remove_absolute(lock_dir()) == OK


func _release_lock() -> void:
	if _lock_token.is_empty():
		return
	var owner := _read_dictionary(lock_owner_path())
	if String(owner.get("token", "")) != _lock_token:
		_lock_token = ""
		return
	if DirAccess.remove_absolute(lock_owner_path()) == OK:
		DirAccess.remove_absolute(lock_dir())
	_lock_token = ""


func _cleanup_just_created_lock() -> void:
	if FileAccess.file_exists(lock_owner_path()):
		DirAccess.remove_absolute(lock_owner_path())
	DirAccess.remove_absolute(lock_dir())
	_lock_token = ""


func _read_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


func legacy_namespace_root() -> String:
	return OS.get_data_dir().path_join("Godot").path_join("app_userdata").path_join(
		LEGACY_PROJECT_NAME
	)


func marker_path() -> String:
	return OS.get_user_data_dir().path_join(MARKER_FILE_NAME)


func marker_tmp_path() -> String:
	return OS.get_user_data_dir().path_join(MARKER_TMP_FILE_NAME)


func lock_dir() -> String:
	return OS.get_user_data_dir().path_join(LOCK_DIR_NAME)


func lock_owner_path() -> String:
	return lock_dir().path_join(LOCK_OWNER_FILE_NAME)
