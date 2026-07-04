extends Control
## 調理フローのheadlessスモークテスト。
# SubViewport画像保存に依存せず、各状態のControl構築と数フレーム実行を確認する。
const ThemeFactory = preload("res://src/ui/ui_theme.gd")
const CookingScreen = preload("res://src/ui/cooking_screen.gd")
const CookingRewardPanelScript = preload("res://src/ui/components/cooking_reward_panel.gd")
const CookingStatusPanelScript = preload("res://src/ui/components/cooking_status_panel.gd")
const LevelUpPanelScript = preload("res://src/ui/components/level_up_panel.gd")

const VIEWPORT_RECT := Rect2(Vector2.ZERO, Vector2(1280.0, 720.0))

var _stage: Control


func _ready() -> void:
	theme = ThemeFactory.build_theme()
	_stage = Control.new()
	_stage.name = "SmokeStage1280x720"
	_stage.position = Vector2.ZERO
	_stage.size = VIEWPORT_RECT.size
	_stage.custom_minimum_size = VIEWPORT_RECT.size
	add_child(_stage)

	_seed_select_state()

	var screen := await _mount_cooking_screen()
	await _tick()
	screen.queue_free()
	await _tick()

	_seed_select_state()
	screen = await _mount_cooking_screen()
	var non_level_result := _fake_non_level_result()
	_seed_exp_gain_state()
	screen.preview_show_reward_result(non_level_result, 80, 120, 150, false)
	await get_tree().create_timer(0.15).timeout
	if not _expect_reward_state(screen, "EXP_GAIN", "non-level reward preview"):
		return
	if not _expect_overlay_count(screen, CookingRewardPanelScript, 1, "non-level reward preview"):
		return
	if not _press_named_button(screen, "RewardConfirmButton", "non-level EXP return"):
		return
	await get_tree().create_timer(0.25).timeout
	if not _expect_overlay_count(screen, CookingRewardPanelScript, 0, "non-level EXP return"):
		return
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
	if not _expect_reward_state(screen, "EXP_GAIN_LEVELUP", "level-up reward preview"):
		return
	if not _expect_overlay_count(screen, CookingRewardPanelScript, 1, "level-up reward preview"):
		return
	if not _press_named_button(screen, "RewardConfirmButton", "level-up EXP transition"):
		return
	await get_tree().create_timer(0.35).timeout
	if not _expect_overlay_count(screen, CookingRewardPanelScript, 0, "level-up EXP transition"):
		return
	if not screen.preview_has_level_up_overlay():
		push_error("Expected reward overlay close to open LEVEL_UP_OVERLAY.")
		get_tree().quit(1)
		return
	if not screen.preview_has_current_prep_summary():
		push_error("Expected LEVEL_UP_OVERLAY background to return to current preparation summary.")
		get_tree().quit(1)
		return
	if not _press_named_button(screen, "LevelUpConfirmButton", "level-up status transition"):
		return
	await get_tree().create_timer(0.25).timeout
	if not _expect_overlay_count(screen, LevelUpPanelScript, 0, "level-up status transition"):
		return
	if not screen.preview_has_status_overlay():
		push_error("Expected LEVEL_UP_OVERLAY close to open STATUS_SUMMARY.")
		get_tree().quit(1)
		return
	if not _expect_overlay_count(screen, CookingStatusPanelScript, 1, "level-up status transition"):
		return
	screen.queue_free()
	await _tick()

	var real_flow_ok := await _run_real_cooking_level_flow()
	if not real_flow_ok:
		return

	var expanded_fish_flow_ok := await _run_expanded_fish_cooking_flow()
	if not expanded_fish_flow_ok:
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
	var status_routes: Array[String] = []
	screen.navigate_requested.connect(
		func(screen_id: String, _payload: Dictionary) -> void:
			status_routes.append(screen_id)
	)
	screen.preview_show_status_overlay()
	await get_tree().create_timer(0.15).timeout
	if not _expect_overlay_count(screen, CookingStatusPanelScript, 1, "status overlay preview"):
		return
	if not _press_named_button(screen, "StatusReturnButton", "status harbor return"):
		return
	await get_tree().create_timer(0.18).timeout
	if not _expect_true(
		status_routes.has("harbor"),
		"STATUS_SUMMARY return button should navigate to harbor."
	):
		return
	if not _expect_true(
		not screen.preview_has_status_overlay(),
		"STATUS_SUMMARY return should close the status overlay."
	):
		return
	if not _expect_overlay_count(screen, CookingStatusPanelScript, 0, "status harbor return"):
		return

	get_tree().quit(0)


