extends Node

const HarborScreenScript = preload("res://src/ui/harbor_screen.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")

const ROUTE_IDS := [
	"fishing_spots",
	"quest_board",
	"cooking",
	"market",
	"shop",
	"shipyard",
	"shark_pen",
	"status",
	"fish_book",
	"title",
]

var _navigated_to := ""
var _payload: Dictionary = {}
var _failed := false


func _ready() -> void:
	await _verify_command_board_structure()
	await _verify_target_priority_one_plus_two()
	await _verify_all_routes_and_focus()
	await _verify_interaction_style_contract()
	await _verify_notifications_and_recommendation()
	await _verify_locked_and_unlocked_shark_pen()
	await _verify_time_slots_and_dynamic_refresh()
	await _verify_departure_intel_meal_and_omen()
	await _verify_long_text_fit_and_assets()
	if _failed:
		return
	print("harbor_screen_smoke: ok")
	get_tree().quit(0)


func _verify_command_board_structure() -> void:
	_seed_base()
	var screen := _make_screen()
	await _settle()
	_expect_rect(screen._top_bar_root, Rect2(32.0, 24.0, 1216.0, 80.0), "top bar")
	_expect(screen._player_status_bar != null, "top metrics should use the shared PlayerStatusBar component")
	_expect(screen._location_label.get_global_rect().position.distance_to(Vector2(68.0, 27.0)) <= 1.0, "location title should use the corrected header origin")
	_expect(screen._context_label.get_global_rect().position.distance_to(Vector2(70.0, 65.0)) <= 1.0, "location subtitle should use the corrected header origin")
	var top_text_rects: Dictionary = screen._player_status_bar.harbor_command_text_rects()
	_expect(is_equal_approx((top_text_rects["level"] as Rect2).position.y, 7.0), "level should use the corrected first-row baseline")
	_expect(is_equal_approx((top_text_rects["exp"] as Rect2).position.y, 38.0), "EXP should use the corrected second-row baseline")
	_expect(is_equal_approx((top_text_rects["rod_caption"] as Rect2).position.y, 8.0), "rod caption should use the corrected first-row baseline")
	_expect(is_equal_approx((top_text_rects["rod"] as Rect2).position.y, 29.0), "rod name should use the corrected second-row baseline")
	_expect(is_equal_approx((top_text_rects["money_caption"] as Rect2).position.y, 6.0), "money caption should remain unchanged")
	_expect(is_equal_approx((top_text_rects["money"] as Rect2).position.y, 27.0), "money value should remain unchanged")
	_expect_rect(screen._command_board_root, Rect2(40.0, 120.0, 788.0, 512.0), "command board")
	_expect_rect(screen._operation_board_root, Rect2(844.0, 120.0, 396.0, 512.0), "operation board")
	_expect_rect(screen._footer_root, Rect2(40.0, 648.0, 1200.0, 48.0), "footer")
	var cta := screen._route_buttons.get("fishing_spots", null) as Button
	_expect_rect(cta, Rect2(864.0, 176.0, 356.0, 64.0), "departure CTA")
	_expect(cta.get_parent() == screen._operation_board_root, "departure CTA must exist only in the right operation board")
	_expect(screen._hero_target_slot.size() > 0, "hero target slot should exist")
	_expect(screen._secondary_target_slots.size() == 2, "two secondary target slots should exist")
	var hero := screen._hero_target_slot.get("slot", null) as Control
	var secondary := screen._secondary_target_slots[0].get("slot", null) as Control
	_expect(hero.size.x >= secondary.size.x * 1.8, "hero target should be materially wider than a secondary target")
	_expect_rect(screen._plan_guide_label.get_parent() as Control, Rect2(60.0, 364.0, 270.0, 78.0), "departure guide")
	_expect_rect(screen._plan_weather_label.get_parent() as Control, Rect2(338.0, 364.0, 270.0, 78.0), "departure weather")
	_expect_rect(screen._plan_pin_row, Rect2(616.0, 364.0, 192.0, 78.0), "departure target point")
	_expect_rect(screen._plan_rumor_row, Rect2(60.0, 450.0, 748.0, 114.0), "departure rumor without meal")
	_expect_rect(screen._meal_effect_panel, Rect2(60.0, 532.0, 748.0, 36.0), "meal effect")
	_expect_rect(screen._time_slot_buttons.get("asa_mazume") as Control, Rect2(132.0, 576.0, 216.0, 44.0), "asa time slot")
	_expect_rect(screen._time_slot_buttons.get("daytime") as Control, Rect2(356.0, 576.0, 216.0, 44.0), "daytime time slot")
	_expect_rect(screen._time_slot_buttons.get("night") as Control, Rect2(580.0, 576.0, 228.0, 44.0), "night time slot")
	_expect(not _tree_has_label(screen, "出港プラン"), "legacy departure-plan heading must be removed")
	_expect(not _tree_has_label(screen, "港の施設"), "legacy facility heading must be removed")
	_expect(not _tree_has_label(screen, "システム"), "legacy system section must be removed")
	_expect(not screen._context_label.text.contains("時間帯"), "time slot must not be duplicated in the header")
	_expect(not screen._status_label.text.contains("｜"), "footer must use spatial separation instead of the legacy divider")
	await _free_screen(screen)


