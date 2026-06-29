extends Control
## 調理フロー5状態のheadless表示内容監査。
# スクリーンショット取得前でも、状態ごとの必須情報が表示テキストとして
# 画面上に出ていることを検証する。
const ThemeFactory = preload("res://src/ui/ui_theme.gd")
const CookingScreen = preload("res://src/ui/cooking_screen.gd")
const LevelUpPanelScript = preload("res://src/ui/components/level_up_panel.gd")
const CookingStatusPanelScript = preload("res://src/ui/components/cooking_status_panel.gd")

const VIEWPORT_SIZE := Vector2(1280.0, 720.0)

var _failures: Array[String] = []
var _stage: Control


func _ready() -> void:
	theme = ThemeFactory.build_theme()
	_stage = Control.new()
	_stage.name = "ContentAuditStage1280x720"
	_stage.position = Vector2.ZERO
	_stage.size = VIEWPORT_SIZE
	_stage.custom_minimum_size = VIEWPORT_SIZE
	add_child(_stage)

	_audit_required_assets()
	await _audit_cook_select()
	await _audit_exp_gain()
	await _audit_exp_gain_level_up()
	await _audit_meal_result()
	await _audit_level_up()
	await _audit_status_summary()

	if not _failures.is_empty():
		for failure in _failures:
			push_error(failure)
		get_tree().quit(1)
		return

	print("Cooking content audit passed for 5 states plus level-up EXP subcase.")
	get_tree().quit(0)


