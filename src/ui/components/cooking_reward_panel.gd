extends ScreenBase
## 調理後の MEAL_RESULT / EXP_GAIN を担う報酬オーバーレイ。
# 料理を食べた結果、EXP、初回ボーナス、次回バフを一拍置いて見せる。
signal closed

const GaugeBarScript = preload("res://src/ui/components/gauge_bar.gd")
const CookingRewardCardsScript = preload("res://src/ui/components/cooking_reward_cards.gd")
const CookingRewardStatusStripScript = preload("res://src/ui/components/cooking_reward_status_strip.gd")
const CookingRewardVisualsScript = preload("res://src/ui/components/cooking_reward_visuals.gd")
const SceneActorVisual = CookingRewardVisualsScript.SceneActorVisual
const MealTableSpreadVisual = CookingRewardVisualsScript.MealTableSpreadVisual
const MealSceneTableBridgeVisual = CookingRewardVisualsScript.MealSceneTableBridgeVisual
const MealSceneForegroundGlowVisual = CookingRewardVisualsScript.MealSceneForegroundGlowVisual
const ExpMessagePortraitVisual = CookingRewardVisualsScript.ExpMessagePortraitVisual
const ExpTrailVisual = CookingRewardVisualsScript.ExpTrailVisual
const MealResultRewardCueVisual = CookingRewardVisualsScript.MealResultRewardCueVisual
const MealResultBannerSparkVisual = CookingRewardVisualsScript.MealResultBannerSparkVisual
const MealResultSplitTitleVisual = CookingRewardVisualsScript.MealResultSplitTitleVisual
const MealResultModeTabVisual = CookingRewardVisualsScript.MealResultModeTabVisual
const MealDishCardBridgeVisual = CookingRewardVisualsScript.MealDishCardBridgeVisual
const FlowConnectorVisual = CookingRewardVisualsScript.FlowConnectorVisual
const EffectPreviewVisual = CookingRewardVisualsScript.EffectPreviewVisual

const MEAL_RESULT_SCENE_ART := "res://assets/showcase/cooking/meal_result_scene_art_v2.png"
const PLAYER_EATING_POSE := "res://assets/showcase/cooking/player_eating_pose_pixel_tight.png"
const PLAYER_EXP_POSE := "res://assets/showcase/cooking/player_exp_message_pose_pixel.png"
const PLAYER_EXP_SCENE_POSE := "res://assets/showcase/cooking/player_exp_pose_pixel_tight.png"
const COOKING_ROOM_BG := "res://assets/showcase/cooking/cooking_room_bg.png"
const MEAL_SCENE_BG := "res://assets/showcase/cooking/meal_scene_bg.png"
const EXP_STAGE_BG := "res://assets/showcase/cooking/exp_stage_bg.png"
const MEAL_RESULT_FRAME := "res://assets/showcase/cooking/meal_result_frame.png"
const MEAL_BANNER_FRAME := "res://assets/showcase/cooking/meal_banner_frame.png"
const MEAL_DISH_CARD_FRAME := "res://assets/showcase/cooking/meal_dish_card_frame.png"
const EXP_BURST_FRAME := "res://assets/showcase/cooking/exp_burst_frame.png"


var _dialog: PanelContainer
var _stage_base: ColorRect
var _stage_background: TextureRect
var _result_banner: PanelContainer
var _meal_banner_spark: MealResultBannerSparkVisual
var _meal_result_mode_label: MealResultModeTabVisual
var _meal_result_split_title: MealResultSplitTitleVisual
var _header_title: Label
var _bridge_label: Label
var _dish_title: Label
var _dish_note_label: Label
var _dish_image: TextureRect
var _dish_card: PanelContainer
var _dish_card_bridge: MealDishCardBridgeVisual
var _scene_card: PanelContainer
var _scene_title: Label
var _scene_caption: Label
var _scene_bonus_label: Label
var _scene_result_image: TextureRect
var _scene_table_bridge: MealSceneTableBridgeVisual
var _scene_foreground_glow: MealSceneForegroundGlowVisual
var _scene_visual_stack: Control
var _scene_table: HBoxContainer
var _scene_dish_image: MealTableSpreadVisual
var _scene_actor_panel: PanelContainer
var _scene_actor_visual: SceneActorVisual
var _scene_actor_image: TextureRect
var _exp_trail_visual: ExpTrailVisual
var _exp_focus_card: PanelContainer
var _exp_focus_burst_layer: Control
var _exp_message_label: Label
var _effect_preview_card: PanelContainer
var _effect_preview_visual: TextureRect
var _effect_name_label: Label
var _effect_text_label: Label
var _effect_duration_label: Label
var _meal_reward_cue: MealResultRewardCueVisual
var _reward_cards: CookingRewardCardsScript
var _exp_bar: GaugeBar
var _exp_label: Label
var _exp_progress_label: Label
var _status_strip: CookingRewardStatusStripScript
var _confirm_button: Button
var _flow_row: HBoxContainer
var _flow_step_cards: Array[PanelContainer] = []
var _flow_step_labels: Array[Label] = []
var _flow_connectors: Array[FlowConnectorVisual] = []
var _preview_state := ""
var _closing := false

var _target_exp := 0.0
var _target_max := 1.0