func _verify_target_priority_one_plus_two() -> void:
	_seed_base()
	PlayerProgress.inventory = {"aji": 2}
	PlayerProgress.quest_board = [
		{"kind": "delivery", "fish_id": "aji", "count": 1, "reward_money": 50, "text": "アジを届ける"}
	]
	var screen := _make_screen()
	await _settle()
	var candidates: Array = screen._harbor_highlight_candidates(3)
	_expect(candidates.size() == 3, "dense preview state should fill hero plus two secondary targets")
	_expect(String(candidates[0].get("fish_id", "")) == "aji", "deliverable quest fish should be the first target")
	_expect(String(candidates[0].get("reason", "")) == "quest", "first target should keep the quest reason")
	_expect(bool(candidates[0].get("deliverable", false)), "first target should expose the deliverable state")
	_expect_targets_match(screen, candidates)
	var hero_badge := screen._hero_target_slot.get("badge_label", null) as Label
	var hero_detail := screen._hero_target_slot.get("detail_label", null) as Label
	_expect(hero_badge.text.contains("最優先") and hero_badge.text.contains("依頼"), "hero badge should show highest quest priority")
	_expect(hero_detail.text.contains("納品できる"), "hero detail should explain that the quest is deliverable")
	var seen: Dictionary = {}
	for candidate in candidates:
		var fish_id := String(candidate.get("fish_id", ""))
		_expect(not fish_id.is_empty() and not seen.has(fish_id), "target candidates must be non-empty and unique")
		seen[fish_id] = true
	await _free_screen(screen)


func _verify_all_routes_and_focus() -> void:
	_seed_base()
	PlayerProgress.caught_counts = {"nekozame": 1}
	var screen := _make_screen()
	await _settle()
	var actual_ids: Array = screen._route_buttons.keys()
	actual_ids.sort()
	var expected_ids := ROUTE_IDS.duplicate()
	expected_ids.sort()
	_expect(actual_ids == expected_ids, "command board should expose exactly the ten route IDs")
	for id in ROUTE_IDS:
		var button := screen._route_buttons.get(id, null) as Button
		_expect(button != null, "route button should exist: %s" % id)
		if button == null:
			continue
		_expect(button.focus_mode == Control.FOCUS_ALL, "route button should accept focus: %s" % id)
		_expect(_has_focus_neighbor(button), "route button should have an explicit focus neighbor: %s" % id)
		_navigated_to = ""
		button.pressed.emit()
		_expect(_navigated_to == id, "route button should navigate to its matching route: %s" % id)
	var cta := screen._route_buttons.get("fishing_spots", null) as Button
	_expect(get_viewport().gui_get_focus_owner() == cta, "departure CTA should receive initial focus")
	var tile := screen._route_buttons.get("quest_board", null) as Button
	_expect(cta.size.x * cta.size.y >= tile.size.x * tile.size.y * 2.0, "departure CTA area should be at least twice a facility tile")
	await _free_screen(screen)


