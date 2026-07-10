extends Node

const HarborScreenScript = preload("res://src/ui/harbor_screen.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")

var _navigated_to := ""
var _payload: Dictionary = {}
var _failed := false


func _ready() -> void:
	await _verify_locked_shark_pen()
	await _verify_preparation_hint_and_meal_row()
	await _verify_time_slot_selector()
	await _verify_hint_recomputes_on_time_slot_change()
	await _verify_info_board_v3()
	await _verify_shark_pen_navigation()
	await _verify_megalodon_omen()
	await _verify_menu_badges_and_hint()

	if _failed:
		return
	print("harbor_screen_smoke: ok")
	get_tree().quit(0)


func _verify_locked_shark_pen() -> void:
	_navigated_to = ""
	_payload = {}
	PlayerProgress.level = 29
	PlayerProgress.owned_boats = ["bluewater_boat"]
	PlayerProgress.sea_chart_fragments = 3
	PlayerProgress.inventory = {"kihada": 1}
	PlayerProgress.caught_counts = {"nekozame": 1}
	var screen := _make_screen()
	await get_tree().process_frame
	_expect(not screen._can_open_shark_pen(), "shark pen should stay locked below Lv.30")
	screen._open_shark_pen()
	_expect(_navigated_to.is_empty(), "locked shark pen should not navigate")
	_expect(screen._facility_detail_body_label.text.contains("Lv.30"), "locked shark pen action should show lock detail")
	screen.queue_free()
	await get_tree().process_frame

	PlayerProgress.level = 30
	PlayerProgress.caught_counts = {}
	screen = _make_screen()
	await get_tree().process_frame
	_expect(not screen._can_open_shark_pen(), "shark pen should stay locked when no shark has been caught")
	screen._open_shark_pen()
	_expect(_navigated_to.is_empty(), "no-shark locked shark pen should not navigate")
	_expect(screen._facility_detail_body_label.text.contains("危険海域"), "no-shark locked shark pen should show lock detail")
	screen.queue_free()
	await get_tree().process_frame


func _verify_preparation_hint_and_meal_row() -> void:
	_navigated_to = ""
	_payload = {}
	PlayerProgress.level = 30
	PlayerProgress.owned_boats = ["bluewater_boat"]
	PlayerProgress.sea_chart_fragments = 3
	PlayerProgress.inventory = {"kihada": 2, "nekozame": 1}
	PlayerProgress.caught_counts = {}
	PlayerProgress.quest_board = []
	PlayerProgress.pending_buff = {}
	var screen := _make_screen()
	await get_tree().process_frame
	_expect(not screen._preparation_body_label.text.is_empty(), "preparation card hint should never be empty")
	_expect(not screen._meal_effect_row_label.visible, "meal effect row should hide without a pending buff")
	_expect(not screen._buff_name_label.visible, "meal effect value should hide without a pending buff")

	PlayerProgress.pending_buff = {"name": "元気な食事", "text": "釣果+10%"}
	screen._refresh_labels()
	_expect(screen._meal_effect_row_label.visible, "meal effect row should show once a buff is pending")
	_expect(screen._buff_name_label.visible, "meal effect value should show once a buff is pending")
	_expect(screen._buff_name_label.text.contains("元気な食事"), "meal effect value should show the buff name")
	screen.queue_free()
	await get_tree().process_frame


func _verify_time_slot_selector() -> void:
	PlayerProgress.level = 11
	PlayerProgress.selected_time_slot_id = "night"
	var screen := _make_screen()
	await get_tree().process_frame
	_expect(PlayerProgress.selected_time_slot_id == GameData.DEFAULT_TIME_SLOT_ID, "locked saved time slot should fall back in harbor")
	_expect((screen._time_slot_buttons["asa_mazume"] as Button).disabled, "asa_mazume should stay locked below Lv12")
	_expect((screen._time_slot_buttons["night"] as Button).disabled, "night should stay locked below Lv15")
	_expect(screen._context_label.text.contains("日中"), "harbor context should show selected daytime")
	screen.queue_free()
	await get_tree().process_frame

	PlayerProgress.level = 12
	PlayerProgress.selected_time_slot_id = GameData.DEFAULT_TIME_SLOT_ID
	screen = _make_screen()
	await get_tree().process_frame
	screen._select_time_slot("asa_mazume")
	_expect(PlayerProgress.selected_time_slot_id == "asa_mazume", "Lv12 should select asa_mazume")
	_expect(screen._context_label.text.contains("朝まずめ"), "harbor context should show asa_mazume")
	_expect((screen._time_slot_buttons["night"] as Button).disabled, "night should stay locked at Lv12")
	screen.queue_free()
	await get_tree().process_frame

	PlayerProgress.level = 15
	screen = _make_screen()
	await get_tree().process_frame
	screen._select_time_slot("night")
	_expect(PlayerProgress.selected_time_slot_id == "night", "Lv15 should select night")
	_expect(screen._context_label.text.contains("夜釣り"), "harbor context should show night")
	screen.queue_free()
	await get_tree().process_frame


