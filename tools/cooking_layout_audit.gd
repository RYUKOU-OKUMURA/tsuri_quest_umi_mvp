extends Control
## 調理フロー5状態のheadlessレイアウト監査。
# スクリーンショット取得ができない環境でも、1280x720での画面外はみ出し、
# 文字の縦クリップ、欠落テクスチャを検出する。
const ThemeFactory = preload("res://src/ui/ui_theme.gd")
const CookingScreen = preload("res://src/ui/cooking_screen.gd")
const LevelUpPanelScript = preload("res://src/ui/components/level_up_panel.gd")

const VIEWPORT_SIZE := Vector2(1280.0, 720.0)
const TOLERANCE := 3.0

var _failures: Array = []
var _stage: Control


func _ready() -> void:
	theme = ThemeFactory.build_theme()
	_stage = Control.new()
	_stage.name = "AuditStage1280x720"
	_stage.position = Vector2.ZERO
	_stage.size = VIEWPORT_SIZE
	_stage.custom_minimum_size = VIEWPORT_SIZE
	add_child(_stage)

	await _audit_cook_select()
	await _audit_fish_scroll()
	await _audit_exp_gain()
	await _audit_exp_gain_level_up()
	await _audit_meal_result()
	await _audit_level_up()
	await _audit_status_summary()

	if not _failures.is_empty():
		for failure in _failures:
			push_error(String(failure))
		get_tree().quit(1)
		return

	print("Cooking layout audit passed for 5 states plus level-up EXP subcase at 1280x720.")
	get_tree().quit(0)


func _audit_cook_select() -> void:
	_seed_select_state()
	var screen := await _mount_cooking_screen()
	_audit_recipe_grid_shape("COOK_SELECT", screen)
	await _audit_tree("COOK_SELECT", screen)
	_expect_named_control_size("COOK_SELECT", screen, "CookingTitleBanner", Vector2(300.0, 50.0))
	_expect_named_control_size("COOK_SELECT", screen, "FishSectionRibbon", Vector2(230.0, 34.0))
	_expect_named_control_size("COOK_SELECT", screen, "RecipeSectionRibbon", Vector2(360.0, 34.0))
	_expect_named_control_size("COOK_SELECT", screen, "RecipeCard_salt_grill", Vector2(100.0, 100.0))
	_expect_named_control_size("COOK_SELECT", screen, "RecipeTitle_salt_grill", Vector2(70.0, 24.0))
	_expect_named_control_size("COOK_SELECT", screen, "RecipeTitle_sashimi", Vector2(70.0, 24.0))
	_expect_named_control_size("COOK_SELECT", screen, "RecipeTitle_PreviewMeuniere", Vector2(70.0, 24.0))
	_expect_named_control_size("COOK_SELECT", screen, "RecipeDishThumb_salt_grill", Vector2(80.0, 88.0))
	_expect_named_control_size("COOK_SELECT", screen, "RecipeDishImage_salt_grill", Vector2(70.0, 82.0))
	_expect_named_control_size("COOK_SELECT", screen, "RecipeMaterialBadge_salt_grill", Vector2(70.0, 22.0))
	_expect_named_control_size("COOK_SELECT", screen, "RecipeMaterialBadge_sashimi", Vector2(70.0, 22.0))
	_expect_named_control_size("COOK_SELECT", screen, "RecipeMaterialBadge_PreviewMeuniere", Vector2(70.0, 22.0))
	_expect_named_control_size("COOK_SELECT", screen, "RecipeBookButton", Vector2(300.0, 40.0))
	_expect_named_control_size("COOK_SELECT", screen, "RecipeToDetailArrow", Vector2(28.0, 160.0))
	_expect_named_control_size("COOK_SELECT", screen, "SelectedDishFeatureImage", Vector2(260.0, 90.0))
	_expect_named_control_size("COOK_SELECT", screen, "CookDetailMaterialRow", Vector2(220.0, 50.0))
	_expect_named_control_size("COOK_SELECT", screen, "CookDetailExpRow", Vector2(220.0, 50.0))
	_expect_named_control_size("COOK_SELECT", screen, "CookDetailEffectRow", Vector2(220.0, 50.0))
	_expect_named_control_size("COOK_SELECT", screen, "CookActionRunway", Vector2(300.0, 80.0))
	_expect_named_control_size("COOK_SELECT", screen, "FishRowAji", Vector2(230.0, 60.0))
	_expect_named_control_size("COOK_SELECT", screen, "FishRowSaba", Vector2(230.0, 60.0))
	_expect_named_control_size("COOK_SELECT", screen, "FishRowMadai", Vector2(230.0, 60.0))
	_expect_named_control_size("COOK_SELECT", screen, "FishRowKasago", Vector2(230.0, 60.0))
	_expect_named_control_size("COOK_SELECT", screen, "FishRowHirame", Vector2(230.0, 60.0))
	_expect_named_control_size("COOK_SELECT", screen, "FishRowKawahagi", Vector2(230.0, 60.0))
	_expect_named_control_size("COOK_SELECT", screen, "CookActionCue", Vector2(70.0, 14.0))
	_expect_named_control_size("COOK_SELECT", screen, "CookButton", Vector2(250.0, 48.0))
	_expect_named_control_size("COOK_SELECT", screen, "CookingPlayerStatusBar", Vector2(420.0, 52.0))
	_expect_named_control_size("COOK_SELECT", screen, "CurrentPrepBar", Vector2(1100.0, 54.0))
	_expect_named_control_size("COOK_SELECT", screen, "PrepSummaryCardLevel", Vector2(150.0, 52.0))
	_expect_named_control_size("COOK_SELECT", screen, "PrepSummaryCardMeal", Vector2(160.0, 52.0))
	_expect_named_control_size("COOK_SELECT", screen, "PrepSummaryCardFish", Vector2(160.0, 52.0))
	_expect_named_control_size("COOK_SELECT", screen, "PrepSummaryCardMoney", Vector2(150.0, 52.0))
	_expect_absent_named_controls("COOK_SELECT", screen, ["PrepSummaryLevelGauge"])
	screen.queue_free()
	await _tick()