func _build_screen() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

	_add_meal_scene_background()

	var dim := ColorRect.new()
	dim.color = Palette.COOKING_REWARD_OVERLAY_DIM
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	_add_reward_ambient_layer()

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_dialog = PanelContainer.new()
	_dialog.custom_minimum_size = Vector2(1168.0, 0.0)
	_dialog.add_theme_stylebox_override("panel", _reward_dialog_frame_style())
	center.add_child(_dialog)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	_dialog.add_child(root)

	_flow_row = HBoxContainer.new()
	_flow_row.name = "RewardFlowRow"
	_flow_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_flow_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_flow_row.add_theme_constant_override("separation", 4)
	root.add_child(_flow_row)
	_add_flow_step(_flow_row, "1 食事")
	_add_flow_connector(_flow_row)
	_add_flow_step(_flow_row, "2 EXP")
	_add_flow_connector(_flow_row)
	_add_flow_step(_flow_row, "3 成長")

	var hero := HBoxContainer.new()
	hero.add_theme_constant_override("separation", 12)
	root.add_child(hero)

	_scene_card = _panel_box(
		Palette.COOKING_REWARD_SCENE_CARD_FILL,
		Palette.COOKING_REWARD_FRAME_BORDER,
		Palette.GOLD_BRIGHT,
		5
	)
	_scene_card.custom_minimum_size = Vector2(438.0, 244.0)
	hero.add_child(_scene_card)
	var scene_box := VBoxContainer.new()
	scene_box.add_theme_constant_override("separation", 5)
	_scene_card.add_child(scene_box)
	_scene_title = make_shadow_label("食べる", 27, Palette.GOLD_BRIGHT, 3)
	_scene_title.name = "MealSceneTitle"
	_scene_title.z_index = 8
	_scene_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scene_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	_scene_title.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	_set_label_min_height(_scene_title, 27)
	_scene_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scene_box.add_child(_scene_title)
	_scene_visual_stack = Control.new()
	_scene_visual_stack.name = "MealSceneVisualStack"
	_scene_visual_stack.clip_contents = true
	_scene_visual_stack.custom_minimum_size = Vector2(0.0, 164.0)
	_scene_visual_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scene_visual_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scene_box.add_child(_scene_visual_stack)
	_scene_result_image = TextureRect.new()
	_scene_result_image.name = "MealResultSceneArt"
	_scene_result_image.texture = load(MEAL_RESULT_SCENE_ART) as Texture2D
	_scene_result_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scene_result_image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scene_result_image.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scene_result_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_scene_result_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_scene_result_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scene_visual_stack.add_child(_scene_result_image)
	_scene_table_bridge = MealSceneTableBridgeVisual.new()
	_scene_table_bridge.name = "MealSceneTableBridge"
	_scene_table_bridge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scene_table_bridge.visible = false
	_scene_visual_stack.add_child(_scene_table_bridge)
	_scene_table = HBoxContainer.new()
	_scene_table.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scene_table.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scene_table.add_theme_constant_override("separation", 10)
	_scene_visual_stack.add_child(_scene_table)
	_scene_actor_panel = _scene_actor_box()
	_scene_actor_panel.custom_minimum_size = Vector2(176.0, 0.0)
	_scene_table.add_child(_scene_actor_panel)
	_scene_dish_image = MealTableSpreadVisual.new()
	_scene_dish_image.name = "MealTableSpread"
	_scene_dish_image.custom_minimum_size = Vector2(252.0, 132.0)
	_scene_dish_image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scene_dish_image.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scene_dish_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scene_table.add_child(_scene_dish_image)
	_scene_foreground_glow = MealSceneForegroundGlowVisual.new()
	_scene_foreground_glow.name = "MealSceneForegroundGlow"
	_scene_foreground_glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scene_foreground_glow.visible = false
	_scene_visual_stack.add_child(_scene_foreground_glow)
	_scene_caption = make_shadow_label("湯気の立つ料理を味わった。", 18, Palette.TEXT_BONE, 2)
	_scene_caption.name = "MealSceneCaption"
	_set_label_min_height(_scene_caption, 18, 2)
	_scene_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_scene_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scene_box.add_child(_scene_caption)
	_scene_bonus_label = make_shadow_label("初回ボーナス", 16, Palette.GOLD_BRIGHT, 2)
	_scene_bonus_label.name = "MealSceneBonusBadge"
	_scene_bonus_label.custom_minimum_size = Vector2(0.0, 24.0)
	_scene_bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_scene_bonus_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_scene_bonus_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_scene_bonus_label.clip_text = true
	scene_box.add_child(_scene_bonus_label)

	_exp_trail_visual = ExpTrailVisual.new()
	_exp_trail_visual.name = "ExpEnergyTrail"
	_exp_trail_visual.custom_minimum_size = Vector2(32.0, 152.0)
	_exp_trail_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_exp_trail_visual.visible = false
	hero.add_child(_exp_trail_visual)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 6)
	hero.add_child(right)

	_result_banner = PanelContainer.new()
	_result_banner.custom_minimum_size = Vector2(0.0, 96.0)
	_set_result_banner_meal_style()
	right.add_child(_result_banner)
	_meal_banner_spark = MealResultBannerSparkVisual.new()
	_meal_banner_spark.name = "MealResultBannerSpark"
	_meal_banner_spark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_meal_banner_spark.visible = false
	_result_banner.add_child(_meal_banner_spark)
	var banner_box := VBoxContainer.new()
	banner_box.alignment = BoxContainer.ALIGNMENT_CENTER
	banner_box.add_theme_constant_override("separation", 2)
	_result_banner.add_child(banner_box)
	_header_title = make_shadow_label("いただきます！", 32, Palette.COOKING_REWARD_BONUS_FLAG, 3)
	_header_title.z_index = 8
	_header_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_header_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	_header_title.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	_set_label_min_height(_header_title, 32)
	_header_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_header_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner_box.add_child(_header_title)
	_bridge_label = make_shadow_label("", 16, Palette.COOKING_REWARD_BRIDGE_TEXT, 1)
	_bridge_label.z_index = 8
	_bridge_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_set_label_min_height(_bridge_label, 16)
	_bridge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bridge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_bridge_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	banner_box.add_child(_bridge_label)
	_meal_result_split_title = MealResultSplitTitleVisual.new()
	_meal_result_split_title.name = "MealResultSplitTitle"
	_meal_result_split_title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_meal_result_split_title.visible = false
	_result_banner.add_child(_meal_result_split_title)
	_meal_result_mode_label = MealResultModeTabVisual.new()
	_meal_result_mode_label.name = "MealResultModeTab"
	_meal_result_mode_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_meal_result_mode_label.visible = false
	_result_banner.add_child(_meal_result_mode_label)

	_dish_card = PanelContainer.new()
	_dish_card.name = "MealDishCard"
	_dish_card.add_theme_stylebox_override(
		"panel",
		_texture_style_box(
			MEAL_DISH_CARD_FRAME,
			24,
			_style_box(
				Palette.COOKING_REWARD_PANEL_FILL,
				Palette.COOKING_REWARD_CARD_FRAME_BORDER,
				Palette.GOLD_DEEP,
				5,
				5
			),
			14.0,
			8.0
		)
	)
	_dish_card.custom_minimum_size = Vector2(0.0, 166.0)
	right.add_child(_dish_card)
	_dish_card_bridge = MealDishCardBridgeVisual.new()
	_dish_card_bridge.name = "MealDishCardBridge"
	_dish_card_bridge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dish_card_bridge.visible = false
	_dish_card.add_child(_dish_card_bridge)
	var dish_row := HBoxContainer.new()
	dish_row.add_theme_constant_override("separation", 14)
	_dish_card.add_child(dish_row)
	_dish_image = TextureRect.new()
	_dish_image.name = "RewardDishFeatureImage"
	_dish_image.custom_minimum_size = Vector2(304.0, 0.0)
	_dish_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_dish_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dish_row.add_child(_dish_image)
	var dish_text := VBoxContainer.new()
	dish_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dish_text.alignment = BoxContainer.ALIGNMENT_CENTER
	dish_row.add_child(dish_text)
	var dish_tag := make_shadow_label("今回の料理", 19, Palette.GOLD_BRIGHT, 2)
	_set_label_min_height(dish_tag, 19)
	dish_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dish_text.add_child(dish_tag)
	_dish_title = make_shadow_label("", 30, Palette.TEXT_BONE, 3)
	_dish_title.custom_minimum_size = Vector2(0.0, 64.0)
	_dish_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dish_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_dish_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dish_text.add_child(_dish_title)
	_dish_note_label = make_shadow_label("料理を食べて、体に力が湧いてきた。", 17, Palette.TEXT_BONE, 2)
	_set_label_min_height(_dish_note_label, 17, 2)
	_dish_note_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dish_note_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dish_text.add_child(_dish_note_label)

	_exp_focus_card = PanelContainer.new()
	_exp_focus_card.name = "ExpBurstFrame"
	_exp_focus_card.add_theme_stylebox_override(
		"panel",
		_texture_style_box(
			EXP_BURST_FRAME,
			28,
			_style_box(
				Palette.COOKING_REWARD_EXP_FRAME_FILL,
				Palette.COOKING_REWARD_CARD_FRAME_BORDER,
				Palette.GAUGE_CYAN_HI,
				5,
				5
			),
			18.0,
			8.0
		)
	)
	_exp_focus_card.custom_minimum_size = Vector2(0.0, 216.0)
	_exp_focus_card.visible = false
	right.add_child(_exp_focus_card)
	_exp_focus_burst_layer = Control.new()
	_exp_focus_burst_layer.name = "ExpFocusBurstLayer"
	_exp_focus_burst_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_exp_focus_burst_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_exp_focus_burst_layer.draw.connect(_draw_exp_focus_burst)
	_exp_focus_card.add_child(_exp_focus_burst_layer)
	var exp_focus_box := VBoxContainer.new()
	exp_focus_box.z_index = 2
	exp_focus_box.add_theme_constant_override("separation", 5)
	_exp_focus_card.add_child(exp_focus_box)
	var exp_focus_tag := make_shadow_label("食経験値", 22, Palette.TEXT_BONE, 3)
	exp_focus_tag.name = "ExpFocusTag"
	exp_focus_tag.z_index = 8
	exp_focus_tag.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	exp_focus_tag.autowrap_mode = TextServer.AUTOWRAP_OFF
	exp_focus_tag.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	_set_label_min_height(exp_focus_tag, 22)
	exp_focus_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	exp_focus_tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	exp_focus_box.add_child(exp_focus_tag)
	_exp_label = make_shadow_label("+0 EXP", 62, Palette.GOLD_BRIGHT, 7)
	_exp_label.name = "ExpGainValue"
	_exp_label.z_index = 8
	_exp_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_exp_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_exp_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	_set_label_min_height(_exp_label, 62)
	_exp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_exp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	exp_focus_box.add_child(_exp_label)
	_exp_bar = GaugeBarScript.new()
	_exp_bar.show_value = false
	_exp_bar.custom_minimum_size = Vector2(0.0, 46.0)
	_exp_bar.set_colors(Palette.GAUGE_CYAN, Palette.GAUGE_CYAN_HI)
	exp_focus_box.add_child(_exp_bar)
	_exp_progress_label = make_shadow_label("", 18, Palette.TEXT_BONE, 2)
	_exp_progress_label.name = "ExpProgressText"
	_exp_progress_label.z_index = 8
	_exp_progress_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_exp_progress_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_exp_progress_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	_set_label_min_height(_exp_progress_label, 18)
	_exp_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_exp_progress_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	exp_focus_box.add_child(_exp_progress_label)
	var message_row := HBoxContainer.new()
	message_row.name = "ExpMessagePanel"
	message_row.add_theme_constant_override("separation", 8)
	message_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	exp_focus_box.add_child(message_row)
	var exp_portrait := TextureRect.new()
	exp_portrait.name = "ExpMessagePortrait"
	exp_portrait.texture = load(PLAYER_EXP_POSE) as Texture2D
	exp_portrait.custom_minimum_size = Vector2(108.0, 62.0)
	exp_portrait.size_flags_vertical = Control.SIZE_EXPAND_FILL
	exp_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	exp_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	exp_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	message_row.add_child(exp_portrait)
	_exp_message_label = make_shadow_label("体に力がみなぎってきた！", 17, Palette.TEXT_BONE, 2)
	_set_label_min_height(_exp_message_label, 17, 2)
	_exp_message_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_exp_message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_exp_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_row.add_child(_exp_message_label)

	_build_effect_preview_card(hero)

	_meal_reward_cue = MealResultRewardCueVisual.new()
	_meal_reward_cue.name = "MealResultRewardCue"
	_meal_reward_cue.custom_minimum_size = Vector2(0.0, 16.0)
	_meal_reward_cue.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_meal_reward_cue.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_meal_reward_cue)

	_reward_cards = CookingRewardCardsScript.new()
	root.add_child(_reward_cards)

	_build_status_strip(root)

	_confirm_button = make_button("OK", _close, 280.0, true)
	_confirm_button.name = "RewardConfirmButton"
	_confirm_button.custom_minimum_size = Vector2(318.0, 40.0)
	_confirm_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_apply_flow_button_style(_confirm_button)
	_set_confirm_button_emphasis(false)
	_confirm_button.draw.connect(func() -> void: _draw_confirm_button_cue(_confirm_button))
	root.add_child(_confirm_button)