func _audit_required_assets() -> void:
	var paths := [
		"res://assets/showcase/cooking/cooking_room_bg.png",
		"res://assets/showcase/cooking/cooking_title_banner.png",
		"res://assets/showcase/cooking/cooking_section_ribbon.png",
		"res://assets/showcase/cooking/meal_scene_bg.png",
		"res://assets/showcase/cooking/exp_stage_bg.png",
		"res://assets/showcase/cooking/fish_icon_sheet.png",
		"res://assets/showcase/cooking/fish_row_frame.png",
		"res://assets/showcase/cooking/dish_icon_sheet.png",
		"res://assets/showcase/cooking/dish_feature_aji_shioyaki.png",
		"res://assets/showcase/cooking/player_eating_pose_pixel_tight.png",
		"res://assets/showcase/cooking/player_eating_upper_scene.png",
		"res://assets/showcase/cooking/meal_table_spread.png",
		"res://assets/showcase/cooking/player_exp_message_pose_pixel.png",
		"res://assets/showcase/cooking/player_exp_pose_pixel_tight.png",
		"res://assets/showcase/cooking/next_effect_art.png",
		"res://assets/showcase/cooking/status_summary_bg.png",
		"res://assets/showcase/cooking/player_status_portrait_pixel.png",
		"res://assets/showcase/cooking/status_cooler_art.png",
		"res://assets/showcase/cooking/status_money_art.png",
		"res://assets/showcase/cooking/status_clock_art.png",
		"res://assets/showcase/cooking/recipe_grid_frame.png",
		"res://assets/showcase/cooking/recipe_card_frame.png",
		"res://assets/showcase/cooking/recipe_selected_card_frame.png",
		"res://assets/showcase/cooking/recipe_dish_thumb_frame.png",
		"res://assets/showcase/cooking/recipe_material_strip_frame.png",
		"res://assets/showcase/cooking/recipe_to_detail_arrow.png",
		"res://assets/showcase/cooking/dish_detail_frame.png",
		"res://assets/showcase/cooking/cook_detail_row_frame.png",
		"res://assets/showcase/cooking/cook_button_frame.png",
		"res://assets/showcase/cooking/cook_action_runway_frame.png",
		"res://assets/showcase/cooking/prep_summary_bar_frame.png",
		"res://assets/showcase/cooking/prep_summary_card_frame.png",
		"res://assets/showcase/cooking/flow_action_button_frame.png",
		"res://assets/showcase/cooking/meal_result_frame.png",
		"res://assets/showcase/cooking/meal_banner_frame.png",
		"res://assets/showcase/cooking/meal_dish_card_frame.png",
		"res://assets/showcase/cooking/reward_card_frame.png",
		"res://assets/showcase/cooking/exp_burst_frame.png",
		"res://assets/showcase/cooking/level_up_frame.png",
		"res://assets/showcase/cooking/level_crown.png",
		"res://assets/showcase/cooking/level_laurel_left.png",
		"res://assets/showcase/cooking/level_laurel_right.png",
		"res://assets/showcase/cooking/level_unlock_medallion.png",
		"res://assets/showcase/cooking/level_unlock_spot.png",
		"res://assets/showcase/cooking/level_unlock_ribbon.png",
		"res://assets/showcase/cooking/level_stat_row_frame.png",
		"res://assets/showcase/cooking/status_card_frame.png",
		"res://assets/showcase/cooking/cooking_icon_sheet.png",
	]
	var expected_sizes := {
		"res://assets/showcase/cooking/cooking_room_bg.png": Vector2i(1280, 720),
		"res://assets/showcase/cooking/cooking_title_banner.png": Vector2i(420, 110),
		"res://assets/showcase/cooking/cooking_section_ribbon.png": Vector2i(520, 72),
		"res://assets/showcase/cooking/meal_scene_bg.png": Vector2i(1280, 720),
		"res://assets/showcase/cooking/exp_stage_bg.png": Vector2i(1280, 720),
		"res://assets/showcase/cooking/fish_icon_sheet.png": Vector2i(192, 528),
		"res://assets/showcase/cooking/fish_row_frame.png": Vector2i(340, 82),
		"res://assets/showcase/cooking/dish_icon_sheet.png": Vector2i(660, 300),
		"res://assets/showcase/cooking/dish_feature_aji_shioyaki.png": Vector2i(620, 330),
		"res://assets/showcase/cooking/player_eating_pose_pixel_tight.png": Vector2i(190, 280),
		"res://assets/showcase/cooking/player_eating_upper_scene.png": Vector2i(250, 185),
		"res://assets/showcase/cooking/meal_table_spread.png": Vector2i(420, 190),
		"res://assets/showcase/cooking/player_exp_message_pose_pixel.png": Vector2i(180, 130),
		"res://assets/showcase/cooking/player_exp_pose_pixel_tight.png": Vector2i(150, 190),
		"res://assets/showcase/cooking/next_effect_art.png": Vector2i(280, 120),
		"res://assets/showcase/cooking/status_summary_bg.png": Vector2i(1280, 720),
		"res://assets/showcase/cooking/player_status_portrait_pixel.png": Vector2i(240, 240),
		"res://assets/showcase/cooking/status_cooler_art.png": Vector2i(260, 170),
		"res://assets/showcase/cooking/status_money_art.png": Vector2i(260, 170),
		"res://assets/showcase/cooking/status_clock_art.png": Vector2i(260, 170),
		"res://assets/showcase/cooking/recipe_grid_frame.png": Vector2i(460, 560),
		"res://assets/showcase/cooking/recipe_card_frame.png": Vector2i(280, 220),
		"res://assets/showcase/cooking/recipe_selected_card_frame.png": Vector2i(280, 220),
		"res://assets/showcase/cooking/recipe_dish_thumb_frame.png": Vector2i(260, 170),
		"res://assets/showcase/cooking/recipe_material_strip_frame.png": Vector2i(240, 54),
		"res://assets/showcase/cooking/recipe_to_detail_arrow.png": Vector2i(96, 220),
		"res://assets/showcase/cooking/dish_detail_frame.png": Vector2i(620, 560),
		"res://assets/showcase/cooking/cook_detail_row_frame.png": Vector2i(560, 46),
		"res://assets/showcase/cooking/cook_button_frame.png": Vector2i(360, 82),
		"res://assets/showcase/cooking/cook_action_runway_frame.png": Vector2i(560, 88),
		"res://assets/showcase/cooking/prep_summary_bar_frame.png": Vector2i(1280, 92),
		"res://assets/showcase/cooking/prep_summary_card_frame.png": Vector2i(340, 62),
		"res://assets/showcase/cooking/flow_action_button_frame.png": Vector2i(380, 88),
		"res://assets/showcase/cooking/meal_result_frame.png": Vector2i(760, 240),
		"res://assets/showcase/cooking/meal_banner_frame.png": Vector2i(760, 128),
		"res://assets/showcase/cooking/meal_dish_card_frame.png": Vector2i(760, 170),
		"res://assets/showcase/cooking/reward_card_frame.png": Vector2i(360, 150),
		"res://assets/showcase/cooking/exp_burst_frame.png": Vector2i(760, 220),
		"res://assets/showcase/cooking/level_up_frame.png": Vector2i(680, 460),
		"res://assets/showcase/cooking/level_crown.png": Vector2i(220, 96),
		"res://assets/showcase/cooking/level_laurel_left.png": Vector2i(140, 120),
		"res://assets/showcase/cooking/level_laurel_right.png": Vector2i(140, 120),
		"res://assets/showcase/cooking/level_unlock_medallion.png": Vector2i(150, 150),
		"res://assets/showcase/cooking/level_unlock_spot.png": Vector2i(260, 110),
		"res://assets/showcase/cooking/level_unlock_ribbon.png": Vector2i(760, 72),
		"res://assets/showcase/cooking/level_stat_row_frame.png": Vector2i(420, 76),
		"res://assets/showcase/cooking/status_card_frame.png": Vector2i(320, 120),
		"res://assets/showcase/cooking/cooking_icon_sheet.png": Vector2i(960, 96),
	}
	for path in paths:
		if not ResourceLoader.exists(path):
			_failures.append("ASSETS: missing or unimported required cooking asset '%s'." % path)
			continue
		var texture := load(path) as Texture2D
		if texture == null:
			_failures.append("ASSETS: required cooking asset '%s' is not a Texture2D." % path)
			continue
		if expected_sizes.has(path):
			var expected: Vector2i = expected_sizes[path]
			var actual := Vector2i(texture.get_width(), texture.get_height())
			if actual != expected:
				_failures.append(
					"ASSETS: cooking asset '%s' should be %s, got %s." % [path, expected, actual]
				)