func _verify_interaction_style_contract() -> void:
	_seed_base(30)
	var screen := _make_screen()
	await _settle()
	for id in ROUTE_IDS:
		var route_button := screen._route_buttons.get(id, null) as Button
		if route_button != null:
			_assert_distinct_interaction_styles(route_button, "route %s" % id)
	for time_slot_id in GameData.get_all_time_slot_ids():
		var time_button := screen._time_slot_buttons.get(time_slot_id, null) as Button
		_expect(time_button != null, "time-slot button should exist: %s" % time_slot_id)
		if time_button != null:
			_assert_distinct_interaction_styles(time_button, "time slot %s" % time_slot_id)
	await _free_screen(screen)


func _verify_notifications_and_recommendation() -> void:
	_seed_base()
	PlayerProgress.inventory = {"aji": 2, "kihada": 1}
	PlayerProgress.quest_board = [
		{"kind": "delivery", "fish_id": "aji", "count": 1, "reward_money": 50, "text": "アジを届ける"}
	]
	var screen := _make_screen()
	await _settle()
	_expect(screen._notification_badges.keys().has("quest_board"), "deliverable quest should show the quest badge")
	_expect(screen._notification_badges.keys().has("market"), "cooler fish should show the market badge")
	_expect(screen._facility_detail_title_label.text == "つぎのおすすめ", "recommendation title should remain visible on initial CTA focus")
	_expect(screen._facility_detail_body_label.text.contains("納品できる依頼"), "deliverable quest should win recommendation priority")
	for id in ["quest_board", "market"]:
		var badge := screen._notification_badges.get(id, null) as Control
		var button := screen._route_buttons.get(id, null) as Button
		_expect(button.get_global_rect().intersects(badge.get_global_rect()), "badge should sit inside its matching tile: %s" % id)
	var cooking := screen._route_buttons.get("cooking", null) as Button
	cooking.grab_focus()
	await get_tree().process_frame
	_expect(screen._facility_detail_title_label.text == "調理場", "focused facility should temporarily replace the recommendation")
	cooking.release_focus()
	await get_tree().process_frame
	_expect(screen._facility_detail_title_label.text == "つぎのおすすめ", "recommendation should return after focus leaves a facility")
	await _free_screen(screen)

	_seed_base()
	PlayerProgress.inventory = {}
	PlayerProgress.quest_board = []
	screen = _make_screen()
	await _settle()
	_expect(screen._notification_badges.is_empty(), "empty state should render no notification badges")
	_expect(screen._facility_detail_title_label.text == "釣り場へ向かう", "empty state should recommend departure")
	await _free_screen(screen)

	_seed_base()
	PlayerProgress.inventory = {"aji": 2}
	PlayerProgress.quest_board = []
	screen = _make_screen()
	await _settle()
	_expect(screen._notification_badges.keys() == ["market"], "cooler-only state should render only the market badge")
	_expect(screen._facility_detail_body_label.text.contains("クーラーボックスに2匹"), "cooler-only recommendation should include fish count")
	await _free_screen(screen)


func _verify_locked_and_unlocked_shark_pen() -> void:
	_seed_base(29)
	var screen := _make_screen()
	await _settle()
	var shark := screen._route_buttons.get("shark_pen", null) as Button
	_expect(not shark.disabled, "locked shark pen should stay pressable so its unlock condition can be read")
	_expect(screen._lock_icons.has("shark_pen"), "locked shark pen should show a lock icon")
	_navigated_to = ""
	shark.pressed.emit()
	_expect(_navigated_to.is_empty(), "locked shark pen must not navigate")
	_expect(screen._facility_detail_body_label.text.contains("Lv.30"), "locked shark pen should explain its level requirement")
	await _free_screen(screen)

	_seed_base(30)
	PlayerProgress.caught_counts = {"nekozame": 1}
	screen = _make_screen()
	await _settle()
	_expect(not screen._lock_icons.has("shark_pen"), "unlocked shark pen should remove its lock icon")
	_navigated_to = ""
	(screen._route_buttons["shark_pen"] as Button).pressed.emit()
	_expect(_navigated_to == "shark_pen", "unlocked shark pen should navigate")
	await _free_screen(screen)


