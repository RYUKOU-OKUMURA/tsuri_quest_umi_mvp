extends Node

const QuestBoardScreenScript = preload("res://src/ui/quest_board_screen.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")
const ProbeCommon = preload("res://tools/e11_probe_common.gd")

const DESIGN_SIZE := Vector2(1280.0, 720.0)
const INITIAL_EVIDENCE := "2026-07-16_input_initial_ready.png"
const ALL_UNMET_EVIDENCE := "2026-07-16_input_all_unmet_return.png"
const POST_DELIVERY_EVIDENCE := "2026-07-16_input_post_delivery.png"

var _failed := false
var _navigation_events: Array[String] = []
var _active_viewport: SubViewport


func _ready() -> void:
	if not _isolated_home_is_safe():
		push_error("quest_board_input_smoke: 専用の隔離HOME以外からの実行を拒否しました")
		get_tree().quit(2)
		return
	PlayerProgress._sandbox_mode = true
	get_tree().root.theme = ThemeFactory.build_theme()
	await _verify_mixed_focus_graph_and_transitions()
	await _verify_delivery_and_record_once()
	await _verify_empty_refill_and_all_unmet()
	await _verify_mouse_regression()
	await _verify_cancel_once()
	if _failed:
		return
	print("quest_board_input_smoke: ok")
	get_tree().quit(0)


func _verify_mixed_focus_graph_and_transitions() -> void:
	_seed_mixed_board()
	var screen: Variant = await _make_screen()
	var action_one := _action(screen, 0)
	var action_two := _action(screen, 1)
	var action_three := _action(screen, 2)
	_expect(_active_viewport.gui_get_focus_owner() == action_one, "leftmost enabled CTA should receive safe initial focus")
	_expect(action_one.focus_mode == Control.FOCUS_ALL, "completed delivery CTA should join focus")
	_expect(action_two.focus_mode == Control.FOCUS_ALL, "completed record CTA should join focus")
	_expect(action_three.focus_mode == Control.FOCUS_NONE, "unmet CTA should leave focus")
	_expect(screen.keyboard_focus_candidates() == [action_one, action_two, screen._return_button], "mixed board should expose only two enabled CTAs and return")
	for control in screen.keyboard_focus_candidates():
		_expect(ProbeCommon.has_distinct_focus_style(control), "%s should keep a distinct focus style" % control.name)
	_expect_closed_graph(screen.keyboard_focus_candidates())
	await _capture_evidence(INITIAL_EVIDENCE)

	await _send_key(KEY_RIGHT)
	_expect(_active_viewport.gui_get_focus_owner() == action_two, "Right should move across enabled CTAs and skip disabled slot 3")
	await _send_key(KEY_DOWN)
	_expect(_active_viewport.gui_get_focus_owner() == screen._return_button, "Down from CTA should reach return")
	await _send_key(KEY_UP)
	_expect(_active_viewport.gui_get_focus_owner() == action_two, "Up from return should reach the rightmost enabled CTA")
	await _send_key(KEY_TAB)
	_expect(_active_viewport.gui_get_focus_owner() == screen._return_button, "Tab should follow card order into return")
	await _send_key(KEY_TAB)
	_expect(_active_viewport.gui_get_focus_owner() == action_one, "Tab should close from return to the first enabled CTA")
	await _send_key(KEY_TAB, true)
	_expect(_active_viewport.gui_get_focus_owner() == screen._return_button, "Shift+Tab should reverse the closed cycle")

	action_one.grab_focus()
	PlayerProgress.inventory["aji"] = 0
	screen._refresh()
	await _settle()
	_expect(action_one.focus_mode == Control.FOCUS_NONE, "newly unmet focused CTA should leave focus")
	_expect(_active_viewport.gui_get_focus_owner() == action_two, "disabled focused slot should fall forward to the next enabled slot")
	PlayerProgress.inventory["aji"] = 2
	screen._refresh()
	await _settle()
	_expect(action_one.focus_mode == Control.FOCUS_ALL, "externally completed CTA should rejoin focus")
	_expect(_active_viewport.gui_get_focus_owner() == action_two, "newly enabled CTA should not steal a still-valid focus")
	PlayerProgress.best_sizes["saba"] = 0.0
	screen._refresh()
	await _settle()
	_expect(action_two.focus_mode == Control.FOCUS_NONE, "record CTA should leave focus when its condition becomes unmet")
	_expect(_active_viewport.gui_get_focus_owner() == action_one, "disabled focused slot should cycle to the remaining enabled CTA")
	PlayerProgress.inventory["aji"] = 0
	screen._refresh()
	await _settle()
	_expect(_active_viewport.gui_get_focus_owner() == screen._return_button, "board with no enabled CTA should fall back to return")
	PlayerProgress.inventory["aji"] = 2
	PlayerProgress.best_sizes["saba"] = 50.0
	screen._refresh()
	await _settle()
	_expect(_active_viewport.gui_get_focus_owner() == screen._return_button, "A-B-A refresh should preserve valid semantic return focus")
	_expect_closed_graph(screen.keyboard_focus_candidates())
	await _free_screen(screen)