func _run_real_cooking_level_flow() -> bool:
	_seed_select_state()
	var starting_aji_count := PlayerProgress.fish_count("aji")
	var screen := await _mount_cooking_screen(false)
	var real_flow_routes: Array[String] = []
	screen.navigate_requested.connect(
		func(screen_id: String, _payload: Dictionary) -> void:
			real_flow_routes.append(screen_id)
	)
	if not _press_named_button(screen, "CookButton", "real cook-select to meal-result transition"):
		return false
	await get_tree().create_timer(0.15).timeout
	if not _expect_reward_state(screen, "MEAL_RESULT", "real cook-select transition"):
		return false
	if not _expect_overlay_count(screen, CookingRewardPanelScript, 1, "real cook-select transition"):
		return false

	if not _expect_eq(
		PlayerProgress.fish_count("aji"),
		starting_aji_count - 1,
		"Real cooking flow should consume one selected fish."
	):
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
	if not _press_named_button(screen, "RewardConfirmButton", "real meal-result to EXP transition"):
		return false
	await get_tree().create_timer(0.35).timeout
	if not _expect_reward_state(screen, "EXP_GAIN_LEVELUP", "real meal-result transition"):
		return false
	if not _expect_overlay_count(screen, CookingRewardPanelScript, 1, "real meal-result transition"):
		return false
	if not _press_named_button(screen, "RewardConfirmButton", "real EXP to level-up transition"):
		return false
	await get_tree().create_timer(0.35).timeout
	if not _expect_overlay_count(screen, CookingRewardPanelScript, 0, "real EXP to level-up transition"):
		return false
	if not _expect_true(
		screen.preview_has_level_up_overlay(),
		"Real cooking reward close should open LEVEL_UP_OVERLAY."
	):
		return false
	if not _expect_overlay_count(screen, LevelUpPanelScript, 1, "real EXP to level-up transition"):
		return false
	if not _expect_true(
		screen.preview_has_current_prep_summary(),
		"Real cooking LEVEL_UP_OVERLAY background should show current preparation summary."
	):
		return false
	if not _press_named_button(screen, "LevelUpConfirmButton", "real level-up to status transition"):
		return false
	await get_tree().create_timer(0.25).timeout
	if not _expect_overlay_count(screen, LevelUpPanelScript, 0, "real level-up to status transition"):
		return false
	if not _expect_true(
		screen.preview_has_status_overlay(),
		"Real cooking LEVEL_UP_OVERLAY close should open STATUS_SUMMARY."
	):
		return false
	if not _expect_overlay_count(screen, CookingStatusPanelScript, 1, "real level-up to status transition"):
		return false
	if not _press_named_button(screen, "StatusReturnButton", "real status harbor return"):
		return false
	await get_tree().create_timer(0.18).timeout
	if not _expect_true(
		real_flow_routes.has("harbor"),
		"Real cooking STATUS_SUMMARY return button should navigate to harbor."
	):
		return false
	if not _expect_true(
		not screen.preview_has_status_overlay(),
		"Real cooking STATUS_SUMMARY return should close the status overlay."
	):
		return false
	if not _expect_overlay_count(screen, CookingStatusPanelScript, 0, "real status harbor return"):
		return false

	screen.queue_free()
	await _tick()
	return true


func _run_expanded_fish_cooking_flow() -> bool:
	PlayerProgress.level = 10
	PlayerProgress.exp = 0
	PlayerProgress.money = 1250
	PlayerProgress.play_seconds = 12345.0
	PlayerProgress.inventory.clear()
	PlayerProgress.inventory["medai"] = 1
	PlayerProgress.eaten_recipes.clear()
	PlayerProgress.pending_buff = {}

	var screen := await _mount_cooking_screen(false)
	if not _expect_true(_find_named(screen, "FishRow_medai") != null, "Expanded fish row should be present in cooking list."):
		return false
	screen._select_fish("medai")
	await _tick()
	if not _expect_eq(String(screen.get("_selected_fish_id")), "medai", "Expanded fish should be selectable."):
		return false
	if not _expect_eq(String(screen.get("_selected_recipe_id")), "salt_grill", "Expanded fish should select an available recipe."):
		return false
	if not _press_named_button(screen, "CookButton", "expanded fish cook transition"):
		return false
	await get_tree().create_timer(0.15).timeout
	if not _expect_eq(PlayerProgress.fish_count("medai"), 0, "Expanded fish cooking should consume one fish."):
		return false
	if not _expect_true(
		PlayerProgress.eaten_recipes.has("medai:salt_grill"),
		"Expanded fish cooking should record dish history."
	):
		return false
	screen.queue_free()
	await _tick()
	return true