func _audit_fish_scroll() -> void:
	_seed_many_fish_state()
	var screen := await _mount_cooking_screen()
	await _tick()
	var scroll := _find_named(screen, "FishListScroll") as ScrollContainer
	var target := _find_named(screen, "FishRow_medai") as Control
	if scroll == null:
		_failures.append("FISH_SCROLL: missing named control 'FishListScroll'.")
	elif scroll.get_v_scroll_bar().max_value <= scroll.get_v_scroll_bar().page + TOLERANCE:
		_failures.append("FISH_SCROLL: fish list should be vertically scrollable with 70 owned fish.")
	elif scroll.get_h_scroll_bar().max_value > scroll.get_h_scroll_bar().page + TOLERANCE:
		_failures.append("FISH_SCROLL: fish list should not require horizontal scrolling.")
	if target == null:
		_failures.append("FISH_SCROLL: missing fish row beyond the first six owned rows.")
	var row_count := _count_fish_rows(screen)
	if row_count < 70:
		_failures.append("FISH_SCROLL: expected at least 70 fish rows, got %d." % row_count)
	if scroll != null and target != null:
		_expect_visible_fish_rows_fit_width(scroll, "FISH_SCROLL_TOP")
		scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
		await _tick()
		_expect_visible_fish_rows_fit_width(scroll, "FISH_SCROLL_BOTTOM")
		if not scroll.get_global_rect().intersects(target.get_global_rect()):
			_failures.append(
				"FISH_SCROLL: lower owned fish row should be visible after scrolling, got scroll=%s target=%s."
				% [scroll.get_global_rect(), target.get_global_rect()]
			)
	screen.queue_free()
	await _tick()