func _verify_delivery_and_record_once() -> void:
	_seed_mixed_board()
	var screen: Variant = await _make_screen()
	var action_one := _action(screen, 0)
	var action_two := _action(screen, 1)
	var action_one_pressed := [0]
	action_one.pressed.connect(func() -> void: action_one_pressed[0] += 1)
	var first_quest: Dictionary = PlayerProgress.quest_board[0].duplicate(true)
	var completed_before := PlayerProgress.quest_completed_count
	var money_before := PlayerProgress.money
	await _send_key_with_echo(KEY_ENTER)
	_expect(action_one_pressed[0] == 1, "Enter press including echo should emit one delivery action")
	_expect(PlayerProgress.quest_completed_count == completed_before + 1, "keyboard delivery should increment completion once")
	_expect(PlayerProgress.money == money_before + int(first_quest.get("reward_money", 0)), "keyboard delivery should add one reward")
	_expect(PlayerProgress.fish_count("aji") == 0, "keyboard delivery should consume the required fish once")
	_expect(PlayerProgress.quest_board.size() == 3, "delivery refresh should keep exactly three posted quests")
	_expect(PlayerProgress.quest_board[0] != first_quest, "delivery should replace only the completed slot")
	_expect(_active_viewport.gui_get_focus_owner() == action_two, "disabled replacement slot should fall forward to the next enabled CTA")
	await _capture_evidence(POST_DELIVERY_EVIDENCE)
	await _free_screen(screen)

	_seed_mixed_board()
	screen = await _make_screen()
	action_two = _action(screen, 1)
	var action_two_pressed := [0]
	action_two.pressed.connect(func() -> void: action_two_pressed[0] += 1)
	action_two.grab_focus()
	var inventory_before := PlayerProgress.inventory.duplicate(true)
	var second_quest: Dictionary = PlayerProgress.quest_board[1].duplicate(true)
	completed_before = PlayerProgress.quest_completed_count
	money_before = PlayerProgress.money
	await _send_key_with_echo(KEY_ENTER)
	_expect(action_two_pressed[0] == 1, "Enter press including echo should emit one record report")
	_expect(PlayerProgress.quest_completed_count == completed_before + 1, "record report should increment completion once")
	_expect(PlayerProgress.money == money_before + int(second_quest.get("reward_money", 0)), "keyboard record report should add one reward including Enter echo")
	_expect(PlayerProgress.inventory == inventory_before, "record report should not consume any fish")
	_expect(PlayerProgress.quest_board.size() == 3 and PlayerProgress.quest_board[1] != second_quest, "record report should replace its slot once")
	await _free_screen(screen)


func _verify_empty_refill_and_all_unmet() -> void:
	_seed_base_progress()
	PlayerProgress.quest_board = []
	var screen: Variant = await _make_screen()
	_expect(PlayerProgress.quest_board.size() == 3, "empty board should refill to three quests when the screen opens")
	_expect(screen.keyboard_focus_candidates() == [screen._return_button], "refilled all-unmet board should expose return only")
	_expect(_active_viewport.gui_get_focus_owner() == screen._return_button, "all-unmet board should focus safe return")
	_expect_closed_graph(screen.keyboard_focus_candidates())
	await _capture_evidence(ALL_UNMET_EVIDENCE)
	await _free_screen(screen)

	_seed_all_unmet_board()
	screen = await _make_screen()
	for index in range(3):
		_expect(_action(screen, index).focus_mode == Control.FOCUS_NONE, "all-unmet slot %d should be excluded from focus" % (index + 1))
	_expect(_active_viewport.gui_get_focus_owner() == screen._return_button, "explicit all-unmet board should focus return")
	await _send_key(KEY_DOWN)
	_expect(_active_viewport.gui_get_focus_owner() == screen._return_button, "singleton return graph should remain safe on arrows")
	PlayerProgress.inventory["aji"] = 2
	screen._refresh()
	await _settle()
	_expect(_action(screen, 0).focus_mode == Control.FOCUS_ALL, "external progress should enable a completed delivery CTA")
	_expect(_active_viewport.gui_get_focus_owner() == screen._return_button, "external enable should not steal current return focus")
	await _send_key(KEY_UP)
	_expect(_active_viewport.gui_get_focus_owner() == _action(screen, 0), "return Up should reach the newly enabled CTA")
	await _free_screen(screen)