func show_meal_result(result: Dictionary) -> void:
	_preview_state = "MEAL_RESULT"
	_reward_cards.set_preview_state(_preview_state)
	_status_strip.set_secondary(true)
	_result_banner.name = "MealResultBanner"
	_header_title.name = "MealResultTitle"
	_set_stage_base_visible(true)
	_set_stage_background(MEAL_SCENE_BG)
	_apply_meal_result_composition()
	var dish_name := String(result.get("dish_name", "料理"))
	_set_result_banner_height(124.0)
	_set_header_title_font_size(35)
	_set_bridge_font_size(12)
	_set_exp_label_font_size(56)
	_header_title.text = "%sを食べた！" % dish_name
	_header_title.modulate = Color(Color.WHITE, 0.0)
	_bridge_label.text = ""
	_bridge_label.visible = false
	if _meal_banner_spark != null:
		_meal_banner_spark.visible = true
		_meal_banner_spark.queue_redraw()
	if _meal_result_split_title != null:
		_meal_result_split_title.configure(dish_name)
		_meal_result_split_title.visible = true
	if _meal_result_mode_label != null:
		_meal_result_mode_label.visible = true
	_dish_title.text = dish_name
	if _dish_note_label != null:
		_dish_note_label.text = "次の釣行へ力がつながる。"
		_dish_note_label.visible = false
	var result_recipe_id := String(Dictionary(result.get("buff", {})).get("recipe_id", ""))
	var dish_texture := _featured_dish_texture(result_recipe_id)
	_dish_image.texture = dish_texture
	_scene_dish_image.set_dish_texture(dish_texture)
	_scene_dish_image.set_recipe_id(result_recipe_id)
	_scene_dish_image.set_mode("meal")
	_set_scene_backdrop(MEAL_RESULT_SCENE_ART, 1.0, true)
	_scene_caption.text = "湯気の立つ%sを味わった。" % dish_name
	_scene_caption.visible = false
	_scene_bonus_label.text = _meal_bonus_badge_text(result)
	_scene_bonus_label.visible = false
	_scene_title.text = "食べる"
	_scene_title.visible = false
	_set_scene_actor_mode("meal")
	_exp_trail_visual.visible = false
	_meal_reward_cue.visible = true
	_meal_reward_cue.queue_redraw()
	_dish_card.visible = true
	if _dish_card_bridge != null:
		_dish_card_bridge.visible = true
		_dish_card_bridge.queue_redraw()
	_exp_focus_card.visible = false
	_effect_preview_card.visible = false

	var buff := Dictionary(result.get("buff", {}))
	_reward_cards.show_meal_result(result, _meal_buff_reward_text(buff))
	_status_strip.refresh(result)
	_set_status_strip_emphasis(false)
	_confirm_button.text = "食経験値へ進む"
	_set_confirm_button_emphasis(true)
	_confirm_button.queue_redraw()
	_refresh_meal_steps()
	_present()


func show_reward(
	result: Dictionary,
	exp_before: int,
	exp_after: int,
	exp_max: int,
	leveled: bool,
	level_before := 0,
	level_after := 0
) -> void:
	_preview_state = "EXP_GAIN_LEVELUP" if leveled else "EXP_GAIN"
	_reward_cards.set_preview_state(_preview_state)
	_status_strip.set_secondary(false)
	_result_banner.name = "ExpGainBanner"
	_header_title.name = "ExpGainTitle"
	_header_title.modulate = Color.WHITE
	_set_stage_base_visible(false)
	_set_stage_background(EXP_STAGE_BG)
	_apply_exp_gain_composition()
	if _meal_banner_spark != null:
		_meal_banner_spark.visible = false
	if _meal_result_mode_label != null:
		_meal_result_mode_label.visible = false
	if _meal_result_split_title != null:
		_meal_result_split_title.visible = false
	if _dish_card_bridge != null:
		_dish_card_bridge.visible = false
	var dish_name := String(result.get("dish_name", "料理"))
	_set_result_banner_height(104.0)
	_set_header_title_font_size(34)
	_set_bridge_font_size(16)
	_set_exp_label_font_size(68)
	_bridge_label.visible = true
	_header_title.text = "食経験値が成長へ！" if leveled else "食経験値を獲得！"
	_bridge_label.text = _growth_bridge_text(dish_name, leveled, level_before, level_after)
	_dish_title.text = "%sを食べた！" % dish_name
	var result_recipe_id := String(Dictionary(result.get("buff", {})).get("recipe_id", ""))
	var dish_texture := _featured_dish_texture(result_recipe_id)
	_dish_image.texture = dish_texture
	_scene_dish_image.set_dish_texture(dish_texture)
	_scene_dish_image.set_recipe_id(result_recipe_id)
	_scene_dish_image.set_mode("exp")
	_set_scene_result_art_visible(false)
	_scene_title.text = "食べた料理"
	_scene_title.visible = true
	_set_scene_actor_mode("exp")
	_exp_trail_visual.visible = true
	_exp_trail_visual.queue_redraw()
	_set_confirm_button_emphasis(false)
	_scene_caption.text = "料理から食経験値が流れ込む。"
	_scene_caption.visible = true
	_scene_bonus_label.text = _meal_bonus_badge_text(result)
	_scene_bonus_label.visible = true
	_dish_card.visible = false
	_exp_focus_card.visible = true
	_effect_preview_card.visible = true
	_set_status_strip_emphasis(true)
	_meal_reward_cue.visible = false

	_target_max = maxf(1.0, float(exp_max))
	_target_exp = clampf(float(exp_after), 0.0, _target_max)
	_exp_bar.max_value = _target_max
	_exp_bar.set_value(clampf(float(exp_before), 0.0, _target_max))
	var shown_max := maxi(1, exp_max)
	var shown_before := mini(maxi(0, exp_before), shown_max)
	var shown_after := mini(maxi(0, exp_after), shown_max)
	_exp_progress_label.text = "EXP %d / %d  ->  %d / %d" % [
		shown_before,
		shown_max,
		shown_after,
		shown_max,
	]
	_exp_label.text = "+%d EXP" % int(result.get("total_exp", 0))
	_exp_message_label.text = "力がみなぎった！"
	var buff := Dictionary(result.get("buff", {}))
	_reward_cards.show_exp_gain(result, _buff_effect_text(buff))
	_effect_name_label.text = String(buff.get("name", "次回効果"))
	_effect_text_label.text = _compact_effect_preview_text(buff)
	_effect_duration_label.text = "次回1回で発動"
	_effect_preview_visual.queue_redraw()
	if _exp_focus_burst_layer != null:
		_exp_focus_burst_layer.queue_redraw()
	_status_strip.refresh(result)
	if leveled:
		if level_before > 0 and level_after > level_before:
			var boss_unlocked := (
				level_before < GameData.BOSS_UNLOCK_LEVEL
				and level_after >= GameData.BOSS_UNLOCK_LEVEL
			)
			if boss_unlocked:
				_reward_cards.set_growth_text("Lv.%d -> Lv.%d / ぬし解放" % [
					level_before,
					level_after,
				])
				_confirm_button.text = "解放を見る"
			else:
				_reward_cards.set_growth_text("LEVEL UP! Lv.%d -> Lv.%d" % [level_before, level_after])
				_confirm_button.text = "Lv.%dの成長を見る" % level_after
		else:
			_reward_cards.set_growth_text("LEVEL UP! 能力上昇へ")
			_confirm_button.text = "成長を見る"
	else:
		_reward_cards.set_growth_text("次のレベルまで %d EXP" % maxi(0, exp_max - exp_after))
		_confirm_button.text = "準備へ戻る"
	_confirm_button.queue_redraw()
	_refresh_flow_steps(leveled)
	_present()