func _audit_exp_gain() -> void:
	_seed_exp_gain_state()
	var screen := await _mount_cooking_screen()
	screen.preview_show_reward_result(_fake_non_level_result(), 80, 120, 150, false)
	await get_tree().create_timer(0.7).timeout
	await _audit_tree("EXP_GAIN", screen)
	_expect_named_control_size("EXP_GAIN", screen, "RewardStageBackground", Vector2(1280.0, 720.0))
	_expect_named_control_size("EXP_GAIN", screen, "ExpGainBanner", Vector2(360.0, 44.0))
	_expect_named_control_size("EXP_GAIN", screen, "ExpGainTitle", Vector2(220.0, 30.0))
	_expect_named_control_size("EXP_GAIN", screen, "ExpEnergyTrail", Vector2(24.0, 100.0))
	_expect_named_control_size("EXP_GAIN", screen, "ExpBurstFrame", Vector2(320.0, 90.0))
	_expect_named_control_size("EXP_GAIN", screen, "ExpMessagePanel", Vector2(260.0, 42.0))
	_expect_named_control_size("EXP_GAIN", screen, "ExpMessagePortrait", Vector2(60.0, 38.0))
	_expect_named_control_size("EXP_GAIN", screen, "MealTableSpread", Vector2(180.0, 70.0))
	_expect_named_control_size("EXP_GAIN", screen, "NextEffectArt", Vector2(180.0, 42.0))
	_expect_named_controls_hidden(
		"EXP_GAIN",
		screen,
		[
			"RewardCardBaseExp",
			"RewardCardFirstBonus",
			"RewardTotalPeakGlow",
			"RewardCardTotalExp",
			"RewardCardNextEffect",
			"RewardCardGrowth",
			"MealDishCardBridge",
			"MealResultModeTab",
			"MealResultSplitTitle",
			"MealResultRewardCue",
			"MealResultBannerSpark",
			"MealSceneTableBridge",
		]
	)
	_expect_reward_status_strip("EXP_GAIN", screen)
	_expect_named_control_size("EXP_GAIN", screen, "RewardConfirmButton", Vector2(280.0, 34.0))
	screen.queue_free()
	await _tick()


func _audit_exp_gain_level_up() -> void:
	_seed_select_state()
	var screen := await _mount_cooking_screen()
	var result := _fake_level_result()
	_seed_after_meal_state()
	screen.preview_show_reward_result(result, 130, 150, 150, true)
	await get_tree().create_timer(0.7).timeout
	await _audit_tree("EXP_GAIN_LEVELUP", screen)
	_expect_named_control_size("EXP_GAIN_LEVELUP", screen, "RewardStageBackground", Vector2(1280.0, 720.0))
	_expect_named_control_size("EXP_GAIN_LEVELUP", screen, "ExpGainBanner", Vector2(360.0, 44.0))
	_expect_named_control_size("EXP_GAIN_LEVELUP", screen, "ExpGainTitle", Vector2(220.0, 30.0))
	_expect_named_control_size("EXP_GAIN_LEVELUP", screen, "ExpEnergyTrail", Vector2(24.0, 100.0))
	_expect_named_control_size("EXP_GAIN_LEVELUP", screen, "ExpBurstFrame", Vector2(320.0, 90.0))
	_expect_named_control_size("EXP_GAIN_LEVELUP", screen, "ExpMessagePanel", Vector2(260.0, 42.0))
	_expect_named_control_size("EXP_GAIN_LEVELUP", screen, "ExpMessagePortrait", Vector2(60.0, 38.0))
	_expect_named_control_size("EXP_GAIN_LEVELUP", screen, "MealTableSpread", Vector2(180.0, 70.0))
	_expect_named_control_size("EXP_GAIN_LEVELUP", screen, "NextEffectArt", Vector2(180.0, 42.0))
	_expect_named_controls_hidden(
		"EXP_GAIN_LEVELUP",
		screen,
		[
			"RewardCardBaseExp",
			"RewardCardFirstBonus",
			"RewardTotalPeakGlow",
			"RewardCardTotalExp",
			"RewardCardNextEffect",
			"RewardCardGrowth",
			"MealDishCardBridge",
			"MealResultModeTab",
			"MealResultSplitTitle",
			"MealResultRewardCue",
			"MealResultBannerSpark",
			"MealSceneTableBridge",
		]
	)
	_expect_reward_status_strip("EXP_GAIN_LEVELUP", screen)
	_expect_named_control_size("EXP_GAIN_LEVELUP", screen, "RewardConfirmButton", Vector2(280.0, 34.0))
	screen.queue_free()
	await _tick()


