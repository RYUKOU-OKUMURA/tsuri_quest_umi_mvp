extends Node

const CLEAN_SAVE_MONEY := 4242
const MIGRATED_SAVE_MONEY := 731
const TITLE_READY_TIMEOUT_MSEC := 5000
const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const TITLE_SCRIPT_PATH := "res://src/ui/title_screen.gd"
const VALID_PHASES := ["create", "reload", "migration"]


func _enter_tree() -> void:
	var phase := _phase()
	if name != "ExportLaunchPreflight" or phase.is_empty():
		return
	var expected := _expected_user_data_dir().simplify_path()
	var actual := OS.get_user_data_dir().simplify_path()
	if phase not in VALID_PHASES or expected.is_empty() or actual != expected:
		# PlayerProgressより前のautoloadでsandboxを立て、migration/saveの書込を防ぐ。
		OS.set_environment("TSURI_QA_SANDBOX", "1")
		OS.set_environment("TSURI_EXPORT_PREFLIGHT_FAILED", "1")
		push_error(
			"EXPORT_LAUNCH_PREFLIGHT_FAILED: phase=%s expected=%s actual=%s"
			% [phase, expected, actual]
		)
		get_tree().quit(73)


func _ready() -> void:
	if name == "ExportLaunchPreflight":
		return
	if OS.get_environment("TSURI_EXPORT_PREFLIGHT_FAILED") == "1":
		return
	if _phase().is_empty():
		return
	_run_smoke.call_deferred()


func _run_smoke() -> void:
	var phase := _phase()
	if not _expect_user_data_dir():
		return
	if not await _wait_for_title_ready():
		return
	match phase:
		"create":
			_run_create()
		"reload":
			_run_reload(CLEAN_SAVE_MONEY)
		"migration":
			_run_reload(MIGRATED_SAVE_MONEY)
		_:
			_fail("unknown phase: %s" % phase)


func _phase() -> String:
	return _user_argument("--tsuri-export-smoke=")


func _expected_user_data_dir() -> String:
	return _user_argument("--tsuri-expected-user-dir=")


func _user_argument(prefix: String) -> String:
	for arg_variant in OS.get_cmdline_user_args():
		var arg := String(arg_variant)
		if arg.begins_with(prefix):
			return arg.trim_prefix(prefix)
	return ""


func _expect_user_data_dir() -> bool:
	var expected := _expected_user_data_dir().simplify_path()
	var actual := OS.get_user_data_dir().simplify_path()
	if expected.is_empty():
		_fail("expected user data dir was not supplied")
		return false
	if actual != expected:
		_fail("unexpected user data dir: expected=%s actual=%s" % [expected, actual])
		return false
	return true


func _wait_for_title_ready() -> bool:
	var deadline := Time.get_ticks_msec() + TITLE_READY_TIMEOUT_MSEC
	while Time.get_ticks_msec() < deadline:
		var current_scene := get_tree().current_scene
		if current_scene != null:
			if current_scene.scene_file_path != MAIN_SCENE_PATH:
				_fail("unexpected main scene: %s" % current_scene.scene_file_path)
				return false
			var current_screen = current_scene.get("_current_screen")
			if current_screen != null and is_instance_valid(current_screen):
				var script := current_screen.get_script() as Script
				if script != null and script.resource_path == TITLE_SCRIPT_PATH and current_screen.is_node_ready():
					return true
		await get_tree().process_frame
	_fail("title did not become ready within %d ms" % TITLE_READY_TIMEOUT_MSEC)
	return false


func _run_create() -> void:
	if PlayerProgress.has_save_file(1):
		_fail("clean phase unexpectedly found a save")
		return
	PlayerProgress.set_active_save_slot(1, false)
	PlayerProgress.reset_game()
	PlayerProgress.money = CLEAN_SAVE_MONEY
	if not PlayerProgress.save_game():
		_fail("save_game failed")
		return
	if not FileAccess.file_exists(PlayerProgress.current_save_path()):
		_fail("new save was not created")
		return
	_pass("create")


func _run_reload(expected_money: int) -> void:
	if PlayerProgress.is_save_storage_blocked():
		_fail(PlayerProgress.save_storage_block_message())
		return
	if not PlayerProgress.has_save_file(1):
		_fail("slot 1 save is missing")
		return
	if not PlayerProgress.set_active_save_slot(1):
		_fail("slot 1 could not be loaded")
		return
	if PlayerProgress.money != expected_money:
		_fail("money mismatch: expected=%d actual=%d" % [expected_money, PlayerProgress.money])
		return
	_pass("reload" if expected_money == CLEAN_SAVE_MONEY else "migration")


func _pass(phase: String) -> void:
	print("EXPORT_LAUNCH_SMOKE_OK phase=%s title=ready user_dir=%s" % [phase, OS.get_user_data_dir()])
	await get_tree().process_frame
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error("EXPORT_LAUNCH_SMOKE_FAILED: %s" % message)
	await get_tree().process_frame
	get_tree().quit(1)
