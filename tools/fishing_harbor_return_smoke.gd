extends Node

const FishingScreenScript = preload("res://src/ui/fishing_screen.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")

var _screen: Variant
var _navigated_to := ""
var _payload: Dictionary = {}
var _failed := false


func _ready() -> void:
	_screen = FishingScreenScript.new()
	_screen.theme = ThemeFactory.build_theme()
	_screen.configure({})
	_screen.size = Vector2(1280.0, 720.0)
	_screen.navigate_requested.connect(
		func(screen_id: String, payload: Dictionary) -> void:
			_navigated_to = screen_id
			_payload = payload.duplicate(true)
	)
	add_child(_screen)
	await get_tree().process_frame

	_verify_ready_returns_immediately()
	_verify_ready_spot_change_returns_immediately()
	_verify_casting_requires_confirmation()
	_verify_casting_spot_change_requires_confirmation()
	_verify_fight_uses_escape_confirmation()
	_verify_fight_spot_change_uses_escape_confirmation()
	_verify_keyboard_confirmation_flow()
	await _verify_continue_trip_does_not_consume_pending_buff()

	if _failed:
		return
	print("fishing_harbor_return_smoke: ok")
	get_tree().quit(0)


func _verify_ready_returns_immediately() -> void:
	_reset_attempt()
	_screen._request_harbor_return()
	_expect(_navigated_to == "harbor", "READY harbor return should navigate immediately")
	_expect(not _screen._quit_overlay.visible, "READY harbor return must not show confirmation")


func _verify_ready_spot_change_returns_immediately() -> void:
	_reset_attempt()
	_screen._request_spot_change()
	_expect(_navigated_to == "fishing_spots", "READY spot change should navigate to fishing_spots")
	_expect(not _screen._quit_overlay.visible, "READY spot change must not show confirmation")
	_expect(bool(_payload.get("from_fishing", false)), "spot change payload should mark from_fishing")
	_expect(String(_payload.get("current_spot_id", "")) == GameData.DEFAULT_FISHING_SPOT_ID, "spot change payload should carry current_spot_id")
	var stats: Dictionary = _payload.get("trip_stats", {})
	_expect(String(stats.get("spot_id", "")) == GameData.DEFAULT_FISHING_SPOT_ID, "spot change payload should carry trip_stats")


func _verify_casting_requires_confirmation() -> void:
	_reset_attempt()
	_expect(_screen._simulator.cast(), "cast should start the attempt")
	_screen._request_harbor_return()
	_expect(_screen._quit_overlay.visible, "CASTING harbor return should show confirmation")
	_expect(
		_screen._quit_details.text == "釣りを中断して港へ戻りますか？",
		"CASTING confirmation message should explain fishing interruption"
	)
	var state_before: int = _screen._simulator.state
	_screen._process(8.0)
	_expect(_screen._simulator.state == state_before, "confirmation overlay should pause fishing progress")
	_screen._hide_harbor_confirm()
	_expect(not _screen._quit_overlay.visible, "cancel should hide harbor confirmation")
	_expect(_screen._simulator.state == state_before, "cancel should preserve fishing state")


func _verify_casting_spot_change_requires_confirmation() -> void:
	_reset_attempt()
	_expect(_screen._simulator.cast(), "cast should start spot-change attempt")
	_screen._request_spot_change()
	_expect(_screen._quit_overlay.visible, "CASTING spot change should show confirmation")
	_expect(_screen._quit_title.text == "釣り場を変える", "spot change confirmation title mismatch")
	_expect(
		_screen._quit_details.text == "釣りを中断して釣り場を変えますか？",
		"CASTING spot change confirmation message should explain interruption"
	)
	_navigated_to = ""
	_payload = {}
	_screen._confirm_quit_action()
	_expect(_navigated_to == "fishing_spots", "confirmed spot change should navigate to fishing_spots")
	_expect(bool(_payload.get("from_fishing", false)), "confirmed spot change should carry from_fishing")