func _audit_meal_result() -> void:
	_seed_select_state()
	var screen := await _mount_cooking_screen()
	var result := _fake_level_result()
	_seed_after_meal_state()
	screen.preview_show_meal_reward_result(result, true)
	await get_tree().create_timer(0.7).timeout
	await _audit_tree("MEAL_RESULT", screen)
	_expect_named_control_size("MEAL_RESULT", screen, "MealResultBanner", Vector2(520.0, 44.0))
	_expect_named_control_size("MEAL_RESULT", screen, "MealResultBannerSpark", Vector2(520.0, 44.0))
	_expect_named_control_size("MEAL_RESULT", screen, "MealResultModeTab", Vector2(70.0, 20.0))
	_expect_named_control_size("MEAL_RESULT", screen, "MealResultSplitTitle", Vector2(520.0, 44.0))
	_expect_named_control_size("MEAL_RESULT", screen, "MealResultTitle", Vector2(240.0, 30.0))
	_expect_named_control_size("MEAL_RESULT", screen, "MealSceneVisualStack", Vector2(380.0, 280.0))
	_expect_named_control_size("MEAL_RESULT", screen, "MealSceneActor", Vector2(90.0, 70.0))
	_expect_named_control_size("MEAL_RESULT", screen, "MealSceneTableBridge", Vector2(380.0, 280.0))
	_expect_named_control_size("MEAL_RESULT", screen, "MealTableSpread", Vector2(250.0, 130.0))
	_expect_named_control_size("MEAL_RESULT", screen, "MealDishCard", Vector2(420.0, 90.0))
	_expect_named_control_size("MEAL_RESULT", screen, "MealDishCardBridge", Vector2(420.0, 90.0))
	_expect_named_control_size("MEAL_RESULT", screen, "MealResultRewardCue", Vector2(520.0, 12.0))
	_expect_named_control_size("MEAL_RESULT", screen, "RewardDishFeatureImage", Vector2(200.0, 70.0))
	_expect_named_control_size("MEAL_RESULT", screen, "RewardBuffSignal", Vector2(48.0, 40.0))
	_expect_named_control_size("MEAL_RESULT", screen, "RewardBuffEffectPlate", Vector2(200.0, 50.0))
	_expect_named_control_size("MEAL_RESULT", screen, "RewardCardBaseExp", Vector2(230.0, 96.0))
	_expect_named_control_size("MEAL_RESULT", screen, "RewardCardFirstBonus", Vector2(230.0, 96.0))
	_expect_named_control_size("MEAL_RESULT", screen, "RewardCardTotalExp", Vector2(230.0, 96.0))
	_expect_named_control_size("MEAL_RESULT", screen, "RewardTotalPeakGlow", Vector2(210.0, 86.0))
	_expect_named_control_size("MEAL_RESULT", screen, "RewardCardNextEffect", Vector2(230.0, 96.0))
	_expect_reward_status_strip("MEAL_RESULT", screen)
	_expect_named_control_size("MEAL_RESULT", screen, "RewardConfirmButton", Vector2(420.0, 46.0))
	_expect_named_controls_hidden(
		"MEAL_RESULT",
		screen,
		[
			"RewardFlowRow",
			"FlowStep_0",
			"FlowStep_1",
			"FlowStep_2",
			"MealSceneTitle",
			"MealSceneCaption",
			"MealSceneBonusBadge",
		]
	)
	screen.queue_free()
	await _tick()


