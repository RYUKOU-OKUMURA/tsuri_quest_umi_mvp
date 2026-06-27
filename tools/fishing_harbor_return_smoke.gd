extends Node

const FishingScreenScript = preload("res://src/ui/fishing_screen.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")

var _screen: Variant
var _navigated_to := ""
var _failed := false


func _ready() -> void:
	_screen = FishingScreenScript.new()
	_screen.theme = ThemeFactory.build_theme()
	_screen.configure({})
	_screen.size = Vector2(1280.0, 720.0)
	_screen.navigate_requested.connect(func(screen_id: String, _payload: Dictionary) -> void: _navigated_to = screen_id)
	add_child(_screen)
	await get_tree().process_frame

	_verify_ready_returns_immediately()
	_verify_casting_requires_confirmation()
	_verify_fight_uses_escape_confirmation()
	_verify_keyboard_confirmation_flow()

	if _failed:
		return
	print("fishing_harbor_return_smoke: ok")
	get_tree().quit(0)


func _verify_ready_returns_immediately() -> void:
	_reset_attempt()
	_screen._request_harbor_return()
	_expect(_navigated_to == "harbor", "READY harbor return should navigate immediately")
	_expect(not _screen._quit_overlay.visible, "READY harbor return must not show confirmation")


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
	_screen._prepare_new_attempt()
	_screen._hide_harbor_confirm()


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
