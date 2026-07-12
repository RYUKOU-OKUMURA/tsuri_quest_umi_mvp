extends Node

const SettingsScreenScript = preload("res://src/ui/settings_screen.gd")
const TitleScreenScript = preload("res://src/ui/title_screen.gd")
const HarborScreenScript = preload("res://src/ui/harbor_screen.gd")
const MainScript = preload("res://src/main.gd")
const ScreenBaseScript = preload("res://src/ui/screen_base.gd")
const CatchFanfareScript = preload("res://src/ui/components/catch_fanfare.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")
const BGM_FIXTURE := "res://assets/audio/opening_bgm.mp3"
const SE_FIXTURE := "res://assets/audio/逃げられた.mp3"

var _failed := false
var _route_id := ""
var _route_payload: Dictionary = {}


func _ready() -> void:
	_remove_settings_file()
	_verify_bus_layout()
	await _verify_player_bus_connections()
	await _verify_defaults_and_input_contract()
	await _verify_slider_bus_save_reload_restore()
	_verify_corruption_recovery()
	await _verify_title_and_harbor_routes()
	if _failed:
		get_tree().quit(1)
		return
	print("settings_smoke: ok")
	get_tree().quit(0)


func _verify_bus_layout() -> void:
	var bgm_index := AudioServer.get_bus_index(&"BGM")
	var se_index := AudioServer.get_bus_index(&"SE")
	_expect(bgm_index >= 0, "BGM bus should exist")
	_expect(se_index >= 0, "SE bus should exist")
	_expect(AudioServer.get_bus_send(bgm_index) == &"Master", "BGM bus should send to Master")
	_expect(AudioServer.get_bus_send(se_index) == &"Master", "SE bus should send to Master")


func _verify_player_bus_connections() -> void:
	var main := MainScript.new()
	add_child(main)
	await _settle()
	main.play_app_bgm(BGM_FIXTURE)
	_expect(main._app_bgm_player != null and main._app_bgm_player.bus == &"BGM", "main app BGM player should use BGM bus")
	main.stop_app_bgm()
	await _free_node(main)
	var base := ScreenBaseScript.new()
	add_child(base)
	await _settle()
	base.play_screen_bgm(BGM_FIXTURE)
	_expect(base._screen_bgm_player != null and base._screen_bgm_player.bus == &"BGM", "screen BGM player should use BGM bus")
	base.play_screen_sfx(SE_FIXTURE)
	var sfx_player := base.get_node_or_null("ScreenSFXPlayer") as AudioStreamPlayer
	_expect(sfx_player != null and sfx_player.bus == &"SE", "screen SFX player should use SE bus")
	await _free_node(base)
	var fanfare := CatchFanfareScript.new()
	add_child(fanfare)
	await _settle()
	_expect(fanfare._audio_player != null and fanfare._audio_player.bus == &"SE", "catch fanfare should use SE bus")
	await _free_node(fanfare)


func _verify_defaults_and_input_contract() -> void:
	var screen: Variant = await _make_settings({"return_screen_id": "title"})
	_expect(int(screen._bgm_slider.value) == SettingsScreenScript.DEFAULT_BGM_VOLUME, "missing file should use default BGM")
	_expect(int(screen._se_slider.value) == SettingsScreenScript.DEFAULT_SE_VOLUME, "missing file should use default SE")
	_expect(screen._bgm_value_label.text == "80%", "default BGM percentage should be visible")
	_expect(screen._se_value_label.text == "80%", "default SE percentage should be visible")
	_expect(screen._return_button.text == "タイトルへ戻る", "title entry should restore title return label")
	_expect(screen._bgm_slider.focus_neighbor_bottom == screen._bgm_slider.get_path_to(screen._se_slider), "BGM focus should lead to SE")
	_expect(screen._se_slider.focus_neighbor_bottom == screen._se_slider.get_path_to(screen._return_button), "SE focus should lead to return")
	_expect(get_viewport().gui_get_focus_owner() == screen._bgm_slider, "BGM slider should own initial focus")
	var initial_bgm: float = screen._bgm_slider.value
	await _send_action("ui_right")
	_expect(screen._bgm_slider.value > initial_bgm, "ui_right should change the focused BGM slider")
	await _send_action("ui_down")
	_expect(get_viewport().gui_get_focus_owner() == screen._se_slider, "ui_down should move focus from BGM to SE")
	_reset_route()
	await _send_action("ui_cancel")
	_expect(_route_id == "title", "ui_cancel should return to title entry")
	_expect(screen.find_child("Fullscreen", true, false) == null, "fullscreen UI is outside this slice")
	_expect(screen.find_child("SlotDelete", true, false) == null, "slot delete UI is outside this slice")
	await _free_node(screen)