func _verify_time_slots_and_dynamic_refresh() -> void:
	_seed_base(11)
	PlayerProgress.selected_time_slot_id = "night"
	var screen := _make_screen()
	await _settle()
	_expect(PlayerProgress.selected_time_slot_id == GameData.DEFAULT_TIME_SLOT_ID, "locked saved time slot should fall back to daytime")
	_expect((screen._time_slot_buttons["asa_mazume"] as Button).disabled, "asa_mazume should be locked below Lv.12")
	_expect((screen._time_slot_buttons["night"] as Button).disabled, "night should be locked below Lv.15")
	_expect(not screen._context_label.text.contains("日中"), "selected time slot should not be duplicated in the header")
	await _free_screen(screen)

	_seed_base(12)
	screen = _make_screen()
	await _settle()
	screen._select_time_slot("asa_mazume")
	_expect(PlayerProgress.selected_time_slot_id == "asa_mazume", "Lv.12 should select asa_mazume")
	_expect(not (screen._time_slot_buttons["asa_mazume"] as Button).disabled, "asa_mazume should unlock at Lv.12")
	_expect((screen._time_slot_buttons["night"] as Button).disabled, "night should stay locked at Lv.12")
	_expect(screen._time_slot_grade_overlay.color == Palette.HARBOR_TIME_GRADE_WARM, "asa_mazume should apply warm harbor grading")
	_expect_targets_match(screen, screen._harbor_highlight_candidates(3))
	_expect(not screen._plan_pin_label.text.is_empty(), "time-slot refresh should keep a target point")
	await _free_screen(screen)

	_seed_base(15)
	screen = _make_screen()
	await _settle()
	screen._select_time_slot("night")
	_expect(PlayerProgress.selected_time_slot_id == "night", "Lv.15 should select night")
	_expect(screen._time_slot_grade_overlay.color == Palette.HARBOR_TIME_GRADE_COOL, "night should apply cool harbor grading")
	_expect_targets_match(screen, screen._harbor_highlight_candidates(3))
	await _free_screen(screen)