func _audit_cook_select() -> void:
	_seed_select_state()
	var screen := await _mount_cooking_screen()
	await _expect_texts(
		"COOK_SELECT",
		screen,
		[
			"調理場",
			"所持している魚",
			"料理を選ぶ",
			"アジの塩焼き",
			"★★",
			"★★★",
			"煮付け",
			"別素材",
			"魚フライ",
			"Lv.5",
			"ヒラメのムニエル",
			"Lv.6",
			"料理図鑑を見る",
			"×1",
			"必要な材料",
			"アジ ×1",
			"4 → 3",
			"獲得EXP",
			"+40 EXP",
			"初回",
			"+20 EXP",
			"次の釣行で得られる効果",
			"次の釣行で最大体力 +5%",
			"1回",
			"調理後は食事結果へ",
			"調理する",
			"現在の準備",
		]
	)
	await _expect_absent_texts(
		"EXP_GAIN",
		screen,
		[
			"PLAYER",
			"DISH",
			"POWER",
			"EATING",
		]
	)
	await _expect_absent_texts(
		"STATUS_SUMMARY",
		screen,
		[
			"STATUS",
			"PLAYER",
			"COOLER",
			"GOLD",
			"TIME",
			"READY",
		]
	)
	_expect_named_node("COOK_SELECT", screen, "CookActionCue")
	_expect_named_node("COOK_SELECT", screen, "CookButton")
	_expect_button_texture_style(
		"COOK_SELECT",
		screen,
		"CookButton",
		"res://assets/showcase/cooking/cook_button_frame.png"
	)
	_expect_named_node("COOK_SELECT", screen, "CookingTitleBanner")
	_expect_named_node("COOK_SELECT", screen, "FishSectionRibbon")
	_expect_named_node("COOK_SELECT", screen, "RecipeSectionRibbon")
	_expect_named_node("COOK_SELECT", screen, "RecipeCard_salt_grill")
	_expect_named_node("COOK_SELECT", screen, "RecipeDishThumb_salt_grill")
	_expect_named_node("COOK_SELECT", screen, "RecipeDishImage_salt_grill")
	_expect_texture_rect_path(
		"COOK_SELECT",
		screen,
		"RecipeDishImage_salt_grill",
		"res://assets/showcase/cooking/dish_feature_aji_shioyaki.png"
	)
	_expect_named_node("COOK_SELECT", screen, "RecipeMaterialBadge_salt_grill")
	_expect_named_node("COOK_SELECT", screen, "RecipeMaterialBadge_sashimi")
	_expect_named_node("COOK_SELECT", screen, "RecipeMaterialBadge_simmered")
	_expect_named_node("COOK_SELECT", screen, "RecipeMaterialBadge_PreviewMeuniere")
	_expect_named_node("COOK_SELECT", screen, "RecipeMaterialIcon_salt_grill")
	_expect_named_node("COOK_SELECT", screen, "RecipeMaterialIcon_sashimi")
	_expect_named_node("COOK_SELECT", screen, "RecipeMaterialIcon_simmered")
	_expect_named_node("COOK_SELECT", screen, "RecipeMaterialIcon_PreviewMeuniere")
	_expect_named_node("COOK_SELECT", screen, "RecipeCard_PreviewMeuniere")
	_expect_named_node("COOK_SELECT", screen, "RecipeBookButton")
	_expect_named_node("COOK_SELECT", screen, "RecipeToDetailArrow")
	_expect_named_node("COOK_SELECT", screen, "CookDetailMaterialRow")
	_expect_named_node("COOK_SELECT", screen, "CookDetailExpRow")
	_expect_named_node("COOK_SELECT", screen, "CookDetailEffectRow")
	_expect_panel_texture_style(
		"COOK_SELECT",
		screen,
		"CookDetailMaterialRow",
		"res://assets/showcase/cooking/cook_detail_row_frame.png"
	)
	_expect_panel_texture_style(
		"COOK_SELECT",
		screen,
		"CookDetailExpRow",
		"res://assets/showcase/cooking/cook_detail_row_frame.png"
	)
	_expect_panel_texture_style(
		"COOK_SELECT",
		screen,
		"CookDetailEffectRow",
		"res://assets/showcase/cooking/cook_detail_row_frame.png"
	)
	_expect_named_node("COOK_SELECT", screen, "CookActionRunway")
	_expect_named_node("COOK_SELECT", screen, "CurrentPrepBar")
	_expect_named_node("COOK_SELECT", screen, "CurrentPrepTitle")
	_expect_named_node("COOK_SELECT", screen, "PrepSummaryCardLevel")
	_expect_named_node("COOK_SELECT", screen, "PrepSummaryCardMeal")
	_expect_named_node("COOK_SELECT", screen, "PrepSummaryCardFish")
	_expect_named_node("COOK_SELECT", screen, "PrepSummaryCardMoney")
	_expect_named_node("COOK_SELECT", screen, "CurrentPrepDetailButton")
	_expect_texture_rect_path(
		"COOK_SELECT",
		screen,
		"SelectedDishFeatureImage",
		"res://assets/showcase/cooking/dish_feature_aji_shioyaki.png"
	)
	_expect_named_node("COOK_SELECT", screen, "FishRowAji")
	_expect_named_node("COOK_SELECT", screen, "FishRowSaba")
	_expect_named_node("COOK_SELECT", screen, "FishRowKasago")
	_expect_named_node("COOK_SELECT", screen, "FishRowMejina")
	_expect_named_node("COOK_SELECT", screen, "FishRowIsaki")
	screen.queue_free()
	await _tick()


