extends Node

const FishingSpotSelectScreenScript = preload("res://src/ui/fishing_spot_select_screen.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")

var _screen: Variant
var _navigated_to := ""
var _payload: Dictionary = {}
var _failed := false


func _ready() -> void:
	_verify_old_save_rig_defaults()

	PlayerProgress.level = 1
	PlayerProgress.owned_boats = []
	PlayerProgress.sea_chart_fragments = 0
	PlayerProgress.owned_rigs = [GameData.DEFAULT_RIG_ID, "chokusen"]
	PlayerProgress.equipped_rig_id = GameData.DEFAULT_RIG_ID
	PlayerProgress.spot_caught_counts = {
		"harbor_pier": {"aji": 2, "mahaze": 1},
	}
	_screen = _make_screen()
	await get_tree().process_frame
	_expect(_screen._map_view != null, "map view should be present")
	_expect(_screen._screen_bgm_path == "res://assets/audio/港外・潮目.mp3", "default map BGM should use harbor tide track")
	_screen._focus_spot("shallow_sand")
	_expect(_screen._screen_bgm_path == "res://assets/audio/砂浜・かけあがり.mp3", "focused sand spot should switch map BGM")
	_expect(not _screen._detail_bait_value_label.text.contains("\n"), "bait detail should stay a single readable bait list")
	_expect(_screen._detail_rig_value_label.text.contains("ふつう"), "sabiki should show normal match in the rig row")
	_expect(not _screen._detail_rig_value_label.text.contains("アミエビ"), "rig detail should not duplicate bait list")
	_screen._cycle_owned_rig()
	_expect(PlayerProgress.equipped_rig_id == "chokusen", "rig cycle should equip next owned rig")
	_expect(_screen._detail_rig_value_label.text.contains("一致"), "chokusen should match shallow sand baits")
	_expect(_screen._footer_completion_value_label != null, "footer completion label should be present")
	var unlocked_completion: Dictionary = _screen._ledger_completion_counts()
	_expect(
		_screen._footer_completion_value_label.text == "%d / %d" % [
			int(unlocked_completion.get("caught", 0)),
			int(unlocked_completion.get("total", 0)),
		],
		"footer completion should show aggregate unlocked progress"
	)
	_verify_no_footer_spot_entries()
	var harbor_completion: Dictionary = _screen._spot_completion_counts(GameData.get_fishing_spot("harbor_pier"))
	_expect(
		_screen._completion_summary_text(GameData.get_fishing_spot("harbor_pier"), true, harbor_completion) == "記録 %d/%d 種" % [
			int(harbor_completion.get("caught", 0)),
			int(harbor_completion.get("total", 0)),
		],
		"spot completion summary should use spot-specific catches"
	)
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
	PlayerProgress.owned_boats = []
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
	PlayerProgress.level = 6
	PlayerProgress.owned_boats = []
	PlayerProgress.sea_chart_fragments = 0
	_screen = _make_screen()
	await get_tree().process_frame
	_screen._select_spot("bluewater_route")
	_expect(_navigated_to.is_empty(), "boat-locked offshore spot must not navigate")
	PlayerProgress.owned_boats = ["offshore_boat"]
	_screen._select_spot("bluewater_route")
	_expect(_navigated_to == "fishing", "offshore boat should allow bluewater route")
	_expect(String(_payload.get("spot_id", "")) == "bluewater_route", "bluewater route payload mismatch")

	_screen.queue_free()
	await get_tree().process_frame

	_navigated_to = ""
	_payload = {}
	PlayerProgress.level = 29
	PlayerProgress.owned_boats = ["bluewater_boat"]
	PlayerProgress.sea_chart_fragments = 3
	_screen = _make_screen()
	await get_tree().process_frame
	var danger_access := PlayerProgress.fishing_spot_access_status("danger_reef")
	_expect(String(danger_access.get("reason", "")) == "level", "danger reef should be level-locked below Lv.30")
	_screen._select_spot("danger_reef")
	_expect(_navigated_to.is_empty(), "level-locked danger reef must not navigate")

	PlayerProgress.level = 30
	PlayerProgress.owned_boats = []
	PlayerProgress.sea_chart_fragments = 3
	danger_access = PlayerProgress.fishing_spot_access_status("danger_reef")
	_expect(String(danger_access.get("reason", "")) == "boat", "danger reef should require rank 3 boat after level gate")

	PlayerProgress.owned_boats = ["bluewater_boat"]
	PlayerProgress.sea_chart_fragments = 2
	danger_access = PlayerProgress.fishing_spot_access_status("danger_reef")
	_expect(String(danger_access.get("reason", "")) == "chart", "danger reef should require completed sea chart")
	_expect(String(danger_access.get("message", "")).contains("断片 2/3"), "chart lock should show fragment progress")
	var accessible_spots := GameData.get_accessible_fishing_spot_ids(
		PlayerProgress.level,
		PlayerProgress.owned_boats,
		PlayerProgress.sea_chart_fragments
	)
	_expect(not accessible_spots.has("danger_reef"), "accessible spot helper should respect sea chart lock")
	_screen._select_spot("danger_reef")
	_expect(_navigated_to.is_empty(), "chart-locked danger reef must not navigate")

	PlayerProgress.sea_chart_fragments = 3
	accessible_spots = GameData.get_accessible_fishing_spot_ids(
		PlayerProgress.level,
		PlayerProgress.owned_boats,
		PlayerProgress.sea_chart_fragments
	)
	_expect(accessible_spots.has("danger_reef"), "accessible spot helper should include completed danger reef")
	_screen._select_spot("danger_reef")
	_expect(_navigated_to == "fishing", "completed sea chart should allow danger reef")
	_expect(String(_payload.get("spot_id", "")) == "danger_reef", "danger reef payload mismatch")

	_screen.queue_free()
	await get_tree().process_frame

	_navigated_to = ""
	_payload = {}
	PlayerProgress.level = 3
	PlayerProgress.owned_boats = []
	PlayerProgress.owned_rigs = [GameData.DEFAULT_RIG_ID, "chokusen"]
	PlayerProgress.equipped_rig_id = GameData.DEFAULT_RIG_ID
	_screen = _make_screen({
		"from_fishing": true,
		"current_spot_id": "outer_tide",
		"trip_stats": {"sentinel": "carried", "max_energy": 123.0},
	})
	await get_tree().process_frame
	_expect(_screen._selected_spot_id == "outer_tide", "current fishing spot should be selected")
	_verify_no_footer_spot_entries()
	_screen._cycle_owned_rig()
	_screen._select_spot("outer_tide")
	_expect(_navigated_to == "fishing", "continued spot selection should navigate to fishing")
	_expect(bool(_payload.get("continue_trip", false)), "continued spot selection should keep continue_trip")
	var stats: Dictionary = _payload.get("trip_stats", {})
	_expect(String(stats.get("sentinel", "")) == "carried", "continued spot selection should carry trip_stats")
	_expect(String(stats.get("rig_id", "")) == "chokusen", "continued spot selection should refresh rig stats")
	PlayerProgress.record_catch("saba", 32.0, "outer_tide")
	var outer_counts: Dictionary = PlayerProgress.spot_caught_counts.get("outer_tide", {})
	_expect(int(outer_counts.get("saba", 0)) == 1, "record_catch should store spot-specific catch counts")

	if _failed:
		return
	print("fishing_spot_select_smoke: ok")
	get_tree().quit(0)


func _verify_old_save_rig_defaults() -> void:
	PlayerProgress._apply_save_data({
		"version": 1,
		"level": 3,
		"exp": 12,
		"money": 700,
		"inventory": {},
		"caught_counts": {},
		"spot_caught_counts": {},
		"best_sizes": {},
		"eaten_recipes": {},
		"owned_rods": ["starter"],
		"equipped_rod_id": "starter",
		"owned_boats": [],
		"pending_buff": {},
		"play_seconds": 0.0,
	})
	_expect(PlayerProgress.owned_rigs == [GameData.DEFAULT_RIG_ID], "old save should default owned_rigs to sabiki")
	_expect(PlayerProgress.equipped_rig_id == GameData.DEFAULT_RIG_ID, "old save should default equipped_rig_id to sabiki")


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