func _verify_departure_intel_meal_and_omen() -> void:
	_seed_base(30)
	PlayerProgress.pending_buff = {}
	var screen := _make_screen()
	await _settle()
	_expect(not screen._meal_effect_panel.visible, "meal strip should hide when no buff is active")
	var daytime_button := screen._time_slot_buttons.get("daytime", null) as Button
	_expect(is_equal_approx(daytime_button.get_global_rect().position.y, 576.0), "time slots should stay on the lower baseline without a meal buff")
	_expect(is_equal_approx(screen._plan_rumor_row.size.y, 114.0), "rumor should expand into the unused meal area when no buff is active")
	_expect(is_equal_approx(daytime_button.get_global_rect().position.y - screen._plan_rumor_row.get_global_rect().end.y, 12.0), "expanded rumor should stop 12px above the time slots")
	_expect(is_equal_approx(screen._plan_rumor_eyebrow_label.position.y, 28.0), "expanded rumor eyebrow should stay vertically centered")
	_expect(is_equal_approx(screen._plan_rumor_icon.position.y, 41.0), "expanded rumor icon should stay vertically centered")
	_expect(is_equal_approx(screen._plan_rumor_label.position.y, 50.0), "expanded rumor body should stay vertically centered")
	_expect(not screen._plan_guide_label.text.is_empty(), "guide card should never be empty")
	_expect(screen._plan_weather_label.text.contains("雨"), "weather card should keep the rain stub")
	_expect(screen._plan_guide_label.get_theme_font_size("font_size") >= 15, "departure body text should use the enlarged readable size")
	PlayerProgress.pending_buff = {"name": "カサゴの塩焼き", "text": "次の釣行で最大体力 +5%"}
	screen._refresh_labels()
	_expect(screen._meal_effect_panel.visible, "meal strip should show for a pending buff")
	_expect(is_equal_approx(screen._plan_rumor_row.size.y, 78.0), "rumor should return to its compact height when a meal buff is active")
	_expect(is_equal_approx(screen._plan_rumor_eyebrow_label.position.y, 10.0), "compact rumor eyebrow should restore its original position")
	_expect(is_equal_approx(screen._plan_rumor_icon.position.y, 23.0), "compact rumor icon should restore its original position")
	_expect(is_equal_approx(screen._plan_rumor_label.position.y, 32.0), "compact rumor body should restore its original position")
	_expect(is_equal_approx(daytime_button.get_global_rect().position.y, 576.0), "time slots should not jump when a meal buff appears")
	_expect(screen._buff_name_label.text.contains("カサゴの塩焼き"), "meal strip should show the buff name")
	_expect(not screen._plan_rumor_row.get_global_rect().intersects(screen._meal_effect_panel.get_global_rect()), "rumor and meal rows must not overlap")
	_expect(not screen._meal_effect_panel.get_global_rect().intersects(daytime_button.get_global_rect()), "meal row and time slots must not overlap")
	_expect(is_equal_approx(screen._command_board_root.get_global_rect().end.y - daytime_button.get_global_rect().end.y, 12.0), "time slots should leave a 12px lower inset")
	PlayerProgress.pending_buff = {}
	screen._refresh_labels()
	_expect(is_equal_approx(screen._plan_rumor_row.size.y, 114.0), "rumor should expand again after a meal buff clears")
	_expect(is_equal_approx(screen._plan_rumor_label.position.y, 50.0), "expanded rumor content should restore after a meal buff clears")
	await _free_screen(screen)

	_seed_base(GameData.MAX_LEVEL)
	PlayerProgress.inventory = {"nushi_deep_ocean": 1}
	PlayerProgress.caught_counts = {"nekozame": 1}
	for shark_id in GameData.get_normal_shark_ids():
		PlayerProgress.shark_bonds[shark_id] = 100
	screen = _make_screen()
	await _settle()
	_expect(screen._plan_rumor_row.visible, "megalodon omen should keep the rumor strip visible")
	_expect(screen._plan_rumor_label.text.contains("深海の何か"), "megalodon omen should appear in the rumor strip")
	_assert_wrapped_label_height(screen._plan_rumor_label, "megalodon rumor")
	await _free_screen(screen)


func _verify_long_text_fit_and_assets() -> void:
	_seed_base(30)
	PlayerProgress.money = 999999999
	PlayerProgress.play_seconds = 359999.0
	PlayerProgress.inventory = {"takenokomebaru": 2}
	PlayerProgress.quest_board = [
		{
			"kind": "delivery",
			"fish_id": "takenokomebaru",
			"count": 1,
			"reward_money": 999999,
			"text": "タケノコメバルを港の研究所へ届けてほしい",
		}
	]
	PlayerProgress.pending_buff = {
		"name": "香草と潮風のタケノコメバル特製塩焼き",
		"text": "次の釣行で最大体力 +15%",
	}
	var screen := _make_screen()
	await _settle()
	_expect_targets_match(screen, screen._harbor_highlight_candidates(3))
	_assert_wrapped_label_height(screen._plan_guide_label, "long departure guide")
	_assert_wrapped_label_height(screen._plan_weather_label, "departure weather")
	_assert_wrapped_label_height(screen._plan_pin_label, "departure target point")
	_assert_wrapped_label_height(screen._plan_rumor_label, "departure rumor")
	_assert_visible_label_widths(screen)
	_assert_visible_textures(screen)
	await _free_screen(screen)


func _expect_targets_match(screen: Control, candidates: Array) -> void:
	for index in range(screen._info_board_slots.size()):
		var slot_data: Dictionary = screen._info_board_slots[index]
		var slot := slot_data.get("slot", null) as Control
		if index >= candidates.size():
			_expect(not slot.visible, "unused target slots should hide")
			continue
		_expect(slot.visible, "candidate target slots should be visible")
		var fish_id := String((candidates[index] as Dictionary).get("fish_id", ""))
		var expected_name := String(GameData.get_fish(fish_id).get("name", fish_id))
		var name_label := slot_data.get("name_label", null) as Label
		_expect(name_label.text == expected_name, "target slot should match candidate order at index %d" % index)


