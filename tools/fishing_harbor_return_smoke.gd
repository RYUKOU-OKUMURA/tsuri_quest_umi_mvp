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
	await _verify_keyboard_confirmation_flow()
	_verify_bite_escape_sfx()
	await _verify_continue_trip_does_not_consume_pending_buff()
	await _verify_shark_lure_cast_stats()
	await _verify_shark_lure_charge_flow()

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
	_expect(
		_screen._screen_bgm_path == "res://assets/audio/水中ファイト通常.mp3",
		"hooking a fish should switch to underwater fight BGM"
	)
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
	await _press_key(KEY_MINUS)
	_expect(_screen._quit_overlay.visible, "minus key should open harbor confirmation")
	_expect(get_viewport().gui_get_focus_owner() == _screen._quit_cancel_button, "confirmation should focus safe continue first")
	await _press_key(KEY_ESCAPE)
	_expect(not _screen._quit_overlay.visible, "escape should cancel harbor confirmation")
	await _press_key(KEY_ESCAPE)
	_expect(_screen._quit_overlay.visible, "escape key should open harbor confirmation outside the overlay")
	await _press_key(KEY_ENTER)
	_expect(not _screen._quit_overlay.visible, "enter on safe initial focus should continue fishing")
	await _press_key(KEY_ESCAPE)
	await _press_key(KEY_TAB)
	_expect(get_viewport().gui_get_focus_owner() == _screen._quit_confirm_button, "tab should reach confirm action")
	_navigated_to = ""
	await _press_key(KEY_ENTER)
	_expect(_navigated_to == "harbor", "enter should confirm harbor return")


func _reset_attempt() -> void:
	_navigated_to = ""
	_payload = {}
	_screen._last_sfx_path = ""
	_screen._prepare_new_attempt()
	_screen._hide_harbor_confirm()
	_expect(_screen._screen_bgm_path == _expected_surface_bgm_path(_screen), "new attempt should use surface BGM")


func _verify_bite_escape_sfx() -> void:
	_reset_attempt()
	_expect(_screen._simulator.cast(), "cast should start bite escape sfx attempt")
	_advance_until_bite()
	_screen._simulator.tick(_screen._simulator.bite_time_left() + 0.2)
	_expect(_screen._simulator.state == FishingSimulator.State.ESCAPED, "bite timeout should enter ESCAPED")
	_expect(
		_screen._last_sfx_path == "res://assets/audio/逃げられた.mp3",
		"escape result should play escaped SFX"
	)


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
		"environment_id": "sunny_windy",
		"weather_label": "快晴",
		"wind_label": "風 強",
		"surface_bgm_key": "windy",
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
		continued._screen_bgm_path == "res://assets/audio/海辺（少し風が強い）.mp3",
		"continued windy fishing screen should use windy seaside BGM"
	)
	_expect(
		PlayerProgress.pending_buff == pending_buff,
		"continued fishing screen must not consume pending meal buff"
	)
	continued.queue_free()
	await get_tree().process_frame
	PlayerProgress.pending_buff = {}


