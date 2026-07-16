extends Node

const CookingScreenScript = preload("res://src/ui/cooking_screen.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")
const ProbeCommon = preload("res://tools/e11_probe_common.gd")

const DESIGN_SIZE := Vector2(1280.0, 720.0)
const EVIDENCE_NORMAL := "2026-07-16_input_select_normal_focus.png"
const EVIDENCE_LOCKED := "2026-07-16_input_select_locked_focus.png"
const EVIDENCE_EMPTY := "2026-07-16_input_select_empty_focus.png"
const EVIDENCE_LAST := "2026-07-16_input_select_last_fish_focus.png"
const EVIDENCE_MEAL := "2026-07-16_input_meal_result_focus.png"
const EVIDENCE_EXP := "2026-07-16_input_exp_gain_focus.png"
const EVIDENCE_LEVEL := "2026-07-16_input_level_up_focus.png"
const EVIDENCE_STATUS := "2026-07-16_input_status_summary_focus.png"

var _failed := false
var _navigation_events: Array[String] = []
var _active_viewport: SubViewport


func _ready() -> void:
	get_tree().root.theme = ThemeFactory.build_theme()
	await _verify_normal_focus_graph_and_semantic_restore()
	if _failed:
		return
	await _verify_locked_and_empty_graphs()
	if _failed:
		return
	await _verify_last_fish_real_flow()
	if _failed:
		return
	await _verify_level_overlay_flow()
	if _failed:
		return
	await _verify_mouse_regression()
	if _failed:
		return
	await _verify_cook_select_cancel_once()
	if _failed:
		return
	print("cooking_input_smoke: ok")
	get_tree().quit(0)


func _verify_normal_focus_graph_and_semantic_restore() -> void:
	_seed_progress(4, {"aji": 3, "saba": 2, "madai": 1, "kasago": 2})
	var screen: Variant = await _make_screen()
	var initial := _recipe_card(screen, "salt_grill")
	_expect(_focus_owner() == initial, "selected available recipe should receive safe initial focus")
	_expect(_visible_focus(initial), "initial recipe focus should have a visible runtime signature")
	_expect(screen._cook_button.focus_mode == Control.FOCUS_ALL, "available cook action should join the graph")
	var unowned_fish := _first_unowned_fish_card(screen)
	_expect(unowned_fish != null and unowned_fish.focus_mode == Control.FOCUS_NONE, "unowned fish rows should leave the graph")
	_expect(_recipe_card(screen, "simmered").focus_mode == Control.FOCUS_NONE, "wrong-material recipes should leave the graph")
	_expect(_recipe_card(screen, "fry").focus_mode == Control.FOCUS_NONE, "locked recipes should leave the graph")
	var candidates: Array[Control] = screen.keyboard_focus_candidates()
	_expect(candidates.size() >= 8, "normal Lv4 state should expose fish, recipe, book, cook, and harbor operations")
	_expect_closed_graph(candidates)
	for control in candidates:
		_expect(_has_focus_style(control), "%s should expose a distinct focus style" % control.name)
	await _capture_evidence(EVIDENCE_NORMAL)

	var visited := {}
	initial.grab_focus()
	for _index in range(candidates.size()):
		var owner := _focus_owner()
		if owner != null:
			visited[screen._control_focus_identity(owner)] = true
		await _send_key(KEY_TAB)
	_expect(visited.size() == candidates.size(), "Tab should reach every enabled COOK_SELECT operation")
	_expect(_focus_owner() == initial, "normal Tab graph should close back to initial recipe")
	var reverse_visited := {}
	for _index in range(candidates.size()):
		var owner := _focus_owner()
		if owner != null:
			reverse_visited[screen._control_focus_identity(owner)] = true
		await _send_key(KEY_TAB, true)
	_expect(reverse_visited.size() == candidates.size(), "Shift+Tab should reach every enabled COOK_SELECT operation")
	_expect(_focus_owner() == initial, "normal Shift+Tab graph should close back to initial recipe")
	for control in candidates:
		for arrow_key in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN]:
			control.grab_focus()
			await _send_key(arrow_key)
			_expect(candidates.has(_focus_owner()), "%s should keep arrow focus inside enabled candidates" % control.name)

	var fish_a := _fish_card(screen, "aji")
	var fish_b := _fish_card(screen, "saba")
	var fish_activation_count := [0]
	fish_b.gui_input.connect(
		func(event: InputEvent) -> void:
			if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_KP_ENTER:
				fish_activation_count[0] += 1
	)
	fish_b.grab_focus()
	await _send_key_with_echo(KEY_KP_ENTER)
	_expect(fish_activation_count[0] == 1, "KP Enter including echo should reach a fish card once")
	_expect(screen._selected_fish_id == "saba", "KP Enter should select the focused fish")
	_expect(_focus_owner() == fish_b, "fish selection should preserve semantic fish focus")
	fish_a.grab_focus()
	await _send_key_with_echo(KEY_ENTER)
	_expect(screen._selected_fish_id == "aji", "fish A to B to A should restore the original selection")
	_expect(_focus_owner() == fish_a, "fish A to B to A should keep focus on the restored semantic fish")

	var recipe_b := _recipe_card(screen, "sashimi")
	var recipe_count := [0]
	recipe_b.gui_input.connect(
		func(event: InputEvent) -> void:
			if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ENTER:
				recipe_count[0] += 1
	)
	recipe_b.grab_focus()
	await _send_key_with_echo(KEY_ENTER)
	_expect(recipe_count[0] == 1, "Enter including echo should reach a recipe card once")
	_expect(screen._selected_recipe_id == "sashimi", "Enter should select the focused recipe")
	_expect(_focus_owner() == recipe_b, "recipe selection should preserve semantic recipe focus")
	var recipe_a := _recipe_card(screen, "salt_grill")
	recipe_a.grab_focus()
	await _send_key_with_echo(KEY_ENTER)
	_expect(screen._selected_recipe_id == "salt_grill", "recipe A to B to A should restore the original selection")
	_expect(_focus_owner() == recipe_a, "recipe A to B to A should keep the restored semantic recipe focus")
	await _free_screen(screen)