func _verify_mouse_regression() -> void:
	_seed_mixed_board()
	var screen: Variant = await _make_screen()
	var money_before := PlayerProgress.money
	var completed_before := PlayerProgress.quest_completed_count
	await _click_control(_action(screen, 0))
	_expect(PlayerProgress.quest_completed_count == completed_before + 1, "mouse delivery should still complete exactly once")
	_expect(PlayerProgress.money > money_before, "mouse delivery should still add its reward")
	_navigation_events.clear()
	await _click_control(screen._return_button)
	_expect(_navigation_events == ["harbor"], "mouse return should navigate exactly once")
	await _free_screen(screen)

	_seed_mixed_board()
	screen = await _make_screen()
	var record_quest: Dictionary = PlayerProgress.quest_board[1].duplicate(true)
	var inventory_before := PlayerProgress.inventory.duplicate(true)
	money_before = PlayerProgress.money
	completed_before = PlayerProgress.quest_completed_count
	await _click_control(_action(screen, 1))
	_expect(PlayerProgress.inventory == inventory_before, "mouse record report should not consume any fish")
	_expect(PlayerProgress.money == money_before + int(record_quest.get("reward_money", 0)), "mouse record report should add exactly one reward")
	_expect(PlayerProgress.quest_completed_count == completed_before + 1, "mouse record report should increment completion exactly once")
	_expect(PlayerProgress.quest_board.size() == 3, "mouse record report should keep three posted quests")
	_expect(PlayerProgress.quest_board[1] != record_quest, "mouse record report should replace its slot exactly once")
	await _free_screen(screen)


func _verify_cancel_once() -> void:
	_seed_all_unmet_board()
	var screen: Variant = await _make_screen()
	_navigation_events.clear()
	await _push_key(KEY_ESCAPE, true)
	await _push_key(KEY_ESCAPE, true, true)
	await _push_key(KEY_ESCAPE, false)
	await _settle()
	_expect(_navigation_events == ["harbor"], "Escape press including echo should navigate exactly once")
	await _free_screen(screen)


func _seed_base_progress() -> void:
	PlayerProgress.level = 9
	PlayerProgress.exp = 0
	PlayerProgress.money = 1000
	PlayerProgress.inventory = {}
	PlayerProgress.caught_counts = {}
	PlayerProgress.best_sizes = {}
	PlayerProgress.quest_board = []
	PlayerProgress.quest_completed_count = 0
	PlayerProgress.owned_boats = ["skiff", "offshore_boat", "bluewater_boat"]
	PlayerProgress.owned_rods = ["starter"]
	PlayerProgress.equipped_rod_id = "starter"
	PlayerProgress.owned_rigs = [GameData.DEFAULT_RIG_ID]
	PlayerProgress.equipped_rig_id = GameData.DEFAULT_RIG_ID
	PlayerProgress._remember_current_titles()


func _seed_mixed_board() -> void:
	_seed_base_progress()
	PlayerProgress.inventory = {"aji": 2}
	PlayerProgress.best_sizes = {"saba": 50.0}
	PlayerProgress.quest_completed_count = 1
	PlayerProgress.quest_board = [
		_delivery_quest("aji", 2, 240),
		_record_quest("saba", 45.0, 975),
		_delivery_quest("kasago", 3, 630),
	]
	PlayerProgress._remember_current_titles()


func _seed_all_unmet_board() -> void:
	_seed_base_progress()
	PlayerProgress.quest_board = [
		_delivery_quest("aji", 2, 240),
		_record_quest("saba", 45.0, 975),
		_delivery_quest("kasago", 3, 630),
	]