func _audit_exp_gain() -> void:
	_seed_exp_gain_state()
	var screen := await _mount_cooking_screen()
	screen.preview_show_reward_result(_fake_non_level_result(), 80, 120, 150, false)
	await get_tree().create_timer(0.7).timeout
	await _expect_texts(
		"EXP_GAIN",
		screen,
		[
			"食経験値を獲得！",
			"1 食事 完了",
			"2 EXP 加算中",
			"3 成長 進行中",
			"アジの塩焼きの食経験値がたまり",
			"アジの塩焼きを食べた！",
			"次の釣行で効果！",
			"EXP 80 / 150  ->  120 / 150",
			"+40 EXP",
			"初回ボーナス +20 EXP",
			"次の釣行で最大体力 +5%",
			"1回の釣行で発動",
			"プレイヤーLv.",
			"Lv.4  120/150 EXP",
			"効果中の料理",
			"アジの塩焼き / あと1回",
			"クーラーボックス",
			"11 / 20",
			"所持金",
			"1250 G",
			"準備へ戻る",
		]
	)
	await _expect_absent_texts(
		"EXP_GAIN_LEVELUP",
		screen,
		[
			"PLAYER",
			"DISH",
			"POWER",
			"EATING",
		]
	)
	_expect_flow_connector_modes("EXP_GAIN", screen, ["meal_to_exp", "exp_to_growth"])
	_expect_named_node("EXP_GAIN", screen, "RewardStageBackground")
	_expect_named_node("EXP_GAIN", screen, "ExpGainBanner")
	_expect_named_node("EXP_GAIN", screen, "ExpGainTitle")
	_expect_named_node("EXP_GAIN", screen, "ExpEnergyTrail")
	_expect_named_node("EXP_GAIN", screen, "ExpBurstFrame")
	_expect_named_node("EXP_GAIN", screen, "ExpMessagePanel")
	_expect_named_node("EXP_GAIN", screen, "ExpMessagePortrait")
	_expect_script_texture_property_path(
		"EXP_GAIN",
		screen,
		"MealTableSpread",
		"dish_texture",
		"res://assets/showcase/cooking/dish_feature_aji_shioyaki.png"
	)
	_expect_named_node("EXP_GAIN", screen, "NextEffectArt")
	_expect_reward_status_strip("EXP_GAIN", screen)
	_expect_named_node("EXP_GAIN", screen, "RewardConfirmButton")
	_expect_named_controls_not_visible(
		"EXP_GAIN",
		screen,
		[
			"MealDishCard",
			"RewardDishFeatureImage",
			"RewardCardBaseExp",
			"RewardCardFirstBonus",
			"RewardCardTotalExp",
			"RewardCardNextEffect",
			"RewardCardGrowth",
		]
	)
	_expect_button_texture_style(
		"EXP_GAIN",
		screen,
		"RewardConfirmButton",
		"res://assets/showcase/cooking/flow_action_button_frame.png"
	)
	screen.queue_free()
	await _tick()


func _audit_exp_gain_level_up() -> void:
	_seed_select_state()
	var screen := await _mount_cooking_screen()
	var result := _fake_level_result()
	_seed_after_meal_state()
	screen.preview_show_reward_result(result, 130, 150, 150, true)
	await get_tree().create_timer(0.7).timeout
	await _expect_texts(
		"EXP_GAIN_LEVELUP",
		screen,
		[
			"食経験値が成長へ！",
			"1 食事 完了",
			"2 EXP 加算中",
			"3 成長 解放",
			"アジの塩焼きの食経験値が Lv.5 到達",
			"アジの塩焼きを食べた！",
			"次の釣行で効果！",
			"EXP 130 / 150  ->  150 / 150",
			"+40 EXP",
			"初回ボーナス +20 EXP",
			"1回の釣行で発動",
			"プレイヤーLv.",
			"Lv.5  20/190 EXP",
			"効果中の料理",
			"アジの塩焼き / あと1回",
			"クーラーボックス",
			"10 / 20",
			"所持金",
			"1250 G",
			"解放を見る",
		]
	)
	_expect_flow_connector_modes("EXP_GAIN_LEVELUP", screen, ["meal_to_exp", "growth_unlock"])
	_expect_named_node("EXP_GAIN_LEVELUP", screen, "RewardStageBackground")
	_expect_named_node("EXP_GAIN_LEVELUP", screen, "ExpGainBanner")
	_expect_named_node("EXP_GAIN_LEVELUP", screen, "ExpGainTitle")
	_expect_named_node("EXP_GAIN_LEVELUP", screen, "ExpEnergyTrail")
	_expect_named_node("EXP_GAIN_LEVELUP", screen, "ExpBurstFrame")
	_expect_named_node("EXP_GAIN_LEVELUP", screen, "ExpMessagePanel")
	_expect_named_node("EXP_GAIN_LEVELUP", screen, "ExpMessagePortrait")
	_expect_script_texture_property_path(
		"EXP_GAIN_LEVELUP",
		screen,
		"MealTableSpread",
		"dish_texture",
		"res://assets/showcase/cooking/dish_feature_aji_shioyaki.png"
	)
	_expect_named_node("EXP_GAIN_LEVELUP", screen, "NextEffectArt")
	_expect_reward_status_strip("EXP_GAIN_LEVELUP", screen)
	_expect_named_node("EXP_GAIN_LEVELUP", screen, "RewardConfirmButton")
	_expect_named_controls_not_visible(
		"EXP_GAIN_LEVELUP",
		screen,
		[
			"MealDishCard",
			"RewardDishFeatureImage",
			"RewardCardBaseExp",
			"RewardCardFirstBonus",
			"RewardCardTotalExp",
			"RewardCardNextEffect",
			"RewardCardGrowth",
		]
	)
	_expect_button_texture_style(
		"EXP_GAIN_LEVELUP",
		screen,
		"RewardConfirmButton",
		"res://assets/showcase/cooking/flow_action_button_frame.png"
	)
	screen.queue_free()
	await _tick()