func _verify_locked_and_empty_graphs() -> void:
	_seed_progress(1, {"aji": 2})
	var screen: Variant = await _make_screen()
	_expect(_focus_owner() == _recipe_card(screen, "salt_grill"), "Lv1 should initially focus its only available recipe")
	for recipe_id in ["sashimi", "simmered", "soup", "fry"]:
		_expect(_recipe_card(screen, recipe_id).focus_mode == Control.FOCUS_NONE, "Lv1 locked recipe %s should leave focus" % recipe_id)
	_expect_closed_graph(screen.keyboard_focus_candidates())
	await _capture_evidence(EVIDENCE_LOCKED)
	await _free_screen(screen)

	_seed_progress(4, {})
	screen = await _make_screen()
	_expect(screen._selected_fish_id.is_empty(), "empty inventory should have no selected fish")
	_expect(screen._cook_button.disabled and screen._cook_button.focus_mode == Control.FOCUS_NONE, "empty inventory cook action should be disabled and unfocusable")
	_expect(screen.keyboard_focus_candidates() == [screen._recipe_book_button, screen._harbor_button], "empty inventory should retain only recipe-book and harbor safety routes")
	_expect(_focus_owner() == screen._recipe_book_button, "empty inventory should prefer the non-destructive recipe-book route")
	_expect_closed_graph(screen.keyboard_focus_candidates())
	await _capture_evidence(EVIDENCE_EMPTY)
	await _free_screen(screen)