func _growth_bridge_text(
	dish_name: String, leveled: bool, level_before: int, level_after: int
) -> String:
	if leveled and level_before > 0 and level_after > level_before:
		return "%sの食経験値が Lv.%d 到達へ！" % [dish_name, level_after]
	return "%sの食経験値がたまり、力が満ちた。" % dish_name


func _buff_effect_text(buff: Dictionary) -> String:
	var text := String(buff.get("text", "次の釣行で効果を得る"))
	if text.begins_with("次の釣行で"):
		text = text.trim_prefix("次の釣行で")
	return "%s / 1回の釣行で発動" % text


func _compact_effect_preview_text(buff: Dictionary) -> String:
	var text := String(buff.get("text", "効果を得る"))
	if text.begins_with("次の釣行で"):
		text = text.trim_prefix("次の釣行で")
	text = text.replace("安全テンション域", "安全域")
	return text.strip_edges()


func _meal_buff_reward_text(buff: Dictionary) -> String:
	var text := String(buff.get("text", "次の釣行で効果を得る"))
	if text.begins_with("次の釣行で"):
		text = text.trim_prefix("次の釣行で")
	text = text.replace("安全テンション域", "安全域")
	return "%s\n次回1回で発動" % text


func _meal_bonus_badge_text(result: Dictionary) -> String:
	if bool(result.get("first_time", false)):
		return "初回ボーナス +%d EXP" % int(result.get("first_bonus", 0))
	return "初回 記録済み"


func _draw_confirm_button_cue(button: Button) -> void:
	var center := Vector2(32.0, button.size.y * 0.5)
	var active := not button.disabled
	var gold := Palette.GOLD_BRIGHT if active else Palette.COOKING_REWARD_BUTTON_DISABLED_GOLD
	var ink := (
		Palette.COOKING_REWARD_BUTTON_ACTIVE_INK
		if active
		else Palette.COOKING_REWARD_BUTTON_DISABLED_INK
	)
	var cyan := Palette.GAUGE_CYAN_HI if active else Palette.COOKING_REWARD_BUTTON_DISABLED_CYAN
	var red := Palette.GAUGE_RED_HI if active else Palette.COOKING_REWARD_BUTTON_DISABLED_RED
	var glow := (
		Palette.COOKING_REWARD_BUTTON_ACTIVE_GLOW
		if active
		else Palette.COOKING_REWARD_BUTTON_DISABLED_GLOW
	)
	button.draw_circle(center, 22.0, glow)
	match _preview_state:
		"MEAL_RESULT":
			_draw_meal_confirm_runway(button, gold, cyan)
			_draw_button_meal_to_exp(button, center, ink, gold, cyan)
		"EXP_GAIN_LEVELUP":
			_draw_button_exp_to_level(button, center, ink, gold, red)
		_:
			_draw_button_exp_to_summary(button, center, ink, gold, cyan)


func _apply_flow_button_style(button: Button) -> void:
	# 左端の導線グリフと本文の描画領域を明確に分離する。
	CookingAssets.apply_flow_button_style(button, 88.0, 6.0)


func _set_confirm_button_emphasis(is_meal_result: bool) -> void:
	if _confirm_button == null:
		return
	_confirm_button.add_theme_font_size_override("font_size", 18 if is_meal_result else 15)
	_confirm_button.add_theme_constant_override("outline_size", 3 if is_meal_result else 2)
	_confirm_button.add_theme_color_override(
		"font_outline_color", Palette.COOKING_REWARD_CARD_FRAME_BORDER
	)


func _draw_meal_confirm_runway(button: Button, gold: Color, cyan: Color) -> void:
	var w := button.size.x
	var h := button.size.y
	if w <= 0.0 or h <= 0.0:
		return
	var mid_y := h * 0.50
	var left := 76.0
	var right := w - 44.0
	button.draw_rect(
		Rect2(Vector2(left - 5.0, h * 0.23), Vector2(maxf(0.0, right - left + 6.0), h * 0.54)),
		Color(Palette.COOKING_REWARD_DARK_BACKDROP, 0.22)
	)
	button.draw_line(
		Vector2(left + 18.0, mid_y - 14.0),
		Vector2(right - 40.0, mid_y - 14.0),
		Color(Palette.COOKING_REWARD_ACCENT_BONUS, 0.18),
		2.0
	)
	button.draw_line(
		Vector2(left + 18.0, mid_y + 14.0),
		Vector2(right - 40.0, mid_y + 14.0),
		Color(Palette.COOKING_REWARD_ACCENT_EXP, 0.12),
		2.0
	)
	var rail := gold
	rail.a = 0.42
	button.draw_line(Vector2(left, 8.0), Vector2(right, 8.0), rail, 1.6)
	button.draw_line(
		Vector2(left, h - 8.0),
		Vector2(right, h - 8.0),
		Color(Palette.COOKING_REWARD_ACCENT_FALLBACK, 0.24),
		1.6
	)
	button.draw_line(
		Vector2(left + 6.0, mid_y),
		Vector2(right - 24.0, mid_y),
		Color(Palette.COOKING_REWARD_ACCENT_BONUS, 0.26),
		6.0
	)
	button.draw_line(
		Vector2(left + 6.0, mid_y),
		Vector2(right - 24.0, mid_y),
		Color(Palette.COOKING_REWARD_ACCENT_EXP, 0.24),
		1.8
	)
	for i in range(4):
		var x := left + 42.0 + float(i) * ((right - left - 110.0) / 3.0)
		var drop := gold if i % 2 == 0 else cyan
		drop.a = 0.34
		button.draw_colored_polygon(
			PackedVector2Array(
				[
					Vector2(x - 7.0, mid_y - 16.0),
					Vector2(x + 7.0, mid_y - 16.0),
					Vector2(x, mid_y - 7.0),
				]
			),
			drop
		)
	for i in range(3):
		var x := right - 86.0 + float(i) * 18.0
		var arrow := gold
		arrow.a = 0.50 - float(i) * 0.06
		button.draw_colored_polygon(
			PackedVector2Array(
				[
					Vector2(x + 9.0, mid_y),
					Vector2(x - 2.0, mid_y - 6.0),
					Vector2(x - 2.0, mid_y + 6.0),
				]
			),
			arrow
		)
	var orb_center := Vector2(w - 30.0, mid_y)
	button.draw_circle(orb_center, 12.0, Color(Palette.COOKING_REWARD_CARD_FRAME_BORDER, 0.58))
	button.draw_circle(orb_center, 8.0, Color(Palette.COOKING_REWARD_EXP_ORB_FILL, 0.72))
	var orb := cyan
	orb.a = 0.86
	button.draw_circle(orb_center, 4.5, orb)
	for i in range(4):
		var p := Vector2(w - 65.0 + float(i) * 10.0, mid_y - 15.0 + float(i % 2) * 30.0)
		var spark := gold if i % 2 == 0 else cyan
		spark.a = 0.46
		button.draw_line(p + Vector2(-2.5, 0.0), p + Vector2(2.5, 0.0), spark, 1.2)
		button.draw_line(p + Vector2(0.0, -2.5), p + Vector2(0.0, 2.5), spark, 1.2)