func _audit_meal_result() -> void:
	_seed_select_state()
	var screen := await _mount_cooking_screen()
	var result := _fake_level_result()
	_seed_after_meal_state()
	result["status_snapshot"] = _meal_status_snapshot(4, 130, 150)
	screen.preview_show_meal_reward_result(result, true)
	await get_tree().create_timer(0.7).timeout
	await _expect_texts(
		"MEAL_RESULT",
		screen,
		[
			"食べた！",
			"2 EXP 次へ",
			"3 成長 待機",
			"食経験値は次に加算される",
			"アジの塩焼きを食べた！",
			"今回の料理",
			"食経験値を獲得した！",
			"はじめて作った料理！",
			"初回ボーナス +20 EXP",
			"合計獲得食経験値",
			"+40 EXP",
			"次回の釣行で効果を発揮！",
			"次の釣行で最大体力 +5%",
			"1回の釣行で発動",
			"プレイヤーLv.",
			"Lv.4  130/150 EXP",
			"効果中の料理",
			"アジの塩焼き / あと1回",
			"クーラーボックス",
			"10 / 20",
			"所持金",
			"1250 G",
			"食経験値へ進む",
		]
	)
	await _expect_absent_texts(
		"MEAL_RESULT",
		screen,
		[
			"食経験値が成長へ！",
			"次の釣行で効果！",
			"EXP 130 / 150",
			"Lv.4 -> Lv.5 / ぬし解放",
			"Lv.5  20/190 EXP",
			"PLAYER",
			"DISH",
			"POWER",
			"EATING",
		]
	)
	_expect_flow_connector_modes("MEAL_RESULT", screen, ["meal_to_exp", "idle"])
	_expect_named_node("MEAL_RESULT", screen, "MealResultBanner")
	_expect_named_node("MEAL_RESULT", screen, "MealResultTitle")
	_expect_named_node("MEAL_RESULT", screen, "MealSceneActor")
	_expect_named_node("MEAL_RESULT", screen, "MealTableSpread")
	_expect_named_node("MEAL_RESULT", screen, "MealDishCard")
	_expect_texture_rect_path(
		"MEAL_RESULT",
		screen,
		"RewardDishFeatureImage",
		"res://assets/showcase/cooking/dish_feature_aji_shioyaki.png"
	)
	_expect_named_node("MEAL_RESULT", screen, "RewardBuffSignal")
	_expect_named_node("MEAL_RESULT", screen, "RewardCardBaseExp")
	_expect_named_node("MEAL_RESULT", screen, "RewardCardFirstBonus")
	_expect_named_node("MEAL_RESULT", screen, "RewardCardTotalExp")
	_expect_named_node("MEAL_RESULT", screen, "RewardCardNextEffect")
	_expect_reward_status_strip("MEAL_RESULT", screen)
	_expect_named_node("MEAL_RESULT", screen, "RewardConfirmButton")
	_expect_named_controls_not_visible(
		"MEAL_RESULT",
		screen,
		[
			"ExpBurstFrame",
			"NextEffectArt",
			"RewardCardGrowth",
		]
	)
	_expect_button_texture_style(
		"MEAL_RESULT",
		screen,
		"RewardConfirmButton",
		"res://assets/showcase/cooking/flow_action_button_frame.png"
	)
	screen.queue_free()
	await _tick()