func _verify_last_fish_real_flow() -> void:
	_seed_progress(4, {"aji": 1})
	PlayerProgress.eaten_recipes = {"aji:salt_grill": 1}
	var screen: Variant = await _make_screen()
	var cook := screen._cook_button as Button
	cook.grab_focus()
	await _settle()
	await _capture_evidence(EVIDENCE_LAST)
	var cook_count := [0]
	cook.pressed.connect(func() -> void: cook_count[0] += 1)
	await _send_key_with_echo(KEY_ENTER)
	_expect(cook_count[0] == 1, "last-fish Enter including echo should invoke cook exactly once")
	_expect(PlayerProgress.fish_count("aji") == 0, "last-fish cooking should consume exactly one fish")
	_expect(screen.preview_has_reward_overlay_state("MEAL_RESULT"), "real cooking should enter MEAL_RESULT")
	_expect(_focus_owner() != null and _focus_owner().name == "RewardConfirmButton", "MEAL_RESULT should hand focus to RewardConfirmButton")
	_expect(_only_overlay_focus(screen, "RewardConfirmButton"), "MEAL_RESULT should trap focus to RewardConfirmButton")
	await _capture_evidence(EVIDENCE_MEAL)

	_navigation_events.clear()
	await _send_cancel_with_echo()
	_expect(screen.preview_has_reward_overlay_state("MEAL_RESULT"), "MEAL_RESULT Escape should not skip irreversible reward progress")
	_expect(_navigation_events.is_empty(), "MEAL_RESULT Escape should not navigate")
	await _send_key_with_echo(KEY_ENTER)
	await _wait_for(func() -> bool: return screen.preview_has_reward_overlay_state("EXP_GAIN"), 0.8)
	_expect(screen.preview_has_reward_overlay_state("EXP_GAIN"), "reward confirm should hand off to EXP_GAIN")
	_expect(_focus_owner() != null and _focus_owner().name == "RewardConfirmButton", "EXP_GAIN should focus RewardConfirmButton")
	_expect(_only_overlay_focus(screen, "RewardConfirmButton"), "EXP_GAIN should trap focus to RewardConfirmButton")
	await _capture_evidence(EVIDENCE_EXP)
	await _send_cancel_with_echo()
	_expect(screen.preview_has_reward_overlay_state("EXP_GAIN"), "EXP_GAIN Escape should not skip reward progress")
	await _send_key_with_echo(KEY_ENTER)
	await _wait_for(func() -> bool: return screen._active_cooking_overlay() == null, 0.8)
	_expect(screen._active_cooking_overlay() == null, "non-level EXP close should return to COOK_SELECT")
	_expect(screen._cook_button.focus_mode == Control.FOCUS_NONE, "post-last-fish CookButton should leave focus")
	_expect(_focus_owner() == screen._recipe_book_button, "post-last-fish return should fall back to recipe book")
	_expect_closed_graph(screen.keyboard_focus_candidates())
	await _free_screen(screen)


func _verify_level_overlay_flow() -> void:
	_seed_progress(5, {"aji": 3, "saba": 2})
	var screen: Variant = await _make_screen()
	screen.preview_show_reward_result(_fake_level_result(), 120, 160, 160, true)
	await _settle()
	_expect(screen.preview_has_reward_overlay_state("EXP_GAIN_LEVELUP"), "level fixture should begin at EXP_GAIN_LEVELUP")
	_expect(_focus_owner() != null and _focus_owner().name == "RewardConfirmButton", "level EXP should focus RewardConfirmButton")
	await _send_cancel_with_echo()
	_expect(screen.preview_has_reward_overlay_state("EXP_GAIN_LEVELUP"), "level EXP Escape should not skip progression")
	await _send_key_with_echo(KEY_ENTER)
	await _wait_for(func() -> bool: return screen.preview_has_level_up_overlay(), 0.8)
	_expect(screen.preview_has_level_up_overlay(), "EXP level branch should open LEVEL_UP_OVERLAY")
	_expect(_focus_owner() != null and _focus_owner().name == "LevelUpConfirmButton", "LEVEL_UP should hand focus to LevelUpConfirmButton")
	_expect(_only_overlay_focus(screen, "LevelUpConfirmButton"), "LEVEL_UP should trap focus to LevelUpConfirmButton")
	await _capture_evidence(EVIDENCE_LEVEL)
	await _send_cancel_with_echo()
	_expect(screen.preview_has_level_up_overlay(), "LEVEL_UP Escape should not skip the result")
	await _send_key_with_echo(KEY_ENTER)
	await _wait_for(func() -> bool: return screen.preview_has_status_overlay(), 0.8)
	_expect(screen.preview_has_status_overlay(), "LEVEL_UP confirm should hand off to STATUS_SUMMARY")
	_expect(_focus_owner() != null and _focus_owner().name == "StatusReturnButton", "STATUS_SUMMARY should focus StatusReturnButton")
	_expect(_only_overlay_focus(screen, "StatusReturnButton"), "STATUS_SUMMARY should trap focus to StatusReturnButton")
	await _capture_evidence(EVIDENCE_STATUS)
	_navigation_events.clear()
	await _send_cancel_with_echo()
	await _wait_for(func() -> bool: return not _navigation_events.is_empty(), 0.6)
	_expect(_navigation_events == ["harbor"], "STATUS_SUMMARY Escape including echo should navigate to harbor exactly once")
	await _free_screen(screen)