func _audit_level_up() -> void:
	var panel := LevelUpPanelScript.new()
	panel.theme = ThemeFactory.build_theme()
	panel.size = VIEWPORT_SIZE
	_stage.add_child(panel)
	await _tick()
	panel.show_level_up(4, 5, _old_stats(), PlayerProgress.get_base_stats())
	await get_tree().create_timer(0.45).timeout
	await _audit_tree("LEVEL_UP_OVERLAY", panel)
	_expect_named_control_size("LEVEL_UP_OVERLAY", panel, "LevelUpDimmer", Vector2(1280.0, 720.0))
	_expect_named_control_size("LEVEL_UP_OVERLAY", panel, "LevelUpDialog", Vector2(850.0, 480.0))
	_expect_named_control_size("LEVEL_UP_OVERLAY", panel, "LevelUpTitleBand", Vector2(760.0, 80.0))
	_expect_named_control_size("LEVEL_UP_OVERLAY", panel, "LevelUpTitle", Vector2(320.0, 56.0))
	_expect_named_control_size("LEVEL_UP_OVERLAY", panel, "LevelUpLevelLine", Vector2(260.0, 36.0))
	_expect_named_control_size("LEVEL_UP_OVERLAY", panel, "LevelUpSourceLine", Vector2(260.0, 24.0))
	_expect_named_control_size("LEVEL_UP_OVERLAY", panel, "LevelCrownAsset", Vector2(120.0, 28.0))
	_expect_named_control_size("LEVEL_UP_OVERLAY", panel, "LevelLaurelLeftAsset", Vector2(80.0, 60.0))
	_expect_named_control_size("LEVEL_UP_OVERLAY", panel, "LevelLaurelRightAsset", Vector2(80.0, 60.0))
	_expect_named_control_size("LEVEL_UP_OVERLAY", panel, "LevelUnlockMedallionAsset", Vector2(90.0, 70.0))
	_expect_named_control_size("LEVEL_UP_OVERLAY", panel, "LevelUnlockSpotAsset", Vector2(150.0, 42.0))
	_expect_named_control_size("LEVEL_UP_OVERLAY", panel, "LevelUnlockRibbonAsset", Vector2(760.0, 28.0))
	_expect_named_control_size("LEVEL_UP_OVERLAY", panel, "LevelStatRowEnergy", Vector2(260.0, 42.0))
	_expect_named_control_size("LEVEL_UP_OVERLAY", panel, "LevelStatRowReel", Vector2(260.0, 42.0))
	_expect_named_control_size("LEVEL_UP_OVERLAY", panel, "LevelStatRowTechnique", Vector2(260.0, 42.0))
	_expect_named_control_size("LEVEL_UP_OVERLAY", panel, "LevelStatRowFocus", Vector2(260.0, 42.0))
	_expect_named_control_size("LEVEL_UP_OVERLAY", panel, "LevelToSummaryCue", Vector2(160.0, 18.0))
	_expect_named_control_size("LEVEL_UP_OVERLAY", panel, "LevelUpConfirmButton", Vector2(260.0, 40.0))
	panel.queue_free()
	await _tick()


func _audit_status_summary() -> void:
	_seed_after_meal_state()
	var screen := await _mount_cooking_screen()
	screen.preview_show_status_overlay()
	await get_tree().create_timer(0.4).timeout
	await _audit_tree("STATUS_SUMMARY", screen)
	_expect_named_control_size("STATUS_SUMMARY", screen, "StatusSummaryBackground", Vector2(1280.0, 720.0))
	_expect_named_control_size("STATUS_SUMMARY", screen, "StatusTitle", Vector2(190.0, 42.0))
	_expect_named_control_size("STATUS_SUMMARY", screen, "StatusHeaderPlayerBadge", Vector2(30.0, 30.0))
	_expect_named_control_size("STATUS_SUMMARY", screen, "StatusHeaderExpBox", Vector2(360.0, 42.0))
	_expect_named_control_size("STATUS_SUMMARY", screen, "StatusHeaderLevel", Vector2(50.0, 24.0))
	_expect_named_control_size("STATUS_SUMMARY", screen, "StatusHeaderExpBar", Vector2(110.0, 16.0))
	_expect_named_control_size("STATUS_SUMMARY", screen, "StatusHeaderExpValue", Vector2(70.0, 20.0))
	_expect_named_control_size("STATUS_SUMMARY", screen, "StatusCardPlayer", Vector2(190.0, 360.0))
	_expect_named_control_size("STATUS_SUMMARY", screen, "StatusCardMeal", Vector2(190.0, 360.0))
	_expect_named_control_size("STATUS_SUMMARY", screen, "StatusCardCooler", Vector2(190.0, 360.0))
	_expect_named_control_size("STATUS_SUMMARY", screen, "StatusCardMoney", Vector2(190.0, 360.0))
	_expect_named_control_size("STATUS_SUMMARY", screen, "StatusCardPlayTime", Vector2(190.0, 360.0))
	_expect_named_control_size("STATUS_SUMMARY", screen, "StatusMealDishImage", Vector2(150.0, 110.0))
	_expect_named_control_size("STATUS_SUMMARY", screen, "StatusCoolerArt", Vector2(120.0, 110.0))
	_expect_named_control_size("STATUS_SUMMARY", screen, "StatusMoneyArt", Vector2(120.0, 110.0))
	_expect_named_control_size("STATUS_SUMMARY", screen, "StatusClockArt", Vector2(120.0, 110.0))
	_expect_named_control_size("STATUS_SUMMARY", screen, "StatusMealEffectCue", Vector2(28.0, 28.0))
	_expect_named_control_size("STATUS_SUMMARY", screen, "StatusReturnButton", Vector2(150.0, 34.0))
	screen.queue_free()
	await _tick()


