extends Node

const MainScript = preload("res://src/main.gd")
const HarborScreen = preload("res://src/ui/harbor_screen.gd")
const MarketScreen = preload("res://src/ui/market_screen.gd")
const SettingsScreen = preload("res://src/ui/settings_screen.gd")
const TitleScreen = preload("res://src/ui/title_screen.gd")

const TRANSITION_TIMEOUT_SECONDS := 1.0

var _failed := false


class MainProbe:
	extends MainScript

	var swap_screen_ids: Array[String] = []
	var bgm_screen_ids: Array[String] = []

	func _swap(screen_id: String, payload: Dictionary) -> void:
		swap_screen_ids.append(screen_id)
		super._swap(screen_id, payload)

	func _update_bgm_for_screen(screen_id: String) -> void:
		bgm_screen_ids.append(screen_id)
		super._update_bgm_for_screen(screen_id)

	func clear_observations() -> void:
		swap_screen_ids.clear()
		bgm_screen_ids.clear()


func _ready() -> void:
	var main := MainProbe.new()
	main.size = Vector2(1280.0, 720.0)
	add_child(main)
	await _wait_for_transition(main, "初期タイトル遷移")
	_expect(main._current_screen != null and main._current_screen.get_script() == TitleScreen, "初期遷移はタイトルを表示する")
	_expect_transition_idle(main, "初期タイトル遷移")
	_expect_fade_frontmost(main, "初期タイトル遷移")

	main.clear_observations()
	main._show_screen("harbor")
	_expect_transition_active(main, "同一frame first request")
	main._show_screen("settings", {"return_screen_id": "title"})
	await _wait_for_swap(main, "同一frame first-wins")
	_expect_fade_frontmost(main, "同一frame swap後")
	await _wait_for_transition(main, "同一frame first-wins")
	_expect_single_transition(main, "harbor", HarborScreen, "同一frame first-wins")

	main.clear_observations()
	main._show_screen("market")
	_expect_transition_active(main, "fade中 first request")
	await get_tree().create_timer(0.06).timeout
	main._show_screen("settings", {"return_screen_id": "harbor"})
	await _wait_for_transition(main, "fade中 first-wins")
	_expect_single_transition(main, "market", MarketScreen, "fade中 first-wins")

	main.clear_observations()
	main._show_screen("unknown_screen")
	await _wait_for_transition(main, "未知ID fallback")
	_expect(main.swap_screen_ids == ["unknown_screen"], "未知IDでもswap要求は1回だけ処理する")
	_expect(main.bgm_screen_ids == ["harbor"], "未知IDはharborのBGM契約へfallbackする")
	_expect(main._current_screen != null and main._current_screen.get_script() == HarborScreen, "未知IDはharborへfallbackする")
	_expect_transition_idle(main, "未知ID fallback")
	_expect_fade_frontmost(main, "未知ID fallback")

	main.clear_observations()
	main._show_screen("settings", {"return_screen_id": "harbor"})
	_expect_transition_active(main, "破棄中遷移")
	remove_child(main)
	_expect(not main._transition_in_progress, "tree離脱時に遷移中状態を解除する")
	_expect(main._transition_tween == null, "tree離脱時に遷移tween参照を破棄する")
	_expect(main._fade.mouse_filter == Control.MOUSE_FILTER_IGNORE, "tree離脱時にfade入力遮断を解除する")
	main.queue_free()
	await get_tree().process_frame

	if _failed:
		get_tree().quit(1)
		return
	print("main_navigation_smoke: ok")
	get_tree().quit(0)


func _wait_for_swap(main: MainProbe, context: String) -> void:
	var started := Time.get_ticks_msec()
	while main.swap_screen_ids.is_empty():
		if float(Time.get_ticks_msec() - started) / 1000.0 > TRANSITION_TIMEOUT_SECONDS:
			_fail("%s: swapがtimeoutしました" % context)
			return
		await get_tree().process_frame


func _wait_for_transition(main: MainProbe, context: String) -> void:
	var started := Time.get_ticks_msec()
	while main._transition_in_progress:
		if float(Time.get_ticks_msec() - started) / 1000.0 > TRANSITION_TIMEOUT_SECONDS:
			_fail("%s: 遷移完了がtimeoutしました" % context)
			return
		await get_tree().process_frame


func _expect_single_transition(main: MainProbe, expected_id: String, expected_script: Script, context: String) -> void:
	_expect(main.swap_screen_ids == [expected_id], "%s: swapはfirst requestの1回だけ" % context)
	_expect(main.bgm_screen_ids == [expected_id], "%s: BGM更新は1回だけ" % context)
	_expect(main._current_screen != null and main._current_screen.get_script() == expected_script, "%s: first request画面を維持する" % context)
	_expect_transition_idle(main, context)
	_expect_fade_frontmost(main, context)


func _expect_transition_active(main: MainProbe, context: String) -> void:
	_expect(main._transition_in_progress, "%s: 遷移中状態を保持する" % context)
	_expect(main._transition_tween != null, "%s: 遷移tweenを保持する" % context)
	_expect(main._fade.mouse_filter == Control.MOUSE_FILTER_STOP, "%s: fadeが入力を遮断する" % context)
	_expect_fade_frontmost(main, context)


func _expect_transition_idle(main: MainProbe, context: String) -> void:
	_expect(not main._transition_in_progress, "%s: 遷移中状態を解除する" % context)
	_expect(main._transition_tween == null, "%s: 完了後にtween参照を破棄する" % context)
	_expect(main._fade.mouse_filter == Control.MOUSE_FILTER_IGNORE, "%s: 完了後にfade入力を通す" % context)


func _expect_fade_frontmost(main: MainProbe, context: String) -> void:
	_expect(main._fade.get_index() == main.get_child_count() - 1, "%s: fadeを最前面childに維持する" % context)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_fail(message)


func _fail(message: String) -> void:
	_failed = true
	push_error(message)