func _mount_cooking_screen(suppress_level_overlay := true) -> Control:
	var screen := CookingScreen.new()
	screen.theme = ThemeFactory.build_theme()
	screen.configure({"suppress_level_overlay": suppress_level_overlay})
	screen.size = VIEWPORT_RECT.size
	screen.custom_minimum_size = VIEWPORT_RECT.size
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stage.add_child(screen)
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


func _expect_reward_state(root: Node, expected_state: String, context: String) -> bool:
	if root.has_method("preview_has_reward_overlay_state") and root.preview_has_reward_overlay_state(expected_state):
		return true
	push_error("%s expected reward overlay state '%s'." % [context, expected_state])
	get_tree().quit(1)
	return false


func _expect_overlay_count(root: Node, script: Script, expected_count: int, context: String) -> bool:
	var actual_count := _count_nodes_with_script(root, script)
	if actual_count == expected_count:
		return true
	push_error("%s expected %d overlay(s), got %d." % [context, expected_count, actual_count])
	get_tree().quit(1)
	return false


func _count_nodes_with_script(node: Node, script: Script) -> int:
	var count := 1 if node.get_script() == script else 0
	for child in node.get_children():
		count += _count_nodes_with_script(child, script)
	return count


func _press_named_button(root: Node, button_name: String, context: String) -> bool:
	var node := _find_named(root, button_name)
	if node == null:
		push_error("%s expected button '%s'." % [context, button_name])
		get_tree().quit(1)
		return false
	if not (node is Button):
		push_error("%s node '%s' should be a Button." % [context, button_name])
		get_tree().quit(1)
		return false
	var button := node as Button
	if not button.is_visible_in_tree():
		push_error("%s button '%s' should be visible before press." % [context, button_name])
		get_tree().quit(1)
		return false
	if button.size.x <= 1.0 or button.size.y <= 1.0:
		push_error(
			"%s button '%s' should have a non-zero size before press, got %s."
			% [context, button_name, button.size]
		)
		get_tree().quit(1)
		return false
	var button_rect := button.get_global_rect()
	if not _stage_rect_contains(button_rect):
		push_error(
			"%s button '%s' should be fully inside the 1280x720 cooking stage, got %s."
			% [context, button_name, button_rect]
		)
		get_tree().quit(1)
		return false
	if button.disabled:
		push_error("%s button '%s' should be enabled before press." % [context, button_name])
		get_tree().quit(1)
		return false
	button.pressed.emit()
	return true


func _stage_rect_contains(rect: Rect2) -> bool:
	return (
		rect.position.x >= VIEWPORT_RECT.position.x
		and rect.position.y >= VIEWPORT_RECT.position.y
		and rect.end.x <= VIEWPORT_RECT.end.x
		and rect.end.y <= VIEWPORT_RECT.end.y
	)


func _find_named(node: Node, node_name: String) -> Node:
	if node.name == node_name:
		return node
	for child in node.get_children():
		var found := _find_named(child, node_name)
		if found != null:
			return found
	return null


func _seed_select_state() -> void:
	PlayerProgress.level = 4
	PlayerProgress.exp = 130
	PlayerProgress.money = 1250
	PlayerProgress.play_seconds = 12345.0
	PlayerProgress.inventory.clear()
	PlayerProgress.inventory["aji"] = 12
	PlayerProgress.inventory["saba"] = 2
	PlayerProgress.inventory["madai"] = 1
	PlayerProgress.inventory["kasago"] = 2
	PlayerProgress.inventory["hirame"] = 1
	PlayerProgress.inventory["kawahagi"] = 1
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
	PlayerProgress.exp = 120
	PlayerProgress.money = 1250
	PlayerProgress.play_seconds = 12345.0
	PlayerProgress.inventory.clear()
	PlayerProgress.inventory["aji"] = 4
	PlayerProgress.inventory["saba"] = 3
	PlayerProgress.inventory["kasago"] = 2
	PlayerProgress.inventory["mejina"] = 2
	PlayerProgress.eaten_recipes.clear()
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
		"first_time": true,
		"first_bonus": 20,
		"total_exp": 40,
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
