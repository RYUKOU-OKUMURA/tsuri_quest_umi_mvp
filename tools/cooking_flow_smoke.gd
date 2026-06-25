extends Control
## 調理フローのheadlessスモークテスト。
# SubViewport画像保存に依存せず、各状態のControl構築と数フレーム実行を確認する。
const ThemeFactory = preload("res://src/ui/ui_theme.gd")
const CookingScreen = preload("res://src/ui/cooking_screen.gd")
const LevelUpPanelScript = preload("res://src/ui/components/level_up_panel.gd")


func _ready() -> void:
	theme = ThemeFactory.build_theme()
	_seed_select_state()

	var screen := await _mount_cooking_screen()
	await _tick()
	screen.queue_free()
	await _tick()

	_seed_select_state()
	screen = await _mount_cooking_screen()
	var non_level_result := _fake_non_level_result()
	_seed_exp_gain_state()
	screen.preview_show_reward_result(non_level_result, 80, 100, 150, false)
	await get_tree().create_timer(0.15).timeout
	if not screen.preview_accept_reward_overlay():
		push_error("Expected non-level EXP overlay before returning to cooking select.")
		get_tree().quit(1)
		return
	await get_tree().create_timer(0.25).timeout
	if not screen.preview_has_current_prep_summary():
		push_error("Expected non-level EXP close to return to current preparation summary.")
		get_tree().quit(1)
		return
	screen.queue_free()
	await _tick()

	_seed_select_state()
	screen = await _mount_cooking_screen(false)
	var fake_result := _fake_level_result()
	_seed_after_meal_state()
	screen.preview_show_reward_result(fake_result, 130, 150, 150, true)
	await get_tree().create_timer(0.15).timeout
	if not screen.preview_accept_reward_overlay():
		push_error("Expected reward overlay before level-up transition.")
		get_tree().quit(1)
		return
	await get_tree().create_timer(0.35).timeout
	if not screen.preview_has_level_up_overlay():
		push_error("Expected reward overlay close to open LEVEL_UP_OVERLAY.")
		get_tree().quit(1)
		return
	if not screen.preview_has_current_prep_summary():
		push_error("Expected LEVEL_UP_OVERLAY background to return to current preparation summary.")
		get_tree().quit(1)
		return
	if not screen.preview_accept_level_up_overlay():
		push_error("Expected LEVEL_UP_OVERLAY before status-summary transition.")
		get_tree().quit(1)
		return
	await get_tree().create_timer(0.25).timeout
	if not screen.preview_has_status_overlay():
		push_error("Expected LEVEL_UP_OVERLAY close to open STATUS_SUMMARY.")
		get_tree().quit(1)
		return
	screen.queue_free()
	await _tick()

	var real_flow_ok := await _run_real_cooking_level_flow()
	if not real_flow_ok:
		return

	var level_panel := LevelUpPanelScript.new()
	level_panel.theme = ThemeFactory.build_theme()
	add_child(level_panel)
	await _tick()
	level_panel.show_level_up(4, 5, _old_stats(), PlayerProgress.get_base_stats())
	await get_tree().create_timer(0.15).timeout
	level_panel.queue_free()
	await _tick()

	_seed_after_meal_state()
	screen = await _mount_cooking_screen()
	screen.preview_show_status_overlay()
	await get_tree().create_timer(0.15).timeout

	get_tree().quit(0)


func _run_real_cooking_level_flow() -> bool:
	_seed_select_state()
	var screen := await _mount_cooking_screen(false)
	screen.preview_cook_selected()
	await get_tree().create_timer(0.15).timeout

	if not _expect_eq(PlayerProgress.fish_count("aji"), 3, "Real cooking flow should consume one selected fish."):
		return false
	if not _expect_eq(PlayerProgress.level, 5, "Real cooking flow should level the player to Lv.5."):
		return false
	if not _expect_eq(PlayerProgress.exp, 20, "Real cooking flow should carry overflow EXP after level-up."):
		return false
	if not _expect_true(
		PlayerProgress.eaten_recipes.has("aji:salt_grill"),
		"Real cooking flow should record first-time dish history."
	):
		return false
	if not _expect_eq(
		String(PlayerProgress.pending_buff.get("recipe_id", "")),
		"salt_grill",
		"Real cooking flow should set the pending meal buff."
	):
		return false
	if not screen.preview_accept_reward_overlay():
		push_error("Expected real cooking meal-result overlay before EXP transition.")
		get_tree().quit(1)
		return false
	await get_tree().create_timer(0.35).timeout
	if not screen.preview_accept_reward_overlay():
		push_error("Expected real cooking EXP overlay before level-up transition.")
		get_tree().quit(1)
		return false
	await get_tree().create_timer(0.35).timeout
	if not _expect_true(
		screen.preview_has_level_up_overlay(),
		"Real cooking reward close should open LEVEL_UP_OVERLAY."
	):
		return false
	if not _expect_true(
		screen.preview_has_current_prep_summary(),
		"Real cooking LEVEL_UP_OVERLAY background should show current preparation summary."
	):
		return false
	if not screen.preview_accept_level_up_overlay():
		push_error("Expected real cooking LEVEL_UP_OVERLAY before status-summary transition.")
		get_tree().quit(1)
		return false
	await get_tree().create_timer(0.25).timeout
	if not _expect_true(
		screen.preview_has_status_overlay(),
		"Real cooking LEVEL_UP_OVERLAY close should open STATUS_SUMMARY."
	):
		return false

	screen.queue_free()
	await _tick()
	return true


