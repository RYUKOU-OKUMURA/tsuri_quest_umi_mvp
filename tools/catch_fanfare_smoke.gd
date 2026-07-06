extends Node

const CatchFanfareScript = preload("res://src/ui/components/catch_fanfare.gd")
const FishingScreenScript = preload("res://src/ui/fishing_screen.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")

var _failed := false
var _continue_count := 0
var _harbor_count := 0


func _ready() -> void:
	_verify_record_catch_result()

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
		"new_titles": ["boss_kurodai"],
	})
	_expect(fanfare.visible, "fanfare should be visible after play")
	_expect(fanfare.is_playing(), "fanfare should report playing after play")
	_expect(fanfare._bonus_label.text.contains("撃破報酬"), "boss reward should be visible")
	_expect(fanfare._bonus_label.text.contains("大岩の覇者"), "new title should be visible")
	await get_tree().create_timer(3.15).timeout
	_expect(_continue_count == 0, "fanfare should not auto-continue")
	_expect(_harbor_count == 0, "fanfare should not auto-request harbor")
	_expect(fanfare.visible, "fanfare should stay visible until the player chooses")
	_expect(fanfare.is_playing(), "fanfare should keep blocking the simulation while visible")

	fanfare.play(GameData.get_fish("aji"), 24.5, {
		"record_broken": true,
		"previous_best_cm": 20.0,
		"new_titles": ["total_10", "species_10"],
	})
	await get_tree().process_frame
	_expect(fanfare._bonus_label.text.contains("自己記録更新！ 24.5 cm（+4.5 cm）"), "record line should be first-class fanfare text")
	_expect(fanfare._bonus_label.text.contains("駆け出し釣り人"), "first new title should be visible")
	_expect(fanfare._bonus_label.text.contains("図鑑の入り口"), "second new title should be visible")
	_expect(fanfare._record_badge_label.visible, "record marker should be visible near size")

	fanfare.play(GameData.get_fish("aji"), 18.3, {"first_catch": true})
	await get_tree().process_frame
	_expect(fanfare._bonus_label.text.contains("初回記録"), "first catch should keep book registration line")
	_expect(not fanfare._bonus_label.text.contains("自己記録更新"), "first catch should not be treated as record broken")

	fanfare.play(GameData.get_fish("aji"), 18.3, {})
	await get_tree().process_frame
	_expect(fanfare.is_playing(), "fanfare should restart")
	fanfare._request_continue()
	await get_tree().process_frame
	_expect(_continue_count == 1, "continue action should emit once")
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


func _verify_record_catch_result() -> void:
	PlayerProgress.inventory = {}
	PlayerProgress.caught_counts = {"aji": 9}
	PlayerProgress.spot_caught_counts = {"harbor_pier": {"aji": 9}}
	PlayerProgress.best_sizes = {"aji": 20.0}
	PlayerProgress.eaten_recipes = {}
	PlayerProgress._remember_current_titles()
	var emitted_title_ids: Array[String] = []
	PlayerProgress.titles_earned.connect(
		func(title_ids: Array[String]) -> void:
			for title_id in title_ids:
				emitted_title_ids.append(title_id)
	)
	var record_result := PlayerProgress.record_catch("aji", 21.0, "harbor_pier")
	_expect(bool(record_result.get("record_broken", false)), "repeat larger catch should break record")
	_expect(float(record_result.get("previous_best_cm", 0.0)) == 20.0, "record result should expose previous best")
	_expect(Array(record_result.get("new_titles", [])).has("total_10"), "record result should include newly earned total_10 title")
	_expect(emitted_title_ids.has("total_10"), "titles_earned signal should emit new title ids")

	PlayerProgress.inventory = {}
	PlayerProgress.caught_counts = {}
	PlayerProgress.spot_caught_counts = {}
	PlayerProgress.best_sizes = {}
	PlayerProgress.eaten_recipes = {}
	PlayerProgress._remember_current_titles()
	var first_result := PlayerProgress.record_catch("mejina", 31.0, "harbor_pier")
	_expect(bool(first_result.get("first_catch", false)), "first catch should be marked")
	_expect(not bool(first_result.get("record_broken", false)), "first catch should not break a record")


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