func _verify_hint_recomputes_on_time_slot_change() -> void:
	PlayerProgress.level = 15
	PlayerProgress.owned_boats = ["bluewater_boat"]
	PlayerProgress.sea_chart_fragments = 3
	PlayerProgress.inventory = {}
	PlayerProgress.caught_counts = {}
	PlayerProgress.quest_board = []
	PlayerProgress.pending_buff = {}
	var screen := _make_screen()
	await get_tree().process_frame
	screen._select_time_slot("asa_mazume")
	var asa_hint: String = screen._preparation_body_label.text
	_expect(not asa_hint.is_empty(), "asa_mazume hint should not be empty")
	screen._select_time_slot("night")
	var night_hint: String = screen._preparation_body_label.text
	_expect(not night_hint.is_empty(), "night hint should not be empty")
	_expect(asa_hint != night_hint, "switching time slot should recompute the target hint")
	screen.queue_free()
	await get_tree().process_frame


func _verify_info_board_v3() -> void:
	PlayerProgress.level = 15
	PlayerProgress.owned_boats = ["bluewater_boat"]
	PlayerProgress.sea_chart_fragments = 3
	PlayerProgress.inventory = {}
	PlayerProgress.caught_counts = {}
	PlayerProgress.quest_board = []
	PlayerProgress.pending_buff = {}
	var screen := _make_screen()
	await get_tree().process_frame
	_expect(screen._info_board_root != null, "info board root should exist")
	_expect(screen._info_board_slots.size() == 3, "info board should reserve 3 slots")
	var candidates: Array = screen._harbor_highlight_candidates(3)
	_expect(candidates is Array, "highlight candidates should return Array")
	_expect(candidates.size() <= 3, "highlight candidates should cap at 3")
	var seen_fish: Dictionary = {}
	for candidate in candidates:
		var fish_id := String((candidate as Dictionary).get("fish_id", ""))
		_expect(not fish_id.is_empty(), "candidate fish_id should not be empty")
		_expect(not seen_fish.has(fish_id), "highlight candidates should not duplicate fish_id")
		seen_fish[fish_id] = true
	_expect(not _has_left_departure_cta(screen), "left departure CTA should be removed")
	_expect(screen._preparation_body_label.text.contains("今日は雨の気配"), "preparation card should include weather stub")
	screen.queue_free()
	await get_tree().process_frame


func _has_left_departure_cta(screen: Control) -> bool:
	return _control_uses_action_button_frame(screen)


func _control_uses_action_button_frame(node: Node) -> bool:
	if node is Button:
		var button := node as Button
		var style := button.get_theme_stylebox("normal")
		if style is StyleBoxTexture:
			var texture_style := style as StyleBoxTexture
			if texture_style.texture != null:
				var path := String(texture_style.texture.resource_path)
				if path.contains("action_button_frame"):
					return true
	for child in node.get_children():
		if _control_uses_action_button_frame(child):
			return true
	return false


func _verify_shark_pen_navigation() -> void:
	_navigated_to = ""
	_payload = {}
	PlayerProgress.level = 30
	PlayerProgress.owned_boats = ["bluewater_boat"]
	PlayerProgress.sea_chart_fragments = 3
	PlayerProgress.inventory = {"kihada": 1}
	PlayerProgress.caught_counts = {"nekozame": 1}
	var screen := _make_screen()
	await get_tree().process_frame
	_expect(screen._can_open_shark_pen(), "shark pen should unlock after Lv.30 and a caught shark")
	screen._open_shark_pen()
	_expect(_navigated_to == "shark_pen", "unlocked shark pen should navigate")
	screen.queue_free()
	await get_tree().process_frame


func _verify_megalodon_omen() -> void:
	PlayerProgress.level = GameData.MAX_LEVEL
	PlayerProgress.owned_boats = ["bluewater_boat"]
	PlayerProgress.sea_chart_fragments = 3
	PlayerProgress.inventory = {"nushi_deep_ocean": 1}
	PlayerProgress.caught_counts = {"nekozame": 1}
	PlayerProgress.shark_bonds = {}
	for shark_id in GameData.get_normal_shark_ids():
		PlayerProgress.shark_bonds[shark_id] = 100
	var screen := _make_screen()
	await get_tree().process_frame
	_expect(screen._preparation_body_label.text.contains("深海の何か"), "harbor should show megalodon omen when unlocked and uncaught")
	screen.queue_free()
	await get_tree().process_frame