func _assert_visible_label_widths(node: Node) -> void:
	if node is Label:
		var label := node as Label
		if label.is_visible_in_tree() and not label.text.is_empty() and label.autowrap_mode == TextServer.AUTOWRAP_OFF:
			var font := label.get_theme_font("font")
			var font_size := label.get_theme_font_size("font_size")
			var outline := label.get_theme_constant("outline_size")
			var width := font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + float(outline * 2)
			_expect(width <= label.size.x + 1.5, "visible label should fit without clipping: %s (%.1f > %.1f)" % [label.text, width, label.size.x])
	for child in node.get_children():
		_assert_visible_label_widths(child)


func _assert_wrapped_label_height(label: Label, label_name: String) -> void:
	var font_size := label.get_theme_font_size("font_size")
	var line_count := maxi(1, label.get_line_count())
	var outline := label.get_theme_constant("outline_size")
	var needed_height := float(font_size * line_count) * 1.18 + float(outline * 2)
	_expect(
		needed_height <= label.size.y + 1.5,
		"%s should show all wrapped lines (%.1f > %.1f)" % [label_name, needed_height, label.size.y]
	)


func _assert_visible_textures(node: Node) -> void:
	if node is TextureRect:
		var rect := node as TextureRect
		if rect.is_visible_in_tree():
			_expect(rect.texture != null, "visible TextureRect should have a loaded texture: %s" % rect.name)
	if node is NinePatchRect:
		var patch := node as NinePatchRect
		if patch.is_visible_in_tree():
			_expect(patch.texture != null, "visible NinePatchRect should have a loaded texture: %s" % patch.name)
	for child in node.get_children():
		_assert_visible_textures(child)


func _assert_distinct_interaction_styles(button: Button, label: String) -> void:
	var normal := button.get_theme_stylebox("normal")
	var hover := button.get_theme_stylebox("hover")
	var pressed := button.get_theme_stylebox("pressed")
	var focus := button.get_theme_stylebox("focus")
	_expect(normal != null, "%s should have a normal style" % label)
	_expect(hover != null, "%s should have a hover style" % label)
	_expect(pressed != null, "%s should have a pressed style" % label)
	_expect(focus != null, "%s should have a focus style" % label)
	if normal == null or hover == null or pressed == null or focus == null:
		return
	var states := [
		{"name": "normal", "style": normal},
		{"name": "hover", "style": hover},
		{"name": "pressed", "style": pressed},
		{"name": "focus", "style": focus},
	]
	for left_index in range(states.size()):
		for right_index in range(left_index + 1, states.size()):
			var left: StyleBox = states[left_index]["style"]
			var right: StyleBox = states[right_index]["style"]
			var pair_label := "%s/%s" % [states[left_index]["name"], states[right_index]["name"]]
			_expect(
				left.get_instance_id() != right.get_instance_id(),
				"%s %s styles must not share one object" % [label, pair_label]
			)
			_expect(
				_stylebox_visual_signature(left) != _stylebox_visual_signature(right),
				"%s %s styles must not render identically" % [label, pair_label]
			)
	_expect(focus is StyleBoxFlat, "%s focus should use a border-only StyleBoxFlat" % label)
	if focus is StyleBoxFlat:
		var flat := focus as StyleBoxFlat
		var border_width := maxi(
			maxi(flat.border_width_left, flat.border_width_top),
			maxi(flat.border_width_right, flat.border_width_bottom)
		)
		_expect(border_width > 0, "%s focus border should have visible width" % label)
		_expect(flat.border_color.a > 0.05, "%s focus border should have visible alpha" % label)


