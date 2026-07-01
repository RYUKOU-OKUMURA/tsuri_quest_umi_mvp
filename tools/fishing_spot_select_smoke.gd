extends Node

const FishingSpotSelectScreenScript = preload("res://src/ui/fishing_spot_select_screen.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")

var _screen: Variant
var _navigated_to := ""
var _payload: Dictionary = {}
var _failed := false


func _ready() -> void:
	PlayerProgress.level = 1
	PlayerProgress.spot_caught_counts = {
		"harbor_pier": {"aji": 2, "iwashi": 1},
	}
	_screen = _make_screen()
	await get_tree().process_frame
	_expect(_screen._map_view != null, "map view should be present")
	_expect(_screen._footer_completion_value_label != null, "footer completion label should be present")
	_expect(_screen._footer_completion_value_label.text == "2 / 5", "footer completion should show aggregate unlocked progress")
	_verify_no_footer_spot_entries()
	_expect(_screen._completion_summary_text(GameData.get_fishing_spot("harbor_pier"), true, _screen._spot_completion_counts(GameData.get_fishing_spot("harbor_pier"))) == "記録 2/5 種", "spot completion summary should use spot-specific catches")
	_expect(_spot_card_buttons(_screen).is_empty(), "footer spot entries must not be selectable buttons")
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
	_verify_no_footer_spot_entries()
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
	_verify_no_footer_spot_entries()
	_screen._select_spot("outer_tide")
	_expect(_navigated_to == "fishing", "continued spot selection should navigate to fishing")
	_expect(bool(_payload.get("continue_trip", false)), "continued spot selection should keep continue_trip")
	var stats: Dictionary = _payload.get("trip_stats", {})
	_expect(String(stats.get("sentinel", "")) == "carried", "continued spot selection should carry trip_stats")
	PlayerProgress.record_catch("saba", 32.0, "outer_tide")
	var outer_counts: Dictionary = PlayerProgress.spot_caught_counts.get("outer_tide", {})
	_expect(int(outer_counts.get("saba", 0)) == 1, "record_catch should store spot-specific catch counts")

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


func _verify_no_footer_spot_entries() -> void:
	var entries := _spot_progress_entries(_screen)
	_expect(entries.is_empty(), "footer must not contain fishing spot ledger cells")


func _spot_progress_entries(root: Node) -> Array[Control]:
	var entries: Array[Control] = []
	_collect_spot_progress_entries(root, entries)
	return entries


func _collect_spot_progress_entries(node: Node, entries: Array[Control]) -> void:
	for child in node.get_children():
		if child is Control:
			var control := child as Control
			if bool(control.get_meta("spot_progress_entry", false)):
				entries.append(control)
		_collect_spot_progress_entries(child, entries)


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