func _mount_cooking_screen() -> Control:
	var screen := CookingScreen.new()
	screen.theme = ThemeFactory.build_theme()
	screen.configure({"suppress_level_overlay": true})
	screen.size = VIEWPORT_SIZE
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stage.add_child(screen)
	await _tick()
	return screen


func _audit_tree(state: String, root: Control) -> void:
	await _tick()
	if OS.get_environment("COOKING_LAYOUT_AUDIT_DEBUG") == "1":
		_debug_top_level(state, root)
	if OS.get_environment("COOKING_LAYOUT_AUDIT_DEBUG_LABELS") == "1":
		_debug_named_controls(
			state,
			root,
			[
				"ExpGainBanner",
				"ExpGainTitle",
				"ExpFocusTag",
				"ExpGainValue",
				"ExpProgressText",
				"ExpBurstFrame",
				"ExpMessagePanel",
				"LevelUpTitle",
				"LevelUpLevelLine",
				"LevelUpSourceLine",
				"LevelUnlockRibbonAsset",
				"LevelUnlockRibbonLabel",
				"LevelStatNameEnergy",
				"LevelStatValuesEnergy",
				"LevelStatGainEnergy",
				"LevelUnlockTitle",
				"LevelUnlockBody",
				"StatusTitle",
			]
		)
	var nodes: Array = []
	_collect_controls(root, nodes)
	for node in nodes:
		var control := node as Control
		if control == null or not control.is_visible_in_tree():
			continue
		_audit_bounds(state, control)
		if control is Label:
			_audit_label(state, control as Label)
		elif control is Button:
			_audit_button(state, control as Button)
		elif control is TextureRect:
			_audit_texture(state, control as TextureRect)


func _collect_controls(node: Node, out: Array) -> void:
	if node is Control:
		out.append(node)
	for child in node.get_children():
		_collect_controls(child, out)


func _audit_bounds(state: String, control: Control) -> void:
	if control == self or control == _stage:
		return
	var rect := control.get_global_rect()
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		_failures.append("%s: %s has non-positive size %s" % [state, _node_path(control), rect])
		return
	if rect.position.x < -TOLERANCE or rect.position.y < -TOLERANCE:
		_failures.append("%s: %s starts outside viewport at %s" % [state, _node_path(control), rect])
	if rect.end.x > VIEWPORT_SIZE.x + TOLERANCE or rect.end.y > VIEWPORT_SIZE.y + TOLERANCE:
		_failures.append("%s: %s ends outside viewport at %s" % [state, _node_path(control), rect])


func _audit_label(state: String, label: Label) -> void:
	if label.text.strip_edges().is_empty():
		return
	var rect := label.get_global_rect()
	var font_size: int = maxi(1, label.get_theme_font_size("font_size"))
	var line_count: int = maxi(1, label.get_line_count())
	var outline: int = label.get_theme_constant("outline_size")
	var needed_height := float(font_size * line_count) * 1.18 + float(outline * 2)
	if rect.size.y + TOLERANCE < needed_height:
		_failures.append(
			"%s: label %s may clip vertically: text='%s' size=%s needed_h=%.1f lines=%d"
			% [state, _node_path(label), _trim(label.text), rect.size, needed_height, line_count]
		)
	if label.autowrap_mode == TextServer.AUTOWRAP_OFF:
		var font := label.get_theme_font("font")
		if font != null:
			var needed_width := _label_text_width(label, font, font_size) + float(outline * 2)
			if rect.size.x + TOLERANCE < needed_width:
				_failures.append(
					"%s: label %s may clip horizontally: text='%s' size=%s needed_w=%.1f"
					% [state, _node_path(label), _trim(label.text), rect.size, needed_width]
				)