func _draw_button_meal_to_exp(
	button: Button, center: Vector2, ink: Color, gold: Color, cyan: Color
) -> void:
	button.draw_arc(
		center + Vector2(-7.0, 6.0),
		13.0,
		0.0,
		PI,
		18,
		Palette.COOKING_REWARD_IVORY_FILL,
		5.0
	)
	button.draw_arc(center + Vector2(-7.0, 2.0), 10.0, 0.0, PI, 16, gold, 4.0)
	for i in range(2):
		var x := center.x - 15.0 + float(i) * 9.0
		button.draw_arc(
			Vector2(x, center.y - 12.0),
			6.0,
			-1.5,
			0.9,
			8,
			Palette.COOKING_REWARD_BUTTON_STEAM,
			2.0
		)
	button.draw_line(center + Vector2(10.0, 0.0), center + Vector2(34.0, 0.0), gold, 3.0)
	button.draw_colored_polygon(
		PackedVector2Array(
			[
				center + Vector2(40.0, 0.0),
				center + Vector2(28.0, -7.0),
				center + Vector2(28.0, 7.0),
			]
		),
		gold
	)
	button.draw_circle(center + Vector2(57.0, 0.0), 12.0, Palette.COOKING_REWARD_EXP_ORB_FILL)
	button.draw_circle(center + Vector2(57.0, 0.0), 7.0, cyan)
	button.draw_line(center + Vector2(51.0, 0.0), center + Vector2(63.0, 0.0), ink, 2.0)


func _draw_button_exp_to_level(
	button: Button, center: Vector2, ink: Color, gold: Color, red: Color
) -> void:
	# 40px高の導線に複数の小グリフを詰めず、成長先を示す単一の上向き矢印にする。
	var glyph_center := center + Vector2(2.0, 0.0)
	button.draw_circle(glyph_center, 15.0, ink)
	button.draw_circle(glyph_center, 12.0, Color(red, 0.82))
	button.draw_line(glyph_center + Vector2(0.0, 8.0), glyph_center + Vector2(0.0, -7.0), gold, 3.0)
	button.draw_colored_polygon(
		PackedVector2Array(
			[
				glyph_center + Vector2(0.0, -13.0),
				glyph_center + Vector2(-7.0, -4.0),
				glyph_center + Vector2(7.0, -4.0),
			]
		),
		gold
	)


func _draw_button_exp_to_summary(
	button: Button, center: Vector2, ink: Color, gold: Color, cyan: Color
) -> void:
	# 準備画面へ戻る導線も、本文と競合しない単一の右向き矢印へ簡略化する。
	var glyph_center := center + Vector2(2.0, 0.0)
	button.draw_circle(glyph_center, 15.0, ink)
	button.draw_circle(glyph_center, 12.0, Color(cyan, 0.76))
	button.draw_line(glyph_center + Vector2(-7.0, 0.0), glyph_center + Vector2(7.0, 0.0), gold, 3.0)
	button.draw_colored_polygon(
		PackedVector2Array(
			[
				glyph_center + Vector2(13.0, 0.0),
				glyph_center + Vector2(4.0, -7.0),
				glyph_center + Vector2(4.0, 7.0),
			]
		),
		gold
	)


func _draw_exp_focus_burst() -> void:
	if (
		_exp_focus_card == null
		or _exp_focus_burst_layer == null
		or not _exp_focus_card.visible
	):
		return
	var rect := Rect2(Vector2.ZERO, _exp_focus_burst_layer.size)
	var center := Vector2(rect.size.x * 0.5, rect.size.y * 0.48)
	var gold := Palette.GOLD_BRIGHT
	var cyan := Palette.GAUGE_CYAN_HI
	for i in range(22):
		var angle := TAU * float(i) / 22.0
		var from := center + Vector2(cos(angle), sin(angle)) * 16.0
		var to := center + Vector2(cos(angle), sin(angle)) * 252.0
		var color := gold if i % 2 == 0 else cyan
		color.a = 0.16 if i % 2 == 0 else 0.11
		_exp_focus_burst_layer.draw_line(from, to, color, 5.0)
	for i in range(6):
		var width := rect.size.x - 48.0 - float(i) * 18.0
		var y := rect.size.y * 0.60 + float(i) * 2.0
		var color := cyan
		color.a = 0.15 - float(i) * 0.014
		_exp_focus_burst_layer.draw_rect(
			Rect2(Vector2((rect.size.x - width) * 0.5, y), Vector2(width, 12.0)),
			color
		)
	for i in range(22):
		var p := Vector2(
			rect.size.x * (0.12 + float((i * 37) % 78) / 100.0),
			rect.size.y * (0.14 + float((i * 23) % 64) / 100.0)
		)
		var color := gold if i % 3 != 0 else cyan
		color.a = 0.42
		var radius := 2.0 + float(i % 3)
		_exp_focus_burst_layer.draw_line(p + Vector2(-radius, 0.0), p + Vector2(radius, 0.0), color, 2.0)
		_exp_focus_burst_layer.draw_line(p + Vector2(0.0, -radius), p + Vector2(0.0, radius), color, 2.0)


func _build_status_strip(parent: VBoxContainer) -> void:
	_status_strip = CookingRewardStatusStripScript.new()
	parent.add_child(_status_strip)


func _add_meal_scene_background() -> void:
	_stage_base = ColorRect.new()
	_stage_base.name = "RewardStageBase"
	_stage_base.color = Palette.COOKING_REWARD_DIALOG_FILL
	_stage_base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stage_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage_base.visible = false
	add_child(_stage_base)

	_stage_background = TextureRect.new()
	_stage_background.name = "RewardStageBackground"
	_stage_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_stage_background.stretch_mode = TextureRect.STRETCH_SCALE
	_stage_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stage_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage_background)
	_set_stage_background(MEAL_SCENE_BG)


func _set_stage_background(path: String) -> void:
	if _stage_background == null:
		return
	var bg_tex := load(path) as Texture2D
	if bg_tex != null:
		_stage_background.texture = bg_tex


func _set_stage_base_visible(visible: bool) -> void:
	if _stage_base != null:
		_stage_base.visible = visible


func _add_reward_ambient_layer() -> void:
	var ambient := Control.new()
	ambient.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ambient.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ambient)
	ambient.draw.connect(
		func() -> void:
			var steam := Palette.TEXT_BONE
			var spark := Palette.GOLD_BRIGHT
			for i in range(6):
				var x := 250.0 + float(i) * 154.0
				var y := 440.0 - float(i % 3) * 26.0
				steam.a = 0.11
				ambient.draw_arc(Vector2(x, y), 34.0, -1.65, 1.35, 22, steam, 3.0)
				steam.a = 0.07
				ambient.draw_arc(Vector2(x + 18.0, y - 34.0), 25.0, -1.45, 1.2, 18, steam, 2.0)
			for i in range(14):
				var p := Vector2(126.0 + float((i * 89) % 1030), 96.0 + float((i * 47) % 500))
				var r := 3.0 + float(i % 3)
				spark.a = 0.17 if i % 2 == 0 else 0.10
				ambient.draw_line(p + Vector2(-r, 0.0), p + Vector2(r, 0.0), spark, 2.0)
				ambient.draw_line(p + Vector2(0.0, -r), p + Vector2(0.0, r), spark, 2.0)
	)
	ambient.queue_redraw()