func _verify_mouse_regression() -> void:
	_seed_progress(4, {"aji": 3, "saba": 2})
	var screen: Variant = await _make_screen()
	await _click_control(_fish_card(screen, "saba"))
	_expect(screen._selected_fish_id == "saba", "mouse click should continue selecting fish rows")
	await _click_control(_recipe_card(screen, "sashimi"))
	_expect(screen._selected_recipe_id == "sashimi", "mouse click should continue selecting recipe cards")
	_navigation_events.clear()
	await _click_control(screen._harbor_button)
	_expect(_navigation_events == ["harbor"], "mouse harbor button should navigate exactly once")
	await _free_screen(screen)


func _verify_cook_select_cancel_once() -> void:
	_seed_progress(4, {"aji": 2})
	var screen: Variant = await _make_screen()
	_navigation_events.clear()
	await _send_cancel_with_echo()
	_expect(_navigation_events == ["harbor"], "COOK_SELECT Escape including echo should navigate exactly once")
	await _free_screen(screen)


func _seed_progress(level: int, inventory: Dictionary) -> void:
	PlayerProgress.level = level
	PlayerProgress.exp = 0
	PlayerProgress.money = 1250
	PlayerProgress.play_seconds = 12345.0
	PlayerProgress.inventory = inventory.duplicate(true)
	PlayerProgress.caught_counts = inventory.duplicate(true)
	PlayerProgress.spot_caught_counts = {}
	PlayerProgress.best_sizes = {}
	PlayerProgress.eaten_recipes = {}
	PlayerProgress.pending_buff = {}


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


func _make_screen() -> Variant:
	_navigation_events.clear()
	_active_viewport = SubViewport.new()
	_active_viewport.name = "CookingInputViewport"
	_active_viewport.size = Vector2i(DESIGN_SIZE)
	_active_viewport.disable_3d = true
	_active_viewport.transparent_bg = false
	_active_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	_active_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_active_viewport)
	var screen := CookingScreenScript.new()
	screen.theme = ThemeFactory.build_theme()
	screen.configure({})
	screen.size = DESIGN_SIZE
	screen.navigate_requested.connect(
		func(screen_id: String, _payload: Dictionary) -> void:
			_navigation_events.append(screen_id)
	)
	_active_viewport.add_child(screen)
	await _settle()
	return screen


func _fish_card(screen: Variant, fish_id: String) -> Control:
	var entry := Dictionary(screen._fish_cards.get(fish_id, {}))
	return entry.get("card") as Control


func _recipe_card(screen: Variant, recipe_id: String) -> Control:
	var entry := Dictionary(screen._recipe_cards.get(recipe_id, {}))
	return entry.get("card") as Control


func _first_unowned_fish_card(screen: Variant) -> Control:
	for fish_id in screen._fish_cards:
		var entry := Dictionary(screen._fish_cards[fish_id])
		if not bool(entry.get("owned", false)):
			return entry.get("card") as Control
	return null


func _focus_owner() -> Control:
	return _active_viewport.gui_get_focus_owner() as Control if _active_viewport != null else null


func _visible_focus(control: Control) -> bool:
	if control == null or not control.has_focus():
		return false
	var indicator := control.get_node_or_null(ScreenBase.COMMON_FOCUS_INDICATOR_NAME) as Control
	return indicator != null and indicator.visible


func _has_focus_style(control: Control) -> bool:
	return control != null and ProbeCommon.has_distinct_focus_style(control)