func _mount_cooking_screen(suppress_level_overlay := true) -> Control:
	var screen := CookingScreen.new()
	screen.theme = ThemeFactory.build_theme()
	screen.configure({"suppress_level_overlay": suppress_level_overlay})
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(screen)
	await _tick()
	return screen


func _tick() -> void:
	await get_tree().process_frame
	await get_tree().process_frame


func _expect_true(value: bool, message: String) -> bool:
	if value:
		return true
	push_error(message)
	get_tree().quit(1)
	return false


func _expect_eq(actual: Variant, expected: Variant, message: String) -> bool:
	if actual == expected:
		return true
	push_error("%s Expected %s, got %s." % [message, str(expected), str(actual)])
	get_tree().quit(1)
	return false


func _seed_select_state() -> void:
	PlayerProgress.level = 4
	PlayerProgress.exp = 130
	PlayerProgress.money = 1250
	PlayerProgress.play_seconds = 12345.0
	PlayerProgress.inventory.clear()
	PlayerProgress.inventory["aji"] = 4
	PlayerProgress.inventory["saba"] = 3
	PlayerProgress.inventory["kasago"] = 2
	PlayerProgress.inventory["mejina"] = 2
	PlayerProgress.eaten_recipes.clear()
	PlayerProgress.pending_buff = {}


func _seed_after_meal_state() -> void:
	PlayerProgress.level = 5
	PlayerProgress.exp = 20
	PlayerProgress.money = 1250
	PlayerProgress.play_seconds = 12345.0
	PlayerProgress.inventory.clear()
	PlayerProgress.inventory["aji"] = 3
	PlayerProgress.inventory["saba"] = 3
	PlayerProgress.inventory["kasago"] = 2
	PlayerProgress.inventory["mejina"] = 2
	PlayerProgress.pending_buff = {
		"recipe_id": "salt_grill",
		"name": "アジの塩焼き",
		"stat": "max_energy",
		"value": 0.05,
		"text": "次の釣行で最大体力 +5%",
	}


func _seed_exp_gain_state() -> void:
	PlayerProgress.level = 4
	PlayerProgress.exp = 100
	PlayerProgress.money = 1250
	PlayerProgress.play_seconds = 12345.0
	PlayerProgress.inventory.clear()
	PlayerProgress.inventory["aji"] = 4
	PlayerProgress.inventory["saba"] = 3
	PlayerProgress.inventory["kasago"] = 2
	PlayerProgress.inventory["mejina"] = 2
	PlayerProgress.eaten_recipes = {"aji:salt_grill": 1}
	PlayerProgress.pending_buff = {
		"recipe_id": "salt_grill",
		"name": "アジの塩焼き",
		"stat": "max_energy",
		"value": 0.05,
		"text": "次の釣行で最大体力 +5%",
	}


func _fake_non_level_result() -> Dictionary:
	return {
		"ok": true,
		"dish_name": "アジの塩焼き",
		"base_exp": 20,
		"first_time": false,
		"first_bonus": 0,
		"total_exp": 20,
		"leveled_to": [],
		"buff": {
			"recipe_id": "salt_grill",
			"name": "アジの塩焼き",
			"stat": "max_energy",
			"value": 0.05,
			"text": "次の釣行で最大体力 +5%",
		},
	}


func _fake_level_result() -> Dictionary:
	return {
		"ok": true,
		"dish_name": "アジの塩焼き",
		"base_exp": 20,
		"first_time": true,
		"first_bonus": 20,
		"total_exp": 40,
		"leveled_to": [5],
		"buff": {
			"recipe_id": "salt_grill",
			"name": "アジの塩焼き",
			"stat": "max_energy",
			"value": 0.05,
			"text": "次の釣行で最大体力 +5%",
		},
	}


func _old_stats() -> Dictionary:
	return {
		"max_energy": 120.0,
		"reel_power": 7.3,
		"technique": 3,
		"focus": 3,
		"rod_name": "港の入門竿",
	}