func _verify_shark_lure_cast_stats() -> void:
	PlayerProgress.level = GameData.MAX_LEVEL
	PlayerProgress.pending_buff = {}
	PlayerProgress.owned_boats = ["bluewater_boat"]
	PlayerProgress.sea_chart_fragments = 3
	PlayerProgress.inventory = {"kihada": 2, "nushi_deep_ocean": 1}
	PlayerProgress.shark_bonds = {}
	for shark_id in GameData.get_normal_shark_ids():
		PlayerProgress.shark_bonds[shark_id] = 100
	var lure_name := String(GameData.get_fish("kihada").get("name", "kihada"))
	var lure_screen := FishingScreenScript.new()
	lure_screen.theme = ThemeFactory.build_theme()
	lure_screen.configure({
		"spot_id": "danger_reef",
		"shark_lure_fish_id": "kihada",
		"shark_lure_fish_name": lure_name,
	})
	lure_screen.size = Vector2(1280.0, 720.0)
	add_child(lure_screen)
	await get_tree().process_frame
	_expect(
		String(lure_screen._selected_shark_lure_fish_id) == "kihada",
		"new danger reef fishing screen should store shark lure fish as initial selection"
	)
	_expect(
		String(lure_screen._trip_stats.get("shark_lure_fish_id", "")).is_empty(),
		"new danger reef fishing screen should not store effective lure before cast"
	)
	_expect(
		lure_screen._spot_detail_label.text.contains(lure_name),
		"new danger reef fishing detail should show selected shark lure fish"
	)
	_expect(PlayerProgress.fish_count("kihada") == 2, "danger reef entry should not consume selected lure fish")
	lure_screen._on_main_action_pressed()
	_expect(PlayerProgress.fish_count("kihada") == 1, "danger reef cast should consume selected lure fish")
	_expect(
		String(lure_screen._trip_stats.get("shark_lure_fish_id", "")) == "kihada",
		"danger reef cast should store effective shark lure fish"
	)
	_expect(
		String(lure_screen._trip_stats.get("shark_lure_fish_name", "")) == lure_name,
		"danger reef cast should store effective shark lure fish name"
	)
	_expect(
		int(Dictionary(lure_screen._trip_stats.get("shark_lure_charges", {})).get("kihada", 0)) == 2,
		"rare lure should keep two remaining charges after first cast"
	)
	var modifiers: Dictionary = lure_screen._trip_extra_fish_weight_modifiers()
	var expected: Dictionary = GameData.shark_lure_weights(GameData.get_fish("kihada"))
	_expect(not expected.is_empty(), "kihada should produce shark lure modifiers")
	for fish_id_variant in expected.keys():
		var fish_id := String(fish_id_variant)
		_expect(modifiers.has(fish_id), "fishing screen lure modifiers should include %s" % fish_id)
		_expect(
			is_equal_approx(float(modifiers.get(fish_id, 0.0)), float(expected.get(fish_id, 0.0))),
			"fishing screen lure modifier mismatch for %s" % fish_id
		)
	lure_screen._trip_stats["bird_swarm_hits_remaining"] = 1
	var combined_modifiers: Dictionary = lure_screen._trip_extra_fish_weight_modifiers()
	var bird_modifiers: Dictionary = GameData.bird_swarm_fish_weight_modifiers()
	_expect(combined_modifiers.has("kihada"), "combined modifiers should include bird swarm fish")
	_expect(
		is_equal_approx(float(combined_modifiers.get("kihada", 0.0)), float(bird_modifiers.get("kihada", 0.0))),
		"combined modifiers should preserve bird swarm multiplier"
	)
	for fish_id_variant in expected.keys():
		var fish_id := String(fish_id_variant)
		_expect(combined_modifiers.has(fish_id), "combined modifiers should include shark lure fish %s" % fish_id)
	lure_screen.queue_free()
	await get_tree().process_frame

	var mega_lure_name := String(GameData.get_fish("nushi_deep_ocean").get("name", "nushi_deep_ocean"))
	var mega_screen := FishingScreenScript.new()
	mega_screen.theme = ThemeFactory.build_theme()
	mega_screen.configure({
		"spot_id": "danger_reef",
		"shark_lure_fish_id": "nushi_deep_ocean",
		"shark_lure_fish_name": mega_lure_name,
	})
	mega_screen.size = Vector2(1280.0, 720.0)
	add_child(mega_screen)
	await get_tree().process_frame
	mega_screen._on_main_action_pressed()
	var mega_lure: Dictionary = mega_screen._trip_shark_lure_fish_data()
	_expect(not mega_lure.is_empty(), "megalodon route should expose nushi-grade lure data")
	_expect(PlayerProgress.fish_count("nushi_deep_ocean") == 0, "nushi lure should be consumed on cast")
	_expect(
		int(Dictionary(mega_screen._trip_stats.get("shark_lure_charges", {})).get("nushi_deep_ocean", 0)) == 4,
		"nushi lure should keep four remaining charges after first cast"
	)
	_expect(
		GameData.can_encounter_megalodon(PlayerProgress.level, "danger_reef", PlayerProgress.shark_bonds, mega_lure),
		"megalodon route should satisfy encounter gate with nushi-grade lure"
	)
	mega_screen.queue_free()
	await get_tree().process_frame