func _verify_menu_badges_and_hint() -> void:
	# ケースA: 納品できる依頼 + クーラーボックスに魚あり → 両バッジ表示・優先度1のヒント。
	PlayerProgress.level = 15
	PlayerProgress.owned_boats = ["bluewater_boat"]
	PlayerProgress.sea_chart_fragments = 3
	PlayerProgress.caught_counts = {}
	PlayerProgress.pending_buff = {}
	PlayerProgress.inventory = {"kihada": 1, "aji": 2}
	PlayerProgress.quest_board = [
		{"kind": "delivery", "fish_id": "kihada", "count": 1, "reward_money": 50, "text": "テスト依頼"}
	]
	var screen := _make_screen()
	await get_tree().process_frame
	_expect(screen._has_deliverable_quest(), "quest with satisfied count should be deliverable")
	_expect(screen._cooler_fish_total() == 3, "cooler total should sum inventory counts")
	var items_a: Array[Dictionary] = screen._facility_menu_items()
	_expect(bool(_menu_item_badge(items_a, "quest_board")), "quest_board should carry badge=true when deliverable")
	_expect(bool(_menu_item_badge(items_a, "market")), "market should carry badge=true when cooler has fish")
	_expect(_count_named_nodes(screen, "FacilityMenuBadge") == 2, "menu tree should render 2 badge dots")
	_expect(
		screen._facility_detail_title_label.text == "つぎのおすすめ",
		"default detail title should switch to hint title when a quest is deliverable"
	)
	_expect(
		screen._facility_detail_body_label.text.contains("納品できる依頼がある"),
		"deliverable quest should take priority over cooler hint"
	)
	screen.queue_free()
	await get_tree().process_frame

	# ケースB: 依頼なし・クーラーボックスも空 → バッジなし・フォールバックヒント。
	PlayerProgress.quest_board = []
	PlayerProgress.inventory = {}
	screen = _make_screen()
	await get_tree().process_frame
	_expect(not screen._has_deliverable_quest(), "empty quest board should not be deliverable")
	_expect(screen._cooler_fish_total() == 0, "empty inventory should sum to zero")
	var items_b: Array[Dictionary] = screen._facility_menu_items()
	_expect(not bool(_menu_item_badge(items_b, "quest_board")), "quest_board badge should be false without a deliverable quest")
	_expect(not bool(_menu_item_badge(items_b, "market")), "market badge should be false with an empty cooler")
	_expect(_count_named_nodes(screen, "FacilityMenuBadge") == 0, "menu tree should render no badge dots")
	_expect(
		screen._facility_detail_title_label.text == "釣り場へ向かう",
		"fallback detail should keep the original guidance when no hint applies"
	)
	screen.queue_free()
	await get_tree().process_frame

	# ケースC: クーラーボックスのみ魚あり → 魚市場バッジのみ・優先度2のヒント。
	PlayerProgress.quest_board = []
	PlayerProgress.inventory = {"aji": 2}
	screen = _make_screen()
	await get_tree().process_frame
	var items_c: Array[Dictionary] = screen._facility_menu_items()
	_expect(not bool(_menu_item_badge(items_c, "quest_board")), "quest_board badge should stay false without a deliverable quest")
	_expect(bool(_menu_item_badge(items_c, "market")), "market badge should be true with fish in the cooler")
	_expect(_count_named_nodes(screen, "FacilityMenuBadge") == 1, "menu tree should render exactly 1 badge dot")
	_expect(
		screen._facility_detail_body_label.text.contains("クーラーボックスに2匹"),
		"cooler-only state should show the priority-2 hint with the fish count"
	)
	screen.queue_free()
	await get_tree().process_frame


func _menu_item_badge(items: Array[Dictionary], id: String) -> bool:
	for item in items:
		if String(item.get("id", "")) == id:
			return bool(item.get("badge", false))
	return false


func _count_named_nodes(node: Node, target_name: String) -> int:
	# Godot は同名兄弟ノードへ自動で連番を振る（"FacilityMenuBadge2" 等）ため前方一致で数える。
	var count := 0
	if String(node.name).begins_with(target_name):
		count += 1
	for child in node.get_children():
		count += _count_named_nodes(child, target_name)
	return count


func _make_screen(payload: Dictionary = {}) -> Control:
	var screen := HarborScreenScript.new()
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


func _expect(condition: bool, message: String) -> void:
	if condition or _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