func _only_overlay_focus(screen: Variant, expected_name: String) -> bool:
	var overlay := screen._active_cooking_overlay() as Control
	if overlay == null:
		return false
	var focusable: Array[Control] = []
	_collect_focusable(overlay, focusable)
	return focusable.size() == 1 and focusable[0].name == expected_name


func _collect_focusable(root: Node, output: Array[Control]) -> void:
	for child in root.get_children():
		if child is Control:
			var control := child as Control
			if control.focus_mode != Control.FOCUS_NONE and control.is_visible_in_tree():
				if not (control is BaseButton and (control as BaseButton).disabled):
					output.append(control)
		_collect_focusable(child, output)


func _expect_closed_graph(candidates: Array[Control]) -> void:
	_expect(not candidates.is_empty(), "focus graph should contain enabled controls")
	for control in candidates:
		for path in [
			control.focus_neighbor_left,
			control.focus_neighbor_right,
			control.focus_neighbor_top,
			control.focus_neighbor_bottom,
			control.focus_next,
			control.focus_previous,
		]:
			_expect(not path.is_empty(), "%s should have a closed focus neighbor" % control.name)
			if path.is_empty():
				continue
			var target := control.get_node_or_null(path) as Control
			_expect(target != null and candidates.has(target), "%s neighbor should resolve to an enabled candidate" % control.name)


func _send_key(keycode: Key, shift := false) -> void:
	await _push_key(keycode, true, false, shift)
	await _push_key(keycode, false, false, shift)
	await _settle()


func _send_key_with_echo(keycode: Key) -> void:
	await _push_key(keycode, true)
	await _push_key(keycode, true, true)
	await _push_key(keycode, false)
	await _settle()


func _send_cancel_with_echo() -> void:
	await _send_key_with_echo(KEY_ESCAPE)


func _push_key(keycode: Key, pressed: bool, echo := false, shift := false) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = pressed
	event.echo = echo
	event.shift_pressed = shift
	_active_viewport.push_input(event, true)
	await get_tree().process_frame


func _click_control(control: Control) -> void:
	_expect(control != null, "mouse target should exist")
	if control == null:
		return
	var position := control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = position
	motion.global_position = position
	_active_viewport.push_input(motion, true)
	var down := InputEventMouseButton.new()
	down.position = position
	down.global_position = position
	down.button_index = MOUSE_BUTTON_LEFT
	down.button_mask = MOUSE_BUTTON_MASK_LEFT
	down.pressed = true
	_active_viewport.push_input(down, true)
	await get_tree().process_frame
	var up := down.duplicate() as InputEventMouseButton
	up.button_mask = 0
	up.pressed = false
	_active_viewport.push_input(up, true)
	await _settle()


func _wait_for(predicate: Callable, timeout_seconds: float) -> void:
	var deadline := Time.get_ticks_msec() + int(timeout_seconds * 1000.0)
	while Time.get_ticks_msec() < deadline:
		if predicate.call():
			return
		await get_tree().process_frame


func _capture_evidence(file_name: String) -> void:
	var output_dir := OS.get_environment("TSURI_COOKING_INPUT_EVIDENCE_DIR").strip_edges()
	if output_dir.is_empty():
		return
	DirAccess.make_dir_recursive_absolute(output_dir)
	await get_tree().create_timer(0.4).timeout
	RenderingServer.force_draw()
	await get_tree().process_frame
	var image := _active_viewport.get_texture().get_image()
	_expect(image != null and image.get_size() == Vector2i(1280, 720), "%s should be exact 1280x720 evidence" % file_name)
	if _failed:
		return
	_expect(image.save_png(output_dir.path_join(file_name)) == OK, "%s should be saved" % file_name)


func _settle() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame


func _free_screen(screen: Node) -> void:
	var viewport := screen.get_parent()
	viewport.queue_free()
	await _settle()
	_active_viewport = null


func _expect(condition: bool, message: String) -> void:
	if condition or _failed:
		return
	_failed = true
	push_error("cooking_input_smoke: %s" % message)
	get_tree().quit(1)