func _verify_shark_lure_charge_flow() -> void:
	PlayerProgress.level = GameData.MAX_LEVEL
	PlayerProgress.pending_buff = {}
	PlayerProgress.owned_boats = ["bluewater_boat"]
	PlayerProgress.sea_chart_fragments = 3
	PlayerProgress.shark_bonds = {}
	for shark_id in GameData.get_normal_shark_ids():
		PlayerProgress.shark_bonds[shark_id] = 100

	PlayerProgress.inventory = {"aji": 2}
	var common_screen: Variant = _danger_screen_with_lure("aji")
	add_child(common_screen)
	await get_tree().process_frame
	common_screen._on_main_action_pressed()
	_expect(PlayerProgress.fish_count("aji") == 1, "common lure first cast should consume one fish")
	_expect(
		not Dictionary(common_screen._trip_stats.get("shark_lure_charges", {})).has("aji"),
		"common lure should not keep charges after cast"
	)
	common_screen._prepare_new_attempt()
	common_screen._on_main_action_pressed()
	_expect(PlayerProgress.fish_count("aji") == 0, "common lure second cast should consume the next fish")
	_expect(String(common_screen._selected_shark_lure_fish_id).is_empty(), "spent common lure should clear selection")
	common_screen.queue_free()
	await get_tree().process_frame

	PlayerProgress.inventory = {"nushi_deep_ocean": 1}
	var nushi_screen: Variant = _danger_screen_with_lure("nushi_deep_ocean")
	add_child(nushi_screen)
	await get_tree().process_frame
	nushi_screen._on_main_action_pressed()
	_expect(PlayerProgress.fish_count("nushi_deep_ocean") == 0, "nushi lure first cast should consume one fish")
	_expect(
		int(Dictionary(nushi_screen._trip_stats.get("shark_lure_charges", {})).get("nushi_deep_ocean", 0)) == 4,
		"nushi lure first cast should keep four charges"
	)
	for expected_remaining in [3, 2, 1, 0]:
		nushi_screen._prepare_new_attempt()
		nushi_screen._on_main_action_pressed()
		_expect(PlayerProgress.fish_count("nushi_deep_ocean") == 0, "nushi charge cast should not consume another fish")
		_expect(
			int(Dictionary(nushi_screen._trip_stats.get("shark_lure_charges", {})).get("nushi_deep_ocean", 0)) == expected_remaining,
			"nushi remaining charge mismatch"
		)
	_expect(String(nushi_screen._selected_shark_lure_fish_id).is_empty(), "nushi selection should clear after final charge")
	nushi_screen.queue_free()
	await get_tree().process_frame

	PlayerProgress.inventory = {}
	var stale_screen := FishingScreenScript.new()
	stale_screen.theme = ThemeFactory.build_theme()
	stale_screen.configure({
		"spot_id": "danger_reef",
		"continue_trip": true,
		"trip_stats": {
			"shark_lure_fish_id": "aji",
			"shark_lure_fish_name": "アジ",
			"spot_depth_range": [30.0, 40.0],
		},
	})
	stale_screen.size = Vector2(1280.0, 720.0)
	add_child(stale_screen)
	await get_tree().process_frame
	_expect(String(stale_screen._selected_shark_lure_fish_id).is_empty(), "stale no-inventory lure should not become selected")
	stale_screen._on_main_action_pressed()
	_expect(
		String(stale_screen._trip_stats.get("shark_lure_fish_id", "")).is_empty(),
		"casting with no lure should clear stale effective lure"
	)
	stale_screen.queue_free()
	await get_tree().process_frame


func _danger_screen_with_lure(fish_id: String) -> Variant:
	var screen := FishingScreenScript.new()
	screen.theme = ThemeFactory.build_theme()
	screen.configure({
		"spot_id": "danger_reef",
		"shark_lure_fish_id": fish_id,
		"shark_lure_fish_name": String(GameData.get_fish(fish_id).get("name", fish_id)),
	})
	screen.size = Vector2(1280.0, 720.0)
	return screen


func _advance_until_bite() -> void:
	for _index in range(90):
		_screen._simulator.tick(0.10)
		if _screen._simulator.state == FishingSimulator.State.BITE:
			_expect(
				_screen._last_sfx_path == "res://assets/audio/アタリ_ヒット音.mp3",
				"entering BITE should play bite hit SFX"
			)
			return
	_expect(false, "simulator did not reach BITE")


func _press_key(keycode: Key) -> void:
	var pressed := InputEventKey.new()
	pressed.keycode = keycode
	pressed.pressed = true
	get_viewport().push_input(pressed)
	await get_tree().process_frame
	var released := InputEventKey.new()
	released.keycode = keycode
	released.pressed = false
	get_viewport().push_input(released)
	await get_tree().process_frame


func _expected_surface_bgm_path(screen: Variant) -> String:
	var bgm_key := String(screen._trip_stats.get("surface_bgm_key", "calm"))
	if bgm_key == "windy":
		return "res://assets/audio/海辺（少し風が強い）.mp3"
	return "res://assets/audio/海辺（さざなみ）.mp3"


func _expect(condition: bool, message: String) -> void:
	if condition or _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