func _audit_level_up() -> void:
	_seed_after_meal_state()
	var panel := LevelUpPanelScript.new()
	panel.theme = ThemeFactory.build_theme()
	panel.size = VIEWPORT_SIZE
	_stage.add_child(panel)
	await _tick()
	panel.show_level_up(4, 5, _old_stats(), PlayerProgress.get_base_stats())
	await get_tree().create_timer(0.45).timeout
	await _expect_texts(
		"LEVEL_UP_OVERLAY",
		panel,
		[
			"成長の証",
			"LEVEL UP!",
			"Lv.4   ->   Lv.5",
			"食経験値が成長に変わった",
			"最大体力",
			"巻力",
			"新たな釣り場が解放！",
			"挑戦解放",
			"港のぬしに挑戦できるようになった！",
			"食事でLv.5到達",
			"次の目標：港のぬし",
			"新釣り場",
			"港の大岩",
			"外洋への挑戦",
			"OK",
			"成果確認へ",
		]
	)
	await _expect_absent_texts(
		"LEVEL_UP_OVERLAY",
		panel,
		[
			"CROWN",
			"REWARD",
			"NEW CHALLENGE",
			"BOSS",
			"MEDAL",
			"NEW SPOT",
		]
	)
	_expect_named_node("LEVEL_UP_OVERLAY", panel, "LevelToSummaryCue")
	_expect_named_node("LEVEL_UP_OVERLAY", panel, "LevelUpConfirmButton")
	_expect_named_node("LEVEL_UP_OVERLAY", panel, "LevelUpDimmer")
	_expect_named_node("LEVEL_UP_OVERLAY", panel, "LevelUpDialog")
	_expect_named_node("LEVEL_UP_OVERLAY", panel, "LevelUpTitleBand")
	_expect_named_node("LEVEL_UP_OVERLAY", panel, "LevelUpTitle")
	_expect_named_node("LEVEL_UP_OVERLAY", panel, "LevelUpLevelLine")
	_expect_named_node("LEVEL_UP_OVERLAY", panel, "LevelUpSourceLine")
	_expect_button_texture_style(
		"LEVEL_UP_OVERLAY",
		panel,
		"LevelUpConfirmButton",
		"res://assets/showcase/cooking/flow_action_button_frame.png"
	)
	_expect_named_node("LEVEL_UP_OVERLAY", panel, "LevelCrownAsset")
	_expect_named_node("LEVEL_UP_OVERLAY", panel, "LevelLaurelLeftAsset")
	_expect_named_node("LEVEL_UP_OVERLAY", panel, "LevelLaurelRightAsset")
	_expect_named_node("LEVEL_UP_OVERLAY", panel, "LevelUnlockMedallionAsset")
	_expect_named_node("LEVEL_UP_OVERLAY", panel, "LevelUnlockSpotAsset")
	_expect_named_node("LEVEL_UP_OVERLAY", panel, "LevelUnlockRibbonAsset")
	_expect_named_node("LEVEL_UP_OVERLAY", panel, "LevelStatRowEnergy")
	_expect_named_node("LEVEL_UP_OVERLAY", panel, "LevelStatRowReel")
	_expect_named_node("LEVEL_UP_OVERLAY", panel, "LevelStatRowTechnique")
	_expect_named_node("LEVEL_UP_OVERLAY", panel, "LevelStatRowFocus")
	panel.queue_free()
	await _tick()


func _audit_status_summary() -> void:
	_seed_after_meal_state()
	var screen := await _mount_cooking_screen()
	screen.preview_show_status_overlay()
	await get_tree().create_timer(0.4).timeout
	var status_panel := _find_script_instance(screen, CookingStatusPanelScript)
	if status_panel == null:
		_failures.append("STATUS_SUMMARY: missing CookingStatusPanel instance.")
		screen.queue_free()
		await _tick()
		return
	await _expect_texts(
		"STATUS_SUMMARY",
		status_panel,
		[
			"ステータス",
			"調理の成果を確認できます",
			"Lv.5",
			"20 / 190",
			"次のレベルまで 170 EXP",
			"体力",
			"攻撃力",
			"防御力",
			"素早さ",
			"運",
			"効果中の料理",
			"効果中！ あと 1回",
			"アジの塩焼き",
			"効果：体力アップ",
			"最大体力 +5%",
			"クーラーボックス",
			"10 / 20",
			"所持金",
			"1250 G",
			"プレイ時間",
			"03:25:45",
			"Lv.5到達！ 港のぬしに挑めます！",
			"効果中の料理を活かして",
			"港へ戻る",
		]
	)
	_expect_named_node("STATUS_SUMMARY", status_panel, "StatusTitle")
	_expect_named_node("STATUS_SUMMARY", status_panel, "StatusHeaderPlayerBadge")
	_expect_named_node("STATUS_SUMMARY", status_panel, "StatusHeaderExpBox")
	_expect_named_node("STATUS_SUMMARY", status_panel, "StatusHeaderLevel")
	_expect_named_node("STATUS_SUMMARY", status_panel, "StatusHeaderExpBar")
	_expect_named_node("STATUS_SUMMARY", status_panel, "StatusHeaderExpValue")
	_expect_named_node("STATUS_SUMMARY", status_panel, "StatusSummaryBackground")
	_expect_exact_named_prefix_count("STATUS_SUMMARY", status_panel, "StatusCard", 5)
	_expect_named_node("STATUS_SUMMARY", status_panel, "StatusCardPlayer")
	_expect_named_node("STATUS_SUMMARY", status_panel, "StatusCardMeal")
	_expect_named_node("STATUS_SUMMARY", status_panel, "StatusCardCooler")
	_expect_named_node("STATUS_SUMMARY", status_panel, "StatusCardMoney")
	_expect_named_node("STATUS_SUMMARY", status_panel, "StatusCardPlayTime")
	_expect_texture_rect_path(
		"STATUS_SUMMARY",
		status_panel,
		"StatusMealDishImage",
		"res://assets/showcase/cooking/dish_feature_aji_shioyaki.png"
	)
	_expect_named_node("STATUS_SUMMARY", status_panel, "StatusCoolerArt")
	_expect_named_node("STATUS_SUMMARY", status_panel, "StatusMoneyArt")
	_expect_named_node("STATUS_SUMMARY", status_panel, "StatusClockArt")
	_expect_named_node("STATUS_SUMMARY", status_panel, "StatusMealEffectCue")
	_expect_named_node("STATUS_SUMMARY", status_panel, "StatusReturnButton")
	_expect_button_texture_style(
		"STATUS_SUMMARY",
		status_panel,
		"StatusReturnButton",
		"res://assets/showcase/cooking/flow_action_button_frame.png"
	)
	_expect_absent_named_nodes(
		"STATUS_SUMMARY",
		status_panel,
		[
			"RecipeGrid",
			"RecipeSectionRibbon",
			"RecipeToDetailArrow",
			"CookButton",
			"CookActionCue",
			"FishSectionRibbon",
		]
	)
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