func _delivery_quest(fish_id: String, count: int, reward: int) -> Dictionary:
	var fish_name := String(GameData.get_fish(fish_id).get("name", fish_id))
	return {
		"template_id": "bulk_common",
		"kind": "delivery",
		"fish_id": fish_id,
		"count": count,
		"reward_money": reward,
		"text": "%sを%d匹届けてほしい" % [fish_name, count],
	}


func _record_quest(fish_id: String, target_size: float, reward: int) -> Dictionary:
	var fish_name := String(GameData.get_fish(fish_id).get("name", fish_id))
	return {
		"template_id": "size_record",
		"kind": "record",
		"fish_id": fish_id,
		"target_size_cm": target_size,
		"posted_best_cm": 0.0,
		"reward_money": reward,
		"text": "%.1fcm以上の%sを釣り上げてくれ" % [target_size, fish_name],
	}


func _make_screen() -> Variant:
	_navigation_events.clear()
	_active_viewport = SubViewport.new()
	_active_viewport.name = "QuestBoardInputViewport"
	_active_viewport.size = Vector2i(DESIGN_SIZE)
	_active_viewport.disable_3d = true
	_active_viewport.transparent_bg = false
	_active_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	_active_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_active_viewport)
	var screen := QuestBoardScreenScript.new()
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


func _action(screen: Variant, index: int) -> Button:
	return screen._quest_cards[index]["button"] as Button


func _expect_closed_graph(available: Array[Control]) -> void:
	_expect(not available.is_empty(), "focus graph should contain at least one enabled operation")
	for control in available:
		for path in [
			control.focus_neighbor_left,
			control.focus_neighbor_right,
			control.focus_neighbor_top,
			control.focus_neighbor_bottom,
			control.focus_next,
			control.focus_previous,
		]:
			_expect(not path.is_empty(), "%s should have no open focus edge" % control.name)
			if path.is_empty():
				continue
			var target := control.get_node_or_null(path) as Control
			_expect(target != null and available.has(target), "%s edge should resolve inside the enabled graph" % control.name)


func _send_key(keycode: Key, shift := false) -> void:
	await _push_key(keycode, true, false, shift)
	await _push_key(keycode, false, false, shift)
	await _settle()


func _send_key_with_echo(keycode: Key) -> void:
	await _push_key(keycode, true)
	await _push_key(keycode, true, true)
	await _push_key(keycode, false)
	await _settle()


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


func _capture_evidence(file_name: String) -> void:
	var output_dir := OS.get_environment("TSURI_QUEST_BOARD_INPUT_EVIDENCE_DIR").strip_edges()
	if output_dir.is_empty():
		return
	DirAccess.make_dir_recursive_absolute(output_dir)
	await get_tree().create_timer(0.5).timeout
	RenderingServer.force_draw()
	await get_tree().process_frame
	var image := _active_viewport.get_texture().get_image()
	_expect(image != null and image.get_size() == Vector2i(1280, 720), "%s should be an exact 1280x720 runtime capture" % file_name)
	if _failed:
		return
	var error := image.save_png(output_dir.path_join(file_name))
	_expect(error == OK, "%s should be saved" % file_name)


func _settle() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame


func _free_screen(screen: Node) -> void:
	var viewport := screen.get_parent()
	viewport.queue_free()
	await _settle()
	_active_viewport = null


func _isolated_home_is_safe() -> bool:
	var raw_home := OS.get_environment("HOME")
	var home := raw_home.simplify_path()
	var user_data := ProjectSettings.globalize_path("user://").simplify_path()
	var manual_home := (
		OS.get_environment("TSURI_QUEST_BOARD_INPUT_SMOKE_ALLOW") == "1"
		and home.begins_with("/private/tmp/tsuri_quest_board_input_smoke_")
	)
	var release_home := (
		(home.begins_with("/private/tmp/") or home.begins_with("/private/var/folders/"))
		and home.get_file().begins_with("test_")
		and home.get_base_dir().get_file().begins_with("tsuri_release_verify_home_")
	)
	return (
		(manual_home or release_home)
		and raw_home == raw_home.strip_edges()
		and not raw_home.contains("..")
		and user_data.begins_with(home + "/")
	)


func _expect(condition: bool, message: String) -> void:
	if condition or _failed:
		return
	_failed = true
	push_error("quest_board_input_smoke: %s" % message)
	get_tree().quit(1)