func _label_text_width(label: Label, font: Font, font_size: int) -> float:
	var max_width := 0.0
	for line in label.text.split("\n"):
		var line_width := font.get_string_size(String(line), HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
		max_width = maxf(max_width, line_width)
	return max_width


func _audit_button(state: String, button: Button) -> void:
	if button.text.strip_edges().is_empty():
		return
	var rect := button.get_global_rect()
	var min_size := button.get_combined_minimum_size()
	if rect.size.x + TOLERANCE < min_size.x or rect.size.y + TOLERANCE < min_size.y:
		_failures.append(
			"%s: button %s smaller than minimum: text='%s' size=%s min=%s"
			% [state, _node_path(button), _trim(button.text), rect.size, min_size]
		)


func _audit_texture(state: String, texture_rect: TextureRect) -> void:
	if texture_rect.texture == null and texture_rect.get_global_rect().size.length() > 32.0:
		_failures.append("%s: texture missing at %s" % [state, _node_path(texture_rect)])


func _debug_top_level(state: String, root: Control) -> void:
	var margin := _find_first(root, "MarginContainer") as MarginContainer
	if margin == null or margin.get_child_count() <= 0:
		return
	var layout := margin.get_child(0) as Container
	if layout == null:
		return
	print("%s root=%s layout=%s" % [state, margin.get_global_rect(), layout.get_global_rect()])
	for child in layout.get_children():
		if child is Control:
			var control := child as Control
			print("  %s %s min=%s" % [control.get_class(), control.get_global_rect(), control.get_combined_minimum_size()])
			for grandchild in control.get_children():
				if grandchild is Control:
					var grand_control := grandchild as Control
					print("    %s %s min=%s" % [grand_control.get_class(), grand_control.get_global_rect(), grand_control.get_combined_minimum_size()])


func _debug_named_controls(state: String, root: Node, node_names: Array) -> void:
	for node_name in node_names:
		var node := _find_named(root, String(node_name))
		var control := node as Control
		if control == null:
			continue
		var label := control as Label
		var text := ""
		if label != null:
			text = label.text
		print(
			"%s DEBUG %s rect=%s min=%s visible=%s modulate=%s text='%s'"
			% [
				state,
				String(node_name),
				control.get_global_rect(),
				control.get_combined_minimum_size(),
				control.is_visible_in_tree(),
				control.modulate,
				_trim(text),
			]
		)


func _audit_recipe_grid_shape(state: String, root: Node) -> void:
	var grid := _find_named(root, "RecipeGrid") as GridContainer
	if grid == null:
		_failures.append("%s: RecipeGrid is missing." % state)
		return
	if grid.columns != 3:
		_failures.append("%s: RecipeGrid should use 3 columns, got %d." % [state, grid.columns])
	var card_count := 0
	for child in grid.get_children():
		if child is Control and String((child as Control).name).begins_with("RecipeCard_"):
			card_count += 1
	if card_count < 6:
		_failures.append("%s: RecipeGrid should expose at least 6 recipe cards, got %d." % [state, card_count])


func _expect_named_control_size(
	state: String, root: Node, node_name: String, min_size: Vector2
) -> void:
	var node := _find_named(root, node_name)
	if node == null:
		_failures.append("%s: missing named control '%s'." % [state, node_name])
		return
	var control := node as Control
	if control == null:
		_failures.append("%s: node '%s' is not a Control." % [state, node_name])
		return
	if not control.is_visible_in_tree():
		_failures.append("%s: named control '%s' is not visible." % [state, node_name])
		return
	var rect := control.get_global_rect()
	if rect.size.x + TOLERANCE < min_size.x or rect.size.y + TOLERANCE < min_size.y:
		_failures.append(
			"%s: named control '%s' too small: size=%s min=%s"
			% [state, node_name, rect.size, min_size]
		)


func _expect_named_controls_hidden(state: String, root: Node, node_names: Array) -> void:
	for node_name in node_names:
		var node := _find_named(root, String(node_name))
		if node == null:
			_failures.append("%s: missing named control '%s'." % [state, String(node_name)])
			continue
		var control := node as Control
		if control == null:
			_failures.append("%s: node '%s' is not a Control." % [state, String(node_name)])
			continue
		if control.is_visible_in_tree():
			_failures.append(
				"%s: named control '%s' should be hidden in this composition."
				% [state, String(node_name)]
			)


func _expect_absent_named_controls(state: String, root: Node, node_names: Array) -> void:
	for node_name in node_names:
		if _find_named(root, String(node_name)) != null:
			_failures.append("%s: forbidden named control '%s' is present." % [state, String(node_name)])


func _expect_reward_status_strip(state: String, root: Node) -> void:
	_expect_named_control_size(state, root, "RewardStatusStrip", Vector2(700.0, 56.0))
	_expect_named_control_size(state, root, "RewardStatusLevelCard", Vector2(190.0, 54.0))
	_expect_named_control_size(state, root, "RewardStatusMealCard", Vector2(240.0, 54.0))
	_expect_named_control_size(state, root, "RewardStatusCoolerCard", Vector2(180.0, 54.0))
	_expect_named_control_size(state, root, "RewardStatusMoneyCard", Vector2(170.0, 54.0))
	_expect_named_control_size(state, root, "RewardStatusLevelIcon", Vector2(38.0, 38.0))
	_expect_named_control_size(state, root, "RewardStatusMealIcon", Vector2(38.0, 38.0))
	_expect_named_control_size(state, root, "RewardStatusCoolerIcon", Vector2(38.0, 38.0))
	_expect_named_control_size(state, root, "RewardStatusMoneyIcon", Vector2(38.0, 38.0))
	_expect_named_control_size(state, root, "RewardStatusLevelExpBar", Vector2(70.0, 7.0))


func _find_named(node: Node, node_name: String) -> Node:
	if node.name == node_name:
		return node
	for child in node.get_children():
		var found := _find_named(child, node_name)
		if found != null:
			return found
	return null


func _count_fish_rows(node: Node) -> int:
	var count := 0
	if node is Control and String((node as Control).name).begins_with("FishRow"):
		count += 1
	for child in node.get_children():
		count += _count_fish_rows(child)
	return count


func _expect_visible_fish_rows_fit_width(scroll: ScrollContainer, state: String) -> void:
	var scroll_rect := scroll.get_global_rect()
	var rows: Array = []
	_collect_fish_rows(scroll, rows)
	for node in rows:
		var row := node as Control
		if row == null or not row.is_visible_in_tree():
			continue
		var rect := row.get_global_rect()
		if not scroll_rect.intersects(rect):
			continue
		if rect.position.x < scroll_rect.position.x - TOLERANCE:
			_failures.append("%s: %s starts left of fish scroll frame: row=%s scroll=%s." % [state, row.name, rect, scroll_rect])
		if rect.end.x > scroll_rect.end.x + TOLERANCE:
			_failures.append("%s: %s ends right of fish scroll frame: row=%s scroll=%s." % [state, row.name, rect, scroll_rect])


func _collect_fish_rows(node: Node, out: Array) -> void:
	if node is Control and String((node as Control).name).begins_with("FishRow"):
		out.append(node)
	for child in node.get_children():
		_collect_fish_rows(child, out)


func _find_first(node: Node, class_name_text: String) -> Node:
	if node.is_class(class_name_text):
		return node
	for child in node.get_children():
		var found := _find_first(child, class_name_text)
		if found != null:
			return found
	return null


func _tick() -> void:
	await get_tree().process_frame
	await get_tree().process_frame


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
	PlayerProgress.pending_buff = {
		"recipe_id": "simmered",
		"name": "サバの味噌煮",
		"stat": "safe_range",
		"value": 0.05,
		"text": "次の釣行で安全テンション域 +5%",
	}


func _seed_many_fish_state() -> void:
	_seed_select_state()
	for fish_id in GameData.get_all_fish_ids():
		PlayerProgress.inventory[fish_id] = 1


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


func _node_path(control: Control) -> String:
	return str(control.get_path())


func _trim(value: String) -> String:
	var single_line := value.replace("\n", " ").strip_edges()
	if single_line.length() > 36:
		return single_line.substr(0, 33) + "..."
	return single_line