func _expect_texts(state: String, root: Node, required: Array) -> void:
	await _tick()
	var visible_text := _visible_text(root)
	for text in required:
		if not visible_text.contains(String(text)):
			_failures.append(
				"%s: missing visible text '%s'. Visible text: %s"
				% [state, String(text), _trim(visible_text)]
			)


func _expect_absent_texts(state: String, root: Node, forbidden: Array) -> void:
	await _tick()
	var visible_text := _visible_text(root)
	for text in forbidden:
		if visible_text.contains(String(text)):
			_failures.append(
				"%s: forbidden visible text '%s'. Visible text: %s"
				% [state, String(text), _trim(visible_text)]
			)


func _expect_flow_connector_modes(state: String, root: Node, expected_modes: Array) -> void:
	for i in range(expected_modes.size()):
		var connector := _find_named(root, "FlowConnector_%d" % i)
		if connector == null:
			_failures.append("%s: missing FlowConnector_%d." % [state, i])
			continue
		var mode := String(connector.get("mode"))
		var expected := String(expected_modes[i])
		if mode != expected:
			_failures.append(
				"%s: FlowConnector_%d should be '%s', got '%s'."
				% [state, i, expected, mode]
			)


func _expect_named_node(state: String, root: Node, node_name: String) -> void:
	if _find_named(root, node_name) == null:
		_failures.append("%s: missing named node '%s'." % [state, node_name])


func _expect_reward_status_strip(state: String, root: Node) -> void:
	_expect_named_node(state, root, "RewardStatusStrip")
	_expect_named_node(state, root, "RewardStatusLevelCard")
	_expect_named_node(state, root, "RewardStatusMealCard")
	_expect_named_node(state, root, "RewardStatusCoolerCard")
	_expect_named_node(state, root, "RewardStatusMoneyCard")


func _expect_absent_named_nodes(state: String, root: Node, node_names: Array) -> void:
	for node_name in node_names:
		if _find_named(root, String(node_name)) != null:
			_failures.append("%s: forbidden named node '%s' is present." % [state, String(node_name)])


func _expect_named_controls_not_visible(state: String, root: Node, node_names: Array) -> void:
	for node_name in node_names:
		var node := _find_named(root, String(node_name))
		if node == null:
			continue
		if not (node is Control):
			_failures.append("%s: node '%s' should be a Control." % [state, String(node_name)])
			continue
		if (node as Control).is_visible_in_tree():
			_failures.append(
				"%s: named control '%s' should not be visible in this state."
				% [state, String(node_name)]
			)


func _expect_exact_named_prefix_count(
	state: String, root: Node, node_prefix: String, expected_count: int
) -> void:
	var matches: Array[Node] = []
	_collect_named_prefix(root, node_prefix, matches)
	if matches.size() != expected_count:
		_failures.append(
			"%s: expected exactly %d visible '%s*' nodes, got %d."
			% [state, expected_count, node_prefix, matches.size()]
		)


func _collect_named_prefix(node: Node, node_prefix: String, out: Array[Node]) -> void:
	if String(node.name).begins_with(node_prefix):
		if not (node is Control) or (node as Control).is_visible_in_tree():
			out.append(node)
	for child in node.get_children():
		_collect_named_prefix(child, node_prefix, out)


