extends Node

const FishingSpotSelectScreenScript = preload("res://src/ui/fishing_spot_select_screen.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")

var _screen: Variant
var _navigated_to := ""
var _payload: Dictionary = {}
var _failed := false


func _ready() -> void:
	PlayerProgress.level = 1
	_screen = _make_screen()
	await get_tree().process_frame
	_expect(_screen._map_view != null, "map view should be present")
	_verify_card_locks(8, 7)
	_screen._select_spot("deep_ocean")
	_expect(_navigated_to.is_empty(), "locked spot must not navigate")
	_screen._select_spot(GameData.DEFAULT_FISHING_SPOT_ID)
	_expect(_navigated_to == "fishing", "unlocked default spot should navigate to fishing")
	_expect(String(_payload.get("spot_id", "")) == GameData.DEFAULT_FISHING_SPOT_ID, "default spot payload mismatch")

	_screen.queue_free()
	await get_tree().process_frame

	_navigated_to = ""
	_payload = {}
	PlayerProgress.level = GameData.BOSS_UNLOCK_LEVEL
	_screen = _make_screen()
	await get_tree().process_frame
	_verify_card_locks(8, 2)
	_screen._select_spot(GameData.BOSS_FISHING_SPOT_ID)
	_expect(_navigated_to == "fishing", "boss spot should navigate when unlocked")
	_expect(String(_payload.get("spot_id", "")) == GameData.BOSS_FISHING_SPOT_ID, "boss spot payload mismatch")

	_screen.queue_free()
	await get_tree().process_frame

	_navigated_to = ""
	_payload = {}
	PlayerProgress.level = 3
	_screen = _make_screen({
		"from_fishing": true,
		"current_spot_id": "outer_tide",
		"trip_stats": {"sentinel": "carried", "max_energy": 123.0},
	})
	await get_tree().process_frame
	_expect(_screen._selected_spot_id == "outer_tide", "current fishing spot should be selected")
	_screen._select_spot("outer_tide")
	_expect(_navigated_to == "fishing", "continued spot selection should navigate to fishing")
	_expect(bool(_payload.get("continue_trip", false)), "continued spot selection should keep continue_trip")
	var stats: Dictionary = _payload.get("trip_stats", {})
	_expect(String(stats.get("sentinel", "")) == "carried", "continued spot selection should carry trip_stats")

	if _failed:
		return
	print("fishing_spot_select_smoke: ok")
	get_tree().quit(0)


func _make_screen(payload: Dictionary = {}) -> Control:
	var screen := FishingSpotSelectScreenScript.new()
	screen.theme = ThemeFactory.build_theme()
	screen.configure(payload)
	screen.size = Vector2(1280.0, 720.0)
	screen.navigate_requested.connect(
		func(screen_id: String, payload: Dictionary) -> void:
			_navigated_to = screen_id
			_payload = payload.duplicate(true)
	)
	add_child(screen)
	return screen


func _verify_card_locks(expected_cards: int, expected_locked: int) -> void:
	var buttons := _spot_card_buttons(_screen)
	_expect(buttons.size() == expected_cards, "spot card count mismatch: expected %d got %d" % [expected_cards, buttons.size()])
	var locked := 0
	for button in buttons:
		if button.disabled:
			locked += 1
	_expect(locked == expected_locked, "locked card count mismatch: expected %d got %d" % [expected_locked, locked])


func _spot_card_buttons(root: Node) -> Array[Button]:
	var buttons: Array[Button] = []
	_collect_spot_buttons(root, buttons)
	return buttons


func _collect_spot_buttons(node: Node, buttons: Array[Button]) -> void:
	for child in node.get_children():
		if child is Button:
			var button := child as Button
			if bool(button.get_meta("spot_card", false)):
				buttons.append(button)
		_collect_spot_buttons(child, buttons)


func _expect(condition: bool, message: String) -> void:
	if condition or _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