func _verify_slider_bus_save_reload_restore() -> void:
	var screen: Variant = await _make_settings({"return_screen_id": "harbor"})
	screen._bgm_slider.value = 35
	screen._se_slider.value = 0
	await get_tree().process_frame
	var bgm_index := AudioServer.get_bus_index(&"BGM")
	var se_index := AudioServer.get_bus_index(&"SE")
	_expect(not AudioServer.is_bus_mute(bgm_index), "positive BGM value should not mute bus")
	_expect(absf(db_to_linear(AudioServer.get_bus_volume_db(bgm_index)) - 0.35) < 0.01, "BGM slider should update BGM bus")
	_expect(AudioServer.is_bus_mute(se_index), "zero SE value should mute SE bus")
	var saved := SettingsScreenScript.load_settings()
	_expect(int(saved["bgm_volume"]) == 35 and int(saved["se_volume"]) == 0, "slider changes should persist")
	await _free_node(screen)
	var restored: Variant = await _make_settings({"return_screen_id": "harbor"})
	_expect(int(restored._bgm_slider.value) == 35, "recreated screen should restore BGM slider")
	_expect(int(restored._se_slider.value) == 0, "recreated screen should restore SE slider")
	_expect(restored._return_button.text == "港へ戻る", "harbor entry should restore harbor return label")
	await _free_node(restored)


func _verify_corruption_recovery() -> void:
	_write_raw("{ broken")
	var broken := SettingsScreenScript.load_settings()
	_expect(broken == SettingsScreenScript.default_settings(), "broken JSON should recover defaults")
	_write_raw(JSON.stringify({"version": 1, "bgm_volume": "loud", "se_volume": 200}))
	var invalid := SettingsScreenScript.load_settings()
	_expect(invalid == SettingsScreenScript.default_settings(), "invalid types and range should recover defaults")
	_write_raw(JSON.stringify({"version": {}, "bgm_volume": 40, "se_volume": 60}))
	var invalid_version := SettingsScreenScript.load_settings()
	_expect(invalid_version == SettingsScreenScript.default_settings(), "non-numeric version should recover defaults")
	_expect(FileAccess.file_exists(SettingsScreenScript.SETTINGS_PATH), "recovery should leave a normalized settings file")


func _verify_title_and_harbor_routes() -> void:
	var title := TitleScreenScript.new()
	title.theme = ThemeFactory.build_theme()
	title.navigate_requested.connect(_capture_route)
	add_child(title)
	await _settle()
	_expect(title._settings_button != null, "title should expose settings button")
	title._settings_button.grab_focus()
	await _send_action("ui_accept")
	_expect(_route_id == "settings" and String(_route_payload.get("return_screen_id", "")) == "title", "title route should carry title return payload")
	await _free_node(title)
	_reset_route()
	var harbor := HarborScreenScript.new()
	harbor.theme = ThemeFactory.build_theme()
	harbor.navigate_requested.connect(_capture_route)
	add_child(harbor)
	await _settle()
	_expect(harbor._settings_button != null, "harbor should expose settings button")
	harbor._settings_button.grab_focus()
	await _send_action("ui_accept")
	_expect(_route_id == "settings" and String(_route_payload.get("return_screen_id", "")) == "harbor", "harbor route should carry harbor return payload")
	await _free_node(harbor)


func _make_settings(payload: Dictionary) -> Variant:
	var screen := SettingsScreenScript.new()
	screen.theme = ThemeFactory.build_theme()
	screen.configure(payload)
	screen.navigate_requested.connect(_capture_route)
	add_child(screen)
	await _settle()
	return screen


func _capture_route(screen_id: String, payload: Dictionary) -> void:
	_route_id = screen_id
	_route_payload = payload.duplicate(true)


func _reset_route() -> void:
	_route_id = ""
	_route_payload.clear()


func _settle() -> void:
	await get_tree().process_frame


func _send_action(action: StringName) -> void:
	var pressed := InputEventAction.new()
	pressed.action = action
	pressed.pressed = true
	Input.parse_input_event(pressed)
	await get_tree().process_frame
	var released := InputEventAction.new()
	released.action = action
	released.pressed = false
	Input.parse_input_event(released)
	await get_tree().process_frame
	await get_tree().process_frame


func _free_node(node: Node) -> void:
	node.queue_free()
	await get_tree().process_frame


func _remove_settings_file() -> void:
	if FileAccess.file_exists(SettingsScreenScript.SETTINGS_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SettingsScreenScript.SETTINGS_PATH))


func _write_raw(text: String) -> void:
	var file := FileAccess.open(SettingsScreenScript.SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		_expect(false, "settings fixture should be writable")
		return
	file.store_string(text)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("settings_smoke: %s" % message)