func _stylebox_visual_signature(style: StyleBox) -> String:
	var common := [
		style.content_margin_left,
		style.content_margin_top,
		style.content_margin_right,
		style.content_margin_bottom,
	]
	if style is StyleBoxFlat:
		var flat := style as StyleBoxFlat
		return var_to_str([
			"flat",
			flat.bg_color,
			flat.border_color,
			flat.border_width_left,
			flat.border_width_top,
			flat.border_width_right,
			flat.border_width_bottom,
			flat.corner_radius_top_left,
			flat.corner_radius_top_right,
			flat.corner_radius_bottom_right,
			flat.corner_radius_bottom_left,
			flat.expand_margin_left,
			flat.expand_margin_top,
			flat.expand_margin_right,
			flat.expand_margin_bottom,
			flat.shadow_color,
			flat.shadow_size,
			flat.shadow_offset,
			common,
		])
	if style is StyleBoxTexture:
		var texture_style := style as StyleBoxTexture
		var texture_path := ""
		if texture_style.texture != null:
			texture_path = texture_style.texture.resource_path
		return var_to_str([
			"texture",
			texture_path,
			texture_style.modulate_color,
			texture_style.texture_margin_left,
			texture_style.texture_margin_top,
			texture_style.texture_margin_right,
			texture_style.texture_margin_bottom,
			texture_style.expand_margin_left,
			texture_style.expand_margin_top,
			texture_style.expand_margin_right,
			texture_style.expand_margin_bottom,
			texture_style.axis_stretch_horizontal,
			texture_style.axis_stretch_vertical,
			common,
		])
	return var_to_str([style.get_class(), style.resource_path, common])


func _seed_base(level := 30) -> void:
	PlayerProgress.level = level
	PlayerProgress.exp = 0
	PlayerProgress.money = 50080
	PlayerProgress.inventory = {}
	PlayerProgress.equipped_rod_id = "big_game"
	PlayerProgress.play_seconds = 3178.0
	PlayerProgress.selected_time_slot_id = GameData.DEFAULT_TIME_SLOT_ID
	PlayerProgress.pending_buff = {}
	PlayerProgress.caught_counts = {}
	PlayerProgress.quest_board = []
	PlayerProgress.eaten_recipes = {"shioyaki": 1}
	PlayerProgress.owned_boats = ["bluewater_boat"]
	PlayerProgress.sea_chart_fragments = 3
	PlayerProgress.shark_bonds = {}


func _make_screen(payload: Dictionary = {}) -> Control:
	_navigated_to = ""
	_payload = {}
	var screen := HarborScreenScript.new()
	screen.theme = ThemeFactory.build_theme()
	screen.configure(payload)
	screen.size = Vector2(1280.0, 720.0)
	screen.navigate_requested.connect(
		func(screen_id: String, route_payload: Dictionary) -> void:
			_navigated_to = screen_id
			_payload = route_payload.duplicate(true)
	)
	add_child(screen)
	return screen


func _settle() -> void:
	await get_tree().process_frame
	await get_tree().process_frame


func _free_screen(screen: Control) -> void:
	screen.queue_free()
	await get_tree().process_frame


func _expect_rect(control: Control, expected: Rect2, label: String) -> void:
	if control == null:
		_expect(false, "%s control should exist" % label)
		return
	var actual := control.get_global_rect()
	_expect(actual.position.distance_to(expected.position) <= 1.0, "%s position should match the adopted mock: %s" % [label, actual.position])
	_expect(actual.size.distance_to(expected.size) <= 1.0, "%s size should match the adopted mock: %s" % [label, actual.size])


func _tree_has_label(node: Node, text: String) -> bool:
	if node is Label and (node as Label).text == text:
		return true
	for child in node.get_children():
		if _tree_has_label(child, text):
			return true
	return false


func _has_focus_neighbor(button: Control) -> bool:
	return (
		not String(button.focus_neighbor_left).is_empty()
		or not String(button.focus_neighbor_right).is_empty()
		or not String(button.focus_neighbor_top).is_empty()
		or not String(button.focus_neighbor_bottom).is_empty()
	)


func _expect(condition: bool, message: String) -> void:
	if condition or _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
