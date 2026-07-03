extends Node

const CatchFanfareScript = preload("res://src/ui/components/catch_fanfare.gd")
const FishingScreenScript = preload("res://src/ui/fishing_screen.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")

var _failed := false
var _continue_count := 0
var _harbor_count := 0


func _ready() -> void:
	var fanfare := CatchFanfareScript.new()
	fanfare.theme = ThemeFactory.build_theme()
	fanfare.size = Vector2(1280.0, 720.0)
	fanfare.continue_requested.connect(func() -> void: _continue_count += 1)
	fanfare.harbor_requested.connect(func() -> void: _harbor_count += 1)
	add_child(fanfare)
	await get_tree().process_frame

	var boss := GameData.get_fish("boss_kurodai")
	fanfare.play(boss, 48.2, {
		"first_catch": true,
		"boss_first_clear_reward": {"money": 3000},
	})
	_expect(fanfare.visible, "fanfare should be visible after play")
	_expect(fanfare.is_playing(), "fanfare should report playing after play")
	await get_tree().create_timer(3.15).timeout
	_expect(_continue_count == 0, "fanfare should not auto-continue")
	_expect(_harbor_count == 0, "fanfare should not auto-request harbor")
	_expect(fanfare.visible, "fanfare should stay visible until the player chooses")
	_expect(fanfare.is_playing(), "fanfare should keep blocking the simulation while visible")

	fanfare.play(GameData.get_fish("aji"), 18.3, {})
	await get_tree().process_frame
	_expect(fanfare.is_playing(), "fanfare should restart")
	fanfare.skip()
	await get_tree().process_frame
	_expect(_continue_count == 1, "skip compatibility should request continue once")
	_expect(not fanfare.visible, "fanfare should hide after continue")
	_expect(not fanfare.is_playing(), "fanfare should stop after continue")

	fanfare.play(GameData.get_fish("aji"), 22.6, {})
	await get_tree().process_frame
	fanfare._request_harbor()
	await get_tree().process_frame
	_expect(_harbor_count == 1, "harbor action should emit once")
	_expect(not fanfare.visible, "fanfare should hide after harbor request")
	_expect(not fanfare.is_playing(), "fanfare should stop after harbor request")
	fanfare.queue_free()
	await get_tree().process_frame

	await _verify_fishing_screen_result_flow()

	if _failed:
		return
	print("catch_fanfare_smoke: ok")
	get_tree().quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition or _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)


func _verify_fishing_screen_result_flow() -> void:
	var screen := FishingScreenScript.new()
	screen.theme = ThemeFactory.build_theme()
	screen.configure({})
	screen.size = Vector2(1280.0, 720.0)
	add_child(screen)
	await get_tree().process_frame
	var fish := GameData.get_fish("aji")
	screen._current_fish = fish
	screen._simulator.result_size_cm = 18.3
	screen._on_fight_finished(true, "釣り上げ成功")
	_expect(screen._catch_fanfare.is_playing(), "caught fish should start catch fanfare")
	_expect(not screen._result_overlay.visible, "caught result overlay should stay hidden")
	await get_tree().create_timer(3.15).timeout
	_expect(screen._catch_fanfare.is_playing(), "caught result screen should not auto-close")
	_expect(not screen._result_overlay.visible, "caught result overlay should not appear after waiting")
	screen._catch_fanfare._request_continue()
	await get_tree().process_frame
	_expect(not screen._catch_fanfare.is_playing(), "continue should close catch result screen")
	_expect(not screen._result_overlay.visible, "continue should not show the old success overlay")
	_expect(screen._simulator.state == FishingSimulator.State.READY, "continue should prepare the next attempt")

	var navigation_events: Array[String] = []
	screen._current_fish = fish
	screen._simulator.result_size_cm = 19.4
	screen.navigate_requested.connect(func(screen_id: String, _payload: Dictionary) -> void: navigation_events.append(screen_id))
	screen._on_fight_finished(true, "釣り上げ成功")
	screen._catch_fanfare._request_harbor()
	await get_tree().process_frame
	_expect(navigation_events.size() == 1 and navigation_events[0] == "harbor", "harbor action should navigate without the old confirmation")

	screen._current_fish = fish
	screen._on_fight_finished(false, "ラインが切れた")
	_expect(screen._result_overlay.visible, "escaped result should still use the result overlay")
	_expect(screen._retry_button.text == "再挑戦", "escaped result should keep retry label")
	_expect(not screen._catch_fanfare.is_playing(), "escaped result should not start catch fanfare")
	screen.queue_free()
	await get_tree().process_frame
