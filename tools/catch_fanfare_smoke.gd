extends Node

const CatchFanfareScript = preload("res://src/ui/components/catch_fanfare.gd")
const FishingScreenScript = preload("res://src/ui/fishing_screen.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")

var _failed := false
var _finished_count := 0


func _ready() -> void:
	var fanfare := CatchFanfareScript.new()
	fanfare.theme = ThemeFactory.build_theme()
	fanfare.size = Vector2(1280.0, 720.0)
	fanfare.finished.connect(func() -> void: _finished_count += 1)
	add_child(fanfare)
	await get_tree().process_frame

	var boss := GameData.get_fish("boss_kurodai")
	fanfare.play(boss, 48.2, {
		"first_catch": true,
		"boss_first_clear_reward": {"money": 3000},
	})
	_expect(fanfare.visible, "fanfare should be visible after play")
	_expect(fanfare.is_playing(), "fanfare should report playing after play")
	await get_tree().create_timer(CatchFanfareScript.AUTO_FINISH_SECONDS + 0.25).timeout
	_expect(_finished_count == 1, "fanfare should auto-finish once")
	_expect(not fanfare.visible, "fanfare should hide after auto-finish")
	_expect(not fanfare.is_playing(), "fanfare should stop playing after auto-finish")

	fanfare.play(GameData.get_fish("aji"), 18.3, {})
	await get_tree().process_frame
	_expect(fanfare.is_playing(), "fanfare should restart")
	fanfare.skip()
	await get_tree().process_frame
	_expect(_finished_count == 2, "skip should emit finished once")
	_expect(not fanfare.visible, "fanfare should hide after skip")
	_expect(not fanfare.is_playing(), "fanfare should stop after skip")
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
	_expect(not screen._result_overlay.visible, "result overlay should wait for fanfare")
	await get_tree().create_timer(CatchFanfareScript.AUTO_FINISH_SECONDS + 0.25).timeout
	_expect(screen._result_overlay.visible, "result overlay should show after fanfare")
	_expect(screen._retry_button.text == "続けて釣る", "caught result should keep continue label")
	screen.queue_free()
	await get_tree().process_frame