func _expect_texture_rect_path(
	state: String, root: Node, node_name: String, expected_texture_path: String
) -> void:
	var node := _find_named(root, node_name)
	if node == null:
		_failures.append("%s: missing texture node '%s'." % [state, node_name])
		return
	if not (node is TextureRect):
		_failures.append("%s: node '%s' should be a TextureRect." % [state, node_name])
		return
	var texture_rect := node as TextureRect
	if not texture_rect.is_visible_in_tree():
		_failures.append("%s: texture node '%s' is not visible." % [state, node_name])
		return
	var texture := texture_rect.texture
	if texture == null:
		_failures.append("%s: texture node '%s' has no texture." % [state, node_name])
		return
	if texture.resource_path != expected_texture_path:
		_failures.append(
			"%s: texture node '%s' should use '%s', got '%s'."
			% [state, node_name, expected_texture_path, texture.resource_path]
		)


func _expect_script_texture_property_path(
	state: String,
	root: Node,
	node_name: String,
	property_name: String,
	expected_texture_path: String
) -> void:
	var node := _find_named(root, node_name)
	if node == null:
		_failures.append("%s: missing texture owner node '%s'." % [state, node_name])
		return
	if node is Control and not (node as Control).is_visible_in_tree():
		_failures.append("%s: texture owner node '%s' is not visible." % [state, node_name])
		return
	var texture := node.get(property_name) as Texture2D
	if texture == null:
		_failures.append(
			"%s: texture owner node '%s' has no Texture2D property '%s'."
			% [state, node_name, property_name]
		)
		return
	if texture.resource_path != expected_texture_path:
		_failures.append(
			"%s: texture owner node '%s.%s' should use '%s', got '%s'."
			% [state, node_name, property_name, expected_texture_path, texture.resource_path]
		)


func _expect_button_texture_style(
	state: String, root: Node, node_name: String, expected_texture_path: String
) -> void:
	var node := _find_named(root, node_name)
	if node == null:
		_failures.append("%s: missing styled button '%s'." % [state, node_name])
		return
	if not (node is Button):
		_failures.append("%s: node '%s' should be a Button." % [state, node_name])
		return
	var button := node as Button
	var style := button.get_theme_stylebox("normal")
	if not (style is StyleBoxTexture):
		_failures.append(
			"%s: button '%s' should use a StyleBoxTexture normal style." % [state, node_name]
		)
		return
	var texture_style := style as StyleBoxTexture
	var texture := texture_style.texture
	if texture == null:
		_failures.append("%s: button '%s' has no normal style texture." % [state, node_name])
		return
	if texture.resource_path != expected_texture_path:
		_failures.append(
			"%s: button '%s' should use '%s', got '%s'."
			% [state, node_name, expected_texture_path, texture.resource_path]
			)


func _expect_panel_texture_style(
	state: String, root: Node, node_name: String, expected_texture_path: String
) -> void:
	var node := _find_named(root, node_name)
	if node == null:
		_failures.append("%s: missing styled panel '%s'." % [state, node_name])
		return
	if not (node is PanelContainer):
		_failures.append("%s: node '%s' should be a PanelContainer." % [state, node_name])
		return
	var panel := node as PanelContainer
	var style := panel.get_theme_stylebox("panel")
	if not (style is StyleBoxTexture):
		_failures.append(
			"%s: panel '%s' should use a StyleBoxTexture panel style." % [state, node_name]
		)
		return
	var texture_style := style as StyleBoxTexture
	var texture := texture_style.texture
	if texture == null:
		_failures.append("%s: panel '%s' has no panel style texture." % [state, node_name])
		return
	if texture.resource_path != expected_texture_path:
		_failures.append(
			"%s: panel '%s' should use '%s', got '%s'."
			% [state, node_name, expected_texture_path, texture.resource_path]
		)


func _visible_text(root: Node) -> String:
	var values: Array[String] = []
	_collect_visible_text(root, values)
	return " | ".join(values)


func _collect_visible_text(node: Node, out: Array[String]) -> void:
	if node is Control and not (node as Control).is_visible_in_tree():
		return
	if node is Label:
		var label_text := (node as Label).text.strip_edges()
		if not label_text.is_empty():
			out.append(label_text)
	elif node is Button:
		var button_text := (node as Button).text.strip_edges()
		if not button_text.is_empty():
			out.append(button_text)
	for child in node.get_children():
		_collect_visible_text(child, out)


func _find_named(node: Node, node_name: String) -> Node:
	if node.name == node_name:
		return node
	for child in node.get_children():
		var found := _find_named(child, node_name)
		if found != null:
			return found
	return null


func _find_script_instance(node: Node, script: Script) -> Node:
	if node.get_script() == script:
		return node
	for child in node.get_children():
		var found := _find_script_instance(child, script)
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


func _meal_status_snapshot(level_before: int, exp_before: int, exp_max_before: int) -> Dictionary:
	return {
		"level": level_before,
		"exp": exp_before,
		"exp_max": exp_max_before,
		"fish_total": _total_fish_count(),
		"money": PlayerProgress.money,
	}


func _total_fish_count() -> int:
	var total := 0
	for fish_id in GameData.get_all_fish_ids():
		total += PlayerProgress.fish_count(fish_id)
	return total


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


func _trim(value: String) -> String:
	if value.length() > 420:
		return value.substr(0, 417) + "..."
	return value