func preview_accept() -> void:
	if is_qa_deterministic():
		if _closing:
			return
		_closing = true
		closed.emit()
		queue_free()
		return
	_close()


func preview_state() -> String:
	return _preview_state


func _add_flow_step(parent: HBoxContainer, text: String) -> void:
	var card := _panel_box(
		Palette.COOKING_REWARD_FLOW_IDLE_FILL,
		Palette.COOKING_REWARD_CARD_FRAME_BORDER,
		Palette.GOLD_DEEP,
		3
	)
	card.name = "FlowStep_%d" % _flow_step_cards.size()
	card.custom_minimum_size = Vector2(138.0, 22.0)
	parent.add_child(card)
	var label := make_shadow_label(text, 12, Palette.TEXT_BONE, 2)
	_set_label_min_height(label, 12)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	card.add_child(label)
	_flow_step_cards.append(card)
	_flow_step_labels.append(label)


func _add_flow_connector(parent: HBoxContainer) -> void:
	var connector := FlowConnectorVisual.new()
	connector.name = "FlowConnector_%d" % _flow_connectors.size()
	connector.custom_minimum_size = Vector2(48.0, 22.0)
	connector.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(connector)
	_flow_connectors.append(connector)


func _set_flow_row_compact(compact: bool) -> void:
	if _flow_row != null:
		_flow_row.add_theme_constant_override("separation", 2 if compact else 4)
	for label in _flow_step_labels:
		label.add_theme_font_size_override("font_size", 11 if compact else 12)
		_set_label_min_height(label, 11 if compact else 12)
	for card in _flow_step_cards:
		card.custom_minimum_size = Vector2(112.0, 18.0) if compact else Vector2(138.0, 22.0)
	for connector in _flow_connectors:
		connector.custom_minimum_size = Vector2(34.0, 18.0) if compact else Vector2(48.0, 22.0)
		connector.queue_redraw()


func _refresh_flow_steps(leveled: bool) -> void:
	_set_flow_step(
		0,
		"1 食事 完了",
		Palette.COOKING_REWARD_PARCHMENT_FILL,
		Palette.GOLD_BRIGHT,
		Palette.COOKING_REWARD_DARK_TEXT
	)
	_set_flow_step(
		1,
		"2 EXP 加算中",
		Palette.COOKING_REWARD_FLOW_EXP_FILL,
		Palette.GAUGE_CYAN_HI,
		Palette.TEXT_BONE
	)
	_set_flow_connector(0, "meal_to_exp")
	if leveled:
		_set_flow_step(
			2,
			"3 成長 解放",
			Palette.COOKING_REWARD_FLOW_GROWTH_FILL,
			Palette.GAUGE_RED_HI,
			Palette.GOLD_BRIGHT
		)
		_set_flow_connector(1, "growth_unlock")
	else:
		_set_flow_step(
			2,
			"3 成長 進行中",
			Palette.COOKING_REWARD_FLOW_IDLE_FILL,
			Palette.GOLD_DEEP,
			Palette.TEXT_BONE
		)
		_set_flow_connector(1, "exp_to_growth")


func _refresh_meal_steps() -> void:
	_set_flow_step(
		0,
		"食事 完了",
		Palette.COOKING_REWARD_PARCHMENT_FILL,
		Palette.GOLD_BRIGHT,
		Palette.COOKING_REWARD_DARK_TEXT
	)
	_set_flow_step(1, "EXPへ", Palette.COOKING_REWARD_FLOW_IDLE_FILL, Palette.GOLD_DEEP, Palette.TEXT_BONE)
	_set_flow_step(2, "成長", Palette.COOKING_REWARD_FLOW_IDLE_FILL, Palette.GOLD_DEEP, Palette.TEXT_BONE)
	_set_flow_connector(0, "meal_to_exp")
	_set_flow_connector(1, "idle")


func _set_flow_step(index: int, text: String, fill: Color, border: Color, text_color: Color) -> void:
	if index < 0 or index >= _flow_step_cards.size():
		return
	var card := _flow_step_cards[index]
	var label := _flow_step_labels[index]
	card.add_theme_stylebox_override("panel", _style_box(fill, border, Palette.GOLD_BRIGHT, 3, 5))
	label.text = text
	label.add_theme_color_override("font_color", text_color)


func _set_flow_connector(index: int, mode: String) -> void:
	if index < 0 or index >= _flow_connectors.size():
		return
	_flow_connectors[index].set_mode(mode)


func _scene_actor_box() -> PanelContainer:
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.TRANSPARENT
	sb.set_border_width_all(0)
	sb.content_margin_left = 0.0
	sb.content_margin_top = 0.0
	sb.content_margin_right = 0.0
	sb.content_margin_bottom = 0.0
	panel.add_theme_stylebox_override("panel", sb)
	_scene_actor_image = TextureRect.new()
	_scene_actor_image.name = "MealSceneActor"
	_scene_actor_image.texture = load(PLAYER_EATING_POSE) as Texture2D
	_scene_actor_image.custom_minimum_size = Vector2(148.0, 0.0)
	_scene_actor_image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scene_actor_image.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scene_actor_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_scene_actor_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_scene_actor_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(_scene_actor_image)
	_scene_actor_visual = SceneActorVisual.new()
	_scene_actor_visual.name = "MealSceneActorFallback"
	_scene_actor_visual.custom_minimum_size = Vector2(110.0, 0.0)
	_scene_actor_visual.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scene_actor_visual.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scene_actor_visual.visible = false
	panel.add_child(_scene_actor_visual)
	return panel


func _set_scene_actor_mode(mode: String) -> void:
	if _scene_actor_visual != null:
		_scene_actor_visual.set_mode(mode)
	if _scene_actor_image == null:
		return
	var path := PLAYER_EXP_SCENE_POSE if mode == "exp" else PLAYER_EATING_POSE
	_scene_actor_image.texture = load(path) as Texture2D
	if mode == "meal":
		if _scene_actor_panel != null:
			_scene_actor_panel.custom_minimum_size = Vector2(184.0, 0.0)
		_scene_actor_image.custom_minimum_size = Vector2(180.0, 0.0)
		_scene_actor_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	else:
		if _scene_actor_panel != null:
			_scene_actor_panel.custom_minimum_size = Vector2(176.0, 0.0)
		_scene_actor_image.custom_minimum_size = Vector2(148.0, 0.0)
		_scene_actor_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED


func _set_scene_result_art_visible(visible: bool) -> void:
	if _scene_result_image != null:
		_scene_result_image.visible = visible
		_scene_result_image.modulate = Color.WHITE
	if _scene_table != null:
		_scene_table.modulate.a = 0.0 if visible else 1.0


func _set_scene_backdrop(path: String, alpha: float, keep_table_visible: bool) -> void:
	if _scene_result_image != null:
		var tex := load(path) as Texture2D
		if tex != null:
			_scene_result_image.texture = tex
		_scene_result_image.visible = true
		_scene_result_image.modulate = Color(Color.WHITE, alpha)
	if _scene_table != null:
		_scene_table.modulate.a = _meal_scene_foreground_alpha() if keep_table_visible else 0.0
	if _scene_table_bridge != null:
		_scene_table_bridge.visible = keep_table_visible
		_scene_table_bridge.modulate.a = _meal_scene_bridge_alpha() if keep_table_visible else 1.0
		_scene_table_bridge.queue_redraw()


func _meal_scene_foreground_alpha() -> float:
	return 0.035 if _preview_state == "MEAL_RESULT" else 1.0


func _meal_scene_bridge_alpha() -> float:
	return 0.14 if _preview_state == "MEAL_RESULT" else 1.0


func _set_header_title_font_size(font_size: int) -> void:
	if _header_title != null:
		_header_title.add_theme_font_size_override("font_size", font_size)
		_set_label_min_height(_header_title, font_size)


func _set_bridge_font_size(font_size: int) -> void:
	if _bridge_label != null:
		_bridge_label.add_theme_font_size_override("font_size", font_size)
		_set_label_min_height(_bridge_label, font_size)