func _verify_fight_uses_escape_confirmation() -> void:
	_reset_attempt()
	_expect(_screen._simulator.cast(), "cast should start the fight attempt")
	_advance_until_bite()
	_expect(_screen._simulator.hook(), "hook should enter FIGHT")
	_screen._request_harbor_return()
	_expect(_screen._quit_overlay.visible, "FIGHT harbor return should show confirmation")
	_expect(
		_screen._quit_details.text == "ファイトを中断すると魚は逃げます。港へ戻りますか？",
		"FIGHT confirmation message should explain the fish escapes"
	)


func _verify_fight_spot_change_uses_escape_confirmation() -> void:
	_reset_attempt()
	_expect(_screen._simulator.cast(), "cast should start spot-change fight attempt")
	_advance_until_bite()
	_expect(_screen._simulator.hook(), "hook should enter FIGHT for spot-change")
	_screen._request_spot_change()
	_expect(_screen._quit_overlay.visible, "FIGHT spot change should show confirmation")
	_expect(
		_screen._quit_details.text == "ファイトを中断すると魚は逃げます。釣り場を変えますか？",
		"FIGHT spot change confirmation should explain the fish escapes"
	)


func _verify_keyboard_confirmation_flow() -> void:
	_reset_attempt()
	_expect(_screen._simulator.cast(), "cast should start keyboard attempt")
	_press_key(KEY_MINUS)
	_expect(_screen._quit_overlay.visible, "minus key should open harbor confirmation")
	_press_key(KEY_ESCAPE)
	_expect(not _screen._quit_overlay.visible, "escape should cancel harbor confirmation")
	_press_key(KEY_ESCAPE)
	_expect(_screen._quit_overlay.visible, "escape key should open harbor confirmation outside the overlay")
	_navigated_to = ""
	_press_key(KEY_ENTER)
	_expect(_navigated_to == "harbor", "enter should confirm harbor return")


func _reset_attempt() -> void:
	_navigated_to = ""
	_payload = {}
	_screen._prepare_new_attempt()
	_screen._hide_harbor_confirm()


func _verify_continue_trip_does_not_consume_pending_buff() -> void:
	_screen.queue_free()
	await get_tree().process_frame

	var pending_buff := {
		"recipe_id": "salt_grill",
		"name": "テスト料理",
		"stat": "max_energy",
		"value": 0.50,
		"text": "次の釣行で最大体力 +50%",
	}
	PlayerProgress.pending_buff = pending_buff.duplicate(true)
	var carried_stats := {
		"sentinel": "carried",
		"level": PlayerProgress.level,
		"max_energy": 123.0,
		"reel_power": 5.6,
		"technique": 0,
		"focus": 0,
		"energy_regen": 14.0,
		"bite_window_bonus": 0.0,
		"safe_min": 0.22,
		"safe_max": 0.72,
		"line_break_limit": 1.0,
		"rod_name": "港の入門竿",
		"meal_buff": {"name": "既に適用済み"},
	}
	var continued := FishingScreenScript.new()
	continued.theme = ThemeFactory.build_theme()
	continued.configure({
		"spot_id": "outer_tide",
		"continue_trip": true,
		"trip_stats": carried_stats,
	})
	continued.size = Vector2(1280.0, 720.0)
	add_child(continued)
	await get_tree().process_frame
	_expect(
		String(continued._trip_stats.get("sentinel", "")) == "carried",
		"continued fishing screen should reuse carried trip_stats"
	)
	_expect(
		is_equal_approx(float(continued._trip_stats.get("max_energy", 0.0)), 123.0),
		"continued fishing screen should not recalculate stats"
	)
	_expect(
		String(continued._trip_stats.get("spot_id", "")) == "outer_tide",
		"continued fishing screen should update only selected spot data"
	)
	_expect(
		PlayerProgress.pending_buff == pending_buff,
		"continued fishing screen must not consume pending meal buff"
	)
	continued.queue_free()
	await get_tree().process_frame
	PlayerProgress.pending_buff = {}


func _advance_until_bite() -> void:
	for _index in range(90):
		_screen._simulator.tick(0.10)
		if _screen._simulator.state == FishingSimulator.State.BITE:
			return
	_expect(false, "simulator did not reach BITE")


func _press_key(keycode: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	_screen._input(event)


func _expect(condition: bool, message: String) -> void:
	if condition or _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