func _set_exp_label_font_size(font_size: int) -> void:
	if _exp_label != null:
		_exp_label.add_theme_font_size_override("font_size", font_size)
		_set_label_min_height(_exp_label, font_size)


func _set_result_banner_height(height: float) -> void:
	if _result_banner != null:
		_result_banner.custom_minimum_size = Vector2(0.0, height)


func _apply_meal_result_composition() -> void:
	_set_dialog_meal_result_style()
	_set_result_banner_meal_style()
	if _scene_card != null:
		_scene_card.custom_minimum_size = Vector2(446.0, 328.0)
		_set_scene_card_meal_result_style()
	if _scene_visual_stack != null:
		_scene_visual_stack.custom_minimum_size = Vector2(0.0, 306.0)
	if _scene_title != null:
		_scene_title.visible = false
	if _scene_actor_panel != null:
		_scene_actor_panel.visible = true
		_scene_actor_panel.custom_minimum_size = Vector2(184.0, 0.0)
	if _scene_table != null:
		_scene_table.add_theme_constant_override("separation", 0)
	if _scene_dish_image != null:
		_scene_dish_image.custom_minimum_size = Vector2(250.0, 248.0)
	if _scene_table_bridge != null:
		_scene_table_bridge.visible = true
		_scene_table_bridge.queue_redraw()
	if _scene_foreground_glow != null:
		_scene_foreground_glow.visible = true
		_scene_foreground_glow.queue_redraw()
	if _scene_caption != null:
		_scene_caption.visible = false
	if _scene_bonus_label != null:
		_scene_bonus_label.visible = false
	if _dish_card != null:
		_dish_card.custom_minimum_size = Vector2(0.0, 198.0)
	if _dish_card_bridge != null:
		_dish_card_bridge.visible = true
		_dish_card_bridge.queue_redraw()
	if _dish_image != null:
		_dish_image.custom_minimum_size = Vector2(462.0, 0.0)
		_dish_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if _dish_title != null:
		_dish_title.add_theme_font_size_override("font_size", 21)
		_dish_title.custom_minimum_size = Vector2(0.0, 58.0)
	if _dish_note_label != null:
		_dish_note_label.visible = false
	if _flow_row != null:
		_flow_row.visible = false
		_flow_row.modulate.a = 0.58
	_set_flow_row_compact(true)
	if _confirm_button != null:
		_confirm_button.custom_minimum_size = Vector2(448.0, 58.0)
	if _meal_reward_cue != null:
		_meal_reward_cue.visible = true
		_meal_reward_cue.custom_minimum_size = Vector2(0.0, 16.0)
	if _meal_banner_spark != null:
		_meal_banner_spark.visible = true
		_meal_banner_spark.queue_redraw()
	if _meal_result_mode_label != null:
		_meal_result_mode_label.visible = true
	if _reward_cards != null:
		_reward_cards.queue_redraw()
	_set_status_strip_emphasis(false)
	_reward_cards.set_reward_cards_height(142.0)


func _apply_exp_gain_composition() -> void:
	_set_dialog_reward_frame_style()
	_set_result_banner_exp_gain_style()
	if _scene_card != null:
		_scene_card.custom_minimum_size = Vector2(294.0, 348.0)
		_set_scene_card_exp_gain_style()
	if _scene_title != null:
		_scene_title.visible = true
	if _scene_visual_stack != null:
		_scene_visual_stack.custom_minimum_size = Vector2(0.0, 224.0)
	if _scene_actor_panel != null:
		_scene_actor_panel.visible = false
	if _scene_table != null:
		_scene_table.add_theme_constant_override("separation", 0)
	if _scene_dish_image != null:
		_scene_dish_image.custom_minimum_size = Vector2(260.0, 178.0)
	if _scene_caption != null:
		_scene_caption.visible = true
	if _scene_bonus_label != null:
		_scene_bonus_label.visible = true
	if _exp_focus_card != null:
		_exp_focus_card.custom_minimum_size = Vector2(0.0, 332.0)
	if _exp_bar != null:
		_exp_bar.custom_minimum_size = Vector2(0.0, 60.0)
	if _effect_preview_card != null:
		_effect_preview_card.custom_minimum_size = Vector2(224.0, 348.0)
	if _meal_reward_cue != null:
		_meal_reward_cue.visible = false
		_meal_reward_cue.custom_minimum_size = Vector2(0.0, 0.0)
	if _meal_banner_spark != null:
		_meal_banner_spark.visible = false
	if _meal_result_mode_label != null:
		_meal_result_mode_label.visible = false
	if _scene_table_bridge != null:
		_scene_table_bridge.visible = false
	if _scene_foreground_glow != null:
		_scene_foreground_glow.visible = false
	if _dish_card_bridge != null:
		_dish_card_bridge.visible = false
	if _dish_image != null:
		_dish_image.custom_minimum_size = Vector2(304.0, 0.0)
		_dish_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if _dish_title != null:
		_dish_title.add_theme_font_size_override("font_size", 30)
	if _dish_note_label != null:
		_dish_note_label.visible = true
	if _flow_row != null:
		_flow_row.visible = false
		_flow_row.modulate.a = 0.18
	_set_flow_row_compact(false)
	if _confirm_button != null:
		_confirm_button.custom_minimum_size = Vector2(318.0, 40.0)
	_set_confirm_button_emphasis(false)
	_set_status_strip_emphasis(true)
	_reward_cards.set_reward_cards_height(84.0)


func _set_dialog_meal_result_style() -> void:
	if _dialog == null:
		return
	_dialog.add_theme_stylebox_override("panel", _transparent_dialog_style(4.0, 0.0, 4.0, 3.0))


func _set_dialog_reward_frame_style() -> void:
	if _dialog == null:
		return
	_dialog.add_theme_stylebox_override("panel", _reward_dialog_frame_style())


func _transparent_dialog_style(left: float, top: float, right: float, bottom: float) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.TRANSPARENT
	sb.border_color = Color.TRANSPARENT
	sb.set_border_width_all(0)
	sb.set_corner_radius_all(0)
	sb.content_margin_left = left
	sb.content_margin_top = top
	sb.content_margin_right = right
	sb.content_margin_bottom = bottom
	sb.shadow_color = Color.TRANSPARENT
	sb.shadow_size = 0
	sb.shadow_offset = Vector2.ZERO
	sb.anti_aliasing = false
	return sb


func _reward_dialog_frame_style() -> StyleBox:
	return _texture_style_box(
		MEAL_RESULT_FRAME,
		34,
		_style_box(
			Palette.COOKING_REWARD_DIALOG_FILL,
			Palette.COOKING_REWARD_FRAME_BORDER,
			Palette.GOLD_BRIGHT,
			6,
			8
		),
		18.0,
		2.0
	)


func _set_result_banner_meal_style() -> void:
	if _result_banner == null:
		return
	_result_banner.add_theme_stylebox_override("panel", _meal_result_banner_style())


func _set_result_banner_exp_gain_style() -> void:
	if _result_banner == null:
		return
	_result_banner.add_theme_stylebox_override("panel", _meal_result_banner_style())


func _meal_result_banner_style() -> StyleBox:
	return _texture_style_box(
		MEAL_BANNER_FRAME,
		24,
		_style_box(
			Palette.COOKING_REWARD_PARCHMENT_FILL,
			Palette.COOKING_REWARD_FRAME_BORDER,
			Palette.GOLD_BRIGHT,
			5,
			5
		),
		18.0,
		6.0
	)


func _set_scene_card_meal_result_style() -> void:
	if _scene_card == null:
		return
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.TRANSPARENT
	sb.border_color = Color(Palette.COOKING_REWARD_ACCENT_BONUS, 0.06)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	sb.content_margin_left = 1.0
	sb.content_margin_top = 1.0
	sb.content_margin_right = 1.0
	sb.content_margin_bottom = 1.0
	sb.shadow_color = Color.TRANSPARENT
	sb.shadow_size = 0
	sb.shadow_offset = Vector2.ZERO
	sb.anti_aliasing = false
	_scene_card.add_theme_stylebox_override("panel", sb)


func _set_scene_card_exp_gain_style() -> void:
	if _scene_card == null:
		return
	_scene_card.add_theme_stylebox_override(
		"panel",
		_style_box(
			Palette.COOKING_REWARD_SCENE_CARD_FILL,
			Palette.COOKING_REWARD_FRAME_BORDER,
			Palette.GOLD_BRIGHT,
			5,
			5
		)
	)


func _set_status_strip_emphasis(is_primary: bool) -> void:
	_status_strip.set_emphasis(is_primary)


func _build_effect_preview_card(parent: HBoxContainer) -> void:
	_effect_preview_card = _compact_panel_box(
		Palette.COOKING_REWARD_PARCHMENT_FILL,
		Palette.COOKING_REWARD_EFFECT_BORDER,
		Palette.COOKING_REWARD_ACCENT_BUFF,
		4
	)
	_effect_preview_card.custom_minimum_size = Vector2(252.0, 208.0)
	_effect_preview_card.visible = false
	parent.add_child(_effect_preview_card)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 2)
	_effect_preview_card.add_child(box)

	var title := make_shadow_label("次の釣行で効果！", 16, Palette.TEXT_BONE, 2)
	title.z_index = 8
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	_set_label_min_height(title, 16)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Palette.TEXT_BONE)
	var title_panel := _compact_panel_box(
		Palette.COOKING_REWARD_BUFF_FIELD,
		Palette.COOKING_REWARD_CARD_FRAME_BORDER,
		Palette.GAUGE_GREEN_HI,
		3
	)
	title_panel.custom_minimum_size = Vector2(0.0, 28.0)
	title_panel.add_child(title)
	box.add_child(title_panel)

	_effect_name_label = make_shadow_label(
		"次回効果",
		20,
		Palette.COOKING_REWARD_EFFECT_NAME_TEXT,
		2,
		Palette.TEXT_BONE
	)
	_effect_name_label.z_index = 8
	_effect_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_effect_name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_effect_name_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	_set_label_min_height(_effect_name_label, 20)
	_effect_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_effect_name_label)

	_effect_preview_visual = TextureRect.new()
	_effect_preview_visual.name = "NextEffectArt"
	_effect_preview_visual.texture = load(EffectPreviewVisual.EFFECT_ART) as Texture2D
	_effect_preview_visual.custom_minimum_size = Vector2(0.0, 102.0)
	_effect_preview_visual.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_effect_preview_visual.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_effect_preview_visual.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_effect_preview_visual.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(_effect_preview_visual)

	_effect_text_label = make_shadow_label(
		"", 13, Palette.COOKING_REWARD_DARK_TEXT, 1, Palette.TEXT_BONE
	)
	_effect_text_label.z_index = 8
	_effect_text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_set_label_min_height(_effect_text_label, 13, 2)
	_effect_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_effect_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_effect_text_label)

	_effect_duration_label = make_shadow_label(
		"", 12, Palette.COOKING_REWARD_EFFECT_DURATION_TEXT, 1, Palette.TEXT_BONE
	)
	_effect_duration_label.z_index = 8
	_effect_duration_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_set_label_min_height(_effect_duration_label, 12)
	_effect_duration_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_effect_duration_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_effect_duration_label)


func _set_label_min_height(label: Label, font_size: int, lines := 1) -> void:
	if label == null:
		return
	var outline := label.get_theme_constant("outline_size")
	var height := float(font_size * maxi(1, lines)) * 1.35 + float(outline * 2)
	label.custom_minimum_size.y = maxf(label.custom_minimum_size.y, ceilf(height))


func _present() -> void:
	_dialog.modulate.a = 0.0
	_dialog.scale = Vector2(0.86, 0.86)
	await get_tree().process_frame
	_dialog.pivot_offset = _dialog.size * 0.5
	if is_qa_deterministic():
		_snap_present_state()
		return
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property(_dialog, "scale", Vector2.ONE, 0.28)
	tw.parallel().tween_property(_dialog, "modulate:a", 1.0, 0.16)
	tw.tween_callback(_animate_exp)
	Juicer.add_trauma(0.18)


func _snap_present_state() -> void:
	_dialog.scale = Vector2.ONE
	_dialog.modulate.a = 1.0
	_snap_exp_animation()


func _snap_exp_animation() -> void:
	if not _exp_focus_card.visible:
		return
	_exp_bar.set_value(_target_exp)
	_exp_label.scale = Vector2.ONE
	_exp_label.pivot_offset = _exp_label.size * 0.5


func _animate_exp() -> void:
	if not _exp_focus_card.visible:
		return
	if is_qa_deterministic():
		_snap_exp_animation()
		return
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_CUBIC)
	tw.tween_method(
		func(v: float) -> void:
			_exp_bar.set_value(v),
		_exp_bar.value,
		_target_exp,
		0.55
	)
	tw.tween_callback(_pulse_exp_label)


func _pulse_exp_label() -> void:
	_exp_label.pivot_offset = _exp_label.size * 0.5
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property(_exp_label, "scale", Vector2(1.12, 1.12), 0.12)
	tw.tween_property(_exp_label, "scale", Vector2.ONE, 0.18)


func _close() -> void:
	if _closing:
		return
	_closing = true
	_confirm_button.disabled = true
	_apply_close_cue()
	_dialog.pivot_offset = _dialog.size * 0.5
	var tw := create_tween()
	tw.set_ease(Tween.EASE_IN)
	tw.set_trans(Tween.TRANS_QUAD)
	tw.tween_property(_dialog, "scale", Vector2(0.92, 0.92), 0.18)
	tw.parallel().tween_property(_dialog, "modulate:a", 0.0, 0.18)
	tw.tween_callback(
		func() -> void:
			closed.emit()
			queue_free()
	)


func _apply_close_cue() -> void:
	match _preview_state:
		"MEAL_RESULT":
			_bridge_label.text = "食経験値へ移ります。料理の力をゲージに送ります。"
			_set_flow_step(
				1,
				"2 EXP 起動",
				Palette.COOKING_REWARD_FLOW_EXP_FILL,
				Palette.GAUGE_CYAN_HI,
				Palette.TEXT_BONE
			)
			_confirm_button.text = "食経験値へ移動中"
		"EXP_GAIN_LEVELUP":
			_bridge_label.text = "成長結果を開きます。"
			_set_flow_step(
				2,
				"3 成長 表示",
				Palette.COOKING_REWARD_FLOW_GROWTH_FILL,
				Palette.GAUGE_RED_HI,
				Palette.GOLD_BRIGHT
			)
			_confirm_button.text = "成長を表示中"
		"EXP_GAIN":
			_bridge_label.text = "食事効果と経験値を保存して、現在の準備へ戻ります。"
			_set_flow_step(
				2,
				"3 成長 保存",
				Palette.COOKING_REWARD_FLOW_IDLE_FILL,
				Palette.GAUGE_CYAN_HI,
				Palette.TEXT_BONE
			)
			_confirm_button.text = "準備へ戻っています"
		_:
			pass


func _panel_box(fill: Color, border: Color, inner: Color, border_width: int) -> PanelContainer:
	return CookingAssets.panel_box(fill, border, inner, border_width)


func _compact_panel_box(fill: Color, border: Color, inner: Color, border_width: int) -> PanelContainer:
	return CookingAssets.compact_panel_box(fill, border, inner, border_width)


func _style_box(fill: Color, border: Color, inner: Color, border_width: int, radius: int) -> StyleBoxFlat:
	return CookingAssets.style_box(fill, border, inner, border_width, radius)


func _compact_style_box(fill: Color, border: Color, inner: Color, border_width: int, radius: int) -> StyleBoxFlat:
	return CookingAssets.compact_style_box(fill, border, inner, border_width, radius)


func _texture_style_box(
	path: String, margin: int, fallback: StyleBox, content_x: float, content_y: float
) -> StyleBox:
	return CookingAssets.texture_style_box(path, margin, fallback, content_x, content_y, 6.0)


func _featured_dish_texture(recipe_id: String) -> Texture2D:
	return CookingAssets.featured_dish_texture_or_icon(recipe_id)


func _recipe_icon(recipe_id: String) -> Texture2D:
	return CookingAssets.recipe_icon(recipe_id)
