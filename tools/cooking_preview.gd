extends Control
## 調理フローの状態別キャプチャツール。
# PlayerProgress を一時的に捏造し、保存を伴う cook_and_eat() は呼ばない。
const ThemeFactory = preload("res://src/ui/ui_theme.gd")
const CookingScreen = preload("res://src/ui/cooking_screen.gd")

const OUT_ALL := "/tmp/tsuri_cooking.png"
const OUT_SELECT := "/tmp/tsuri_cooking_select.png"
const OUT_RESULT := "/tmp/tsuri_cooking_result.png"
const OUT_EXP := "/tmp/tsuri_cooking_exp.png"
const OUT_LEVELUP := "/tmp/tsuri_cooking_levelup.png"
const OUT_STATUS := "/tmp/tsuri_cooking_status.png"
const OUT_C1B_HOVER_FOCUS := "/tmp/tsuri_cooking_c1b_hover_focus.png"
const OUT_MANIFEST := "/tmp/tsuri_cooking_capture_manifest.json"
const VW := Vector2i(1280, 720)
const CAPTURE_SETTLE_FRAMES := 10

var _capture_manifest: Array[Dictionary] = []


func _ready() -> void:
	if ScreenBase.is_qa_deterministic():
		seed(20260705)
	theme = ThemeFactory.build_theme()
	_reset_manifest()

	var vp := _new_capture_viewport()

	_seed_reference_select_state()
	var screen := await _mount_screen(vp)
	if not _expect_current_prep_summary(screen, "COOK_SELECT capture"):
		get_tree().quit(1)
		return
	await _await_capture_ready(vp)
	if not await _save_viewport(vp, OUT_SELECT):
		get_tree().quit(1)
		return
	_record_capture("COOK_SELECT", OUT_SELECT, "current_prep_summary")
	if not await _save_viewport(vp, OUT_ALL):
		get_tree().quit(1)
		return
	var hover_card := _find_named(screen, "RecipeCard_sashimi") as Control
	if hover_card == null:
		push_error("COOK-C1B hover capture requires RecipeCard_sashimi.")
		get_tree().quit(1)
		return
	var hover_before := hover_card.self_modulate
	var hover_motion := InputEventMouseMotion.new()
	hover_motion.position = hover_card.get_global_rect().get_center()
	hover_motion.global_position = hover_motion.position
	vp.push_input(hover_motion, true)
	await _await_capture_ready(vp)
	if hover_card.self_modulate == hover_before:
		push_error("COOK-C1B hover capture did not activate the recipe hover tint.")
		get_tree().quit(1)
		return
	if not await _save_viewport(vp, OUT_C1B_HOVER_FOCUS):
		get_tree().quit(1)
		return

	screen.queue_free()
	vp.queue_free()
	await get_tree().process_frame

	_seed_select_state()
	vp = _new_capture_viewport()
	screen = await _mount_screen(vp)
	var fake_result := _fake_meal_result()
	_seed_after_meal_state()
	var meal_result := fake_result.duplicate(true)
	meal_result["status_snapshot"] = _meal_status_snapshot(7, 165, 285)
	screen.preview_show_meal_reward_result(meal_result, true)

	await _await_capture_ready(vp)
	if not _expect_reward_state(screen, "MEAL_RESULT", "MEAL_RESULT capture"):
		get_tree().quit(1)
		return
	if not _expect_c0_meal_result_contract(screen, "MEAL_RESULT capture"):
		get_tree().quit(1)
		return
	if not _expect_c0_flow_button_contract(
		screen, "RewardConfirmButton", "RewardConfirmCue", "meal", 88.0, "MEAL_RESULT capture"
	):
		get_tree().quit(1)
		return
	if not await _save_viewport(vp, OUT_RESULT):
		get_tree().quit(1)
		return
	_record_capture("MEAL_RESULT", OUT_RESULT, "MEAL_RESULT")

	screen.queue_free()
	vp.queue_free()
	await get_tree().process_frame

	_seed_select_state()
	vp = _new_capture_viewport()
	screen = await _mount_screen(vp)
	var non_level_result := _fake_non_level_result()
	_seed_after_non_level_meal_state()
	screen.preview_show_reward_result(non_level_result, 127, 165, 285, false)
	await _await_capture_ready(vp)
	if not _expect_reward_state(screen, "EXP_GAIN", "EXP_GAIN capture"):
		get_tree().quit(1)
		return
	if not _expect_c0_flow_button_contract(
		screen, "RewardConfirmButton", "RewardConfirmCue", "summary", 88.0, "EXP_GAIN capture"
	):
		get_tree().quit(1)
		return
	if not _expect_c0_non_meal_stage_contract(screen, "EXP_GAIN capture"):
		get_tree().quit(1)
		return
	if not await _save_viewport(vp, OUT_EXP):
		get_tree().quit(1)
		return
	_record_capture("EXP_GAIN", OUT_EXP, "EXP_GAIN")

	screen.queue_free()
	vp.queue_free()
	await get_tree().process_frame

	_seed_select_state()
	vp = _new_capture_viewport()
	screen = await _mount_screen(vp, false)
	var boss_unlock_result := _fake_boss_unlock_result()
	_seed_after_boss_unlock_meal_state()
	screen.preview_show_reward_result(boss_unlock_result, 92, 150, 150, true)
	await _await_capture_ready(vp)
	if not _expect_reward_state(screen, "EXP_GAIN_LEVELUP", "LEVEL_UP transition"):
		get_tree().quit(1)
		return
	if not _expect_c0_non_meal_stage_contract(screen, "LEVEL_UP transition"):
		get_tree().quit(1)
		return
	if not _expect_c0_flow_button_contract(
		screen, "RewardConfirmButton", "RewardConfirmCue", "level", 88.0, "LEVEL_UP transition"
	):
		get_tree().quit(1)
		return
	if not screen.preview_accept_reward_overlay():
		push_error("Expected EXP_GAIN_LEVELUP overlay before LEVEL_UP capture.")
		get_tree().quit(1)
		return
	if ScreenBase.is_qa_deterministic():
		await _await_capture_ready(vp)
	else:
		await get_tree().create_timer(0.45).timeout
	if not _expect_level_up_overlay(screen, "LEVEL_UP capture"):
		get_tree().quit(1)
		return
	if not _expect_c0_non_meal_stage_contract(screen, "LEVEL_UP capture"):
		get_tree().quit(1)
		return
	if not _expect_c0_flow_button_contract(
		screen, "LevelUpConfirmButton", "LevelUpConfirmCue", "summary", 92.0, "LEVEL_UP capture"
	):
		get_tree().quit(1)
		return
	_debug_named_controls(
		screen,
		[
			"LevelUpTitle",
			"LevelUpLevelLine",
			"LevelUpSourceLine",
			"LevelUnlockRibbonLabel",
			"LevelStatNameEnergy",
			"LevelStatValuesEnergy",
			"LevelStatGainEnergy",
			"LevelUnlockTitle",
			"LevelUnlockBody",
		]
	)
	if not await _save_viewport(vp, OUT_LEVELUP):
		get_tree().quit(1)
		return
	_record_capture("LEVEL_UP_OVERLAY", OUT_LEVELUP, "LEVEL_UP_OVERLAY")

	if not _expect_level_up_overlay(screen, "STATUS_SUMMARY transition"):
		get_tree().quit(1)
		return
	if not screen.preview_accept_level_up_overlay():
		push_error("Expected LEVEL_UP_OVERLAY before STATUS_SUMMARY capture.")
		get_tree().quit(1)
		return
	if not await _wait_for_level_up_overlay_to_close(screen, "STATUS_SUMMARY capture"):
		get_tree().quit(1)
		return
	await _await_capture_ready(vp)
	if not _expect_status_overlay(screen, "STATUS_SUMMARY capture"):
		get_tree().quit(1)
		return
	if not _expect_c0_status_contract(screen, "STATUS_SUMMARY capture"):
		get_tree().quit(1)
		return
	if not await _save_viewport(vp, OUT_STATUS):
		get_tree().quit(1)
		return
	_record_capture("STATUS_SUMMARY", OUT_STATUS, "STATUS_SUMMARY")

	get_tree().quit()


func _new_capture_viewport() -> SubViewport:
	var vp := SubViewport.new()
	vp.size = VW
	vp.disable_3d = true
	vp.transparent_bg = false
	vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	return vp


func _mount_screen(vp: SubViewport, suppress_level_overlay := true) -> Control:
	var screen := CookingScreen.new()
	screen.theme = ThemeFactory.build_theme()
	screen.configure({"suppress_level_overlay": suppress_level_overlay})
	screen.size = Vector2(VW)
	vp.add_child(screen)
	await _await_capture_ready(vp)
	return screen


func _await_capture_ready(vp: SubViewport) -> void:
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var frames := CAPTURE_SETTLE_FRAMES if ScreenBase.is_qa_deterministic() else 2
	for _i in range(frames):
		await get_tree().process_frame


func _seed_select_state() -> void:
	PlayerProgress.level = 7
	PlayerProgress.exp = 165
	PlayerProgress.money = 10170
	PlayerProgress.play_seconds = 10028.0
	PlayerProgress.inventory.clear()
	PlayerProgress.inventory["aji"] = 12
	PlayerProgress.inventory["saba"] = 2
	PlayerProgress.inventory["madai"] = 1
	PlayerProgress.inventory["kasago"] = 2
	PlayerProgress.inventory["hirame"] = 1
	PlayerProgress.inventory["kawahagi"] = 1
	PlayerProgress.eaten_recipes.clear()
	PlayerProgress.pending_buff = {}


func _seed_reference_select_state() -> void:
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


func _seed_after_meal_state() -> void:
	PlayerProgress.level = 5
	PlayerProgress.exp = 20
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


func _seed_after_non_level_meal_state() -> void:
	PlayerProgress.level = 7
	PlayerProgress.exp = 165
	PlayerProgress.inventory.clear()
	PlayerProgress.inventory["mejina"] = 1
	PlayerProgress.inventory["kasago"] = 2
	PlayerProgress.inventory["isaki"] = 1
	PlayerProgress.inventory["saba"] = 1
	PlayerProgress.pending_buff = {
		"recipe_id": "simmered",
		"name": "メジナの煮付け",
		"stat": "safe_max",
		"value": 0.10,
		"text": "次の釣行で安全テンション域 +10%",
	}


func _seed_after_boss_unlock_meal_state() -> void:
	PlayerProgress.level = 5
	PlayerProgress.exp = 2
	PlayerProgress.inventory.clear()
	PlayerProgress.inventory["aji"] = 12
	PlayerProgress.inventory["saba"] = 2
	PlayerProgress.inventory["madai"] = 1
	PlayerProgress.inventory["kasago"] = 2
	PlayerProgress.inventory["hirame"] = 1
	PlayerProgress.inventory["kawahagi"] = 1
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


func _fake_meal_result() -> Dictionary:
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


func _total_fish_count() -> int:
	return GameData.inventory_fish_total(PlayerProgress.inventory)


func _fake_non_level_result() -> Dictionary:
	return {
		"ok": true,
		"dish_name": "メジナの煮付け",
		"base_exp": 38,
		"first_time": false,
		"first_bonus": 0,
		"total_exp": 38,
		"leveled_to": [],
		"buff": {
			"recipe_id": "simmered",
			"name": "メジナの煮付け",
			"stat": "safe_max",
			"value": 0.10,
			"text": "次の釣行で安全テンション域 +10%",
		},
	}


func _fake_boss_unlock_result() -> Dictionary:
	return {
		"ok": true,
		"dish_name": "アジの塩焼き",
		"base_exp": 60,
		"first_time": false,
		"first_bonus": 0,
		"total_exp": 60,
		"leveled_to": [5],
		"buff": {
			"recipe_id": "salt_grill",
			"name": "アジの塩焼き",
			"stat": "max_energy",
			"value": 0.05,
			"text": "次の釣行で最大体力 +5%",
		},
	}


func _save_viewport(vp: SubViewport, path: String) -> bool:
	var img: Image = null
	for _attempt in range(18):
		vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		await get_tree().process_frame
		if RenderingServer.has_method("force_draw"):
			RenderingServer.force_draw(false, 0.0)
		else:
			await RenderingServer.frame_post_draw
		img = vp.get_texture().get_image()
		if _image_has_visible_pixels(img):
			img.save_png(path)
			return true
	if img == null:
		push_error(
			(
				"SubViewport get_image() returned null for %s. "
				+ "If this happens with the headless/dummy display driver, "
				+ "run the preview with a real display driver."
			)
			% path
		)
		return false
	if img.is_empty():
		push_error(
			(
				"SubViewport get_image() returned an empty image for %s. "
				+ "If this happens with the headless/dummy display driver, "
				+ "run the preview with a real display driver."
			)
			% path
		)
		return false
	push_error("SubViewport capture stayed transparent for %s after waiting for redraw." % path)
	return false


func _image_has_visible_pixels(img: Image) -> bool:
	if img == null or img.is_empty():
		return false
	var max_x := maxi(0, img.get_width() - 1)
	var max_y := maxi(0, img.get_height() - 1)
	var points := [
		Vector2i(max_x / 2, max_y / 2),
		Vector2i(max_x / 4, max_y / 4),
		Vector2i(max_x * 3 / 4, max_y / 4),
		Vector2i(max_x / 4, max_y * 3 / 4),
		Vector2i(max_x * 3 / 4, max_y * 3 / 4),
	]
	for point in points:
		if img.get_pixelv(point).a > 0.01:
			return true
	return false


func _reset_manifest() -> void:
	_capture_manifest.clear()
	var file_exists := FileAccess.file_exists(OUT_MANIFEST)
	if file_exists:
		DirAccess.remove_absolute(OUT_MANIFEST)


func _record_capture(state_id: String, path: String, verified_state: String) -> void:
	_capture_manifest.append(
		{
			"state": state_id,
			"capture": path,
			"verified_state": verified_state,
			"width": VW.x,
			"height": VW.y,
		}
	)
	var payload := {
		"version": 1,
		"source": "tools/cooking_preview.gd",
		"captures": _capture_manifest,
	}
	var file := FileAccess.open(OUT_MANIFEST, FileAccess.WRITE)
	if file == null:
		push_error("Failed to write cooking capture manifest: %s" % OUT_MANIFEST)
		return
	file.store_string(JSON.stringify(payload, "\t"))


func _push_headless_capture_error(path: String) -> void:
	push_error(
		(
			"Cannot capture %s with the headless/dummy display driver. "
			+ "Run this scene with a real display driver, for example without --headless, "
			+ "to generate cooking screenshots."
		)
		% path
	)
func _expect_reward_state(screen: Control, expected_state: String, context: String) -> bool:
	if screen.preview_has_reward_overlay_state(expected_state):
		return true
	push_error("%s expected reward overlay state '%s'." % [context, expected_state])
	return false


func _expect_c0_meal_result_contract(screen: Control, context: String) -> bool:
	var base := _find_named(screen, "RewardStageBase") as ColorRect
	if (
		base == null
		or not base.is_visible_in_tree()
		or base.size != Vector2(VW)
		or not _is_c0_stage_base_fully_opaque(base)
	):
		push_error("%s requires an opaque RewardStageBase behind MEAL_RESULT." % context)
		return false
	return true


func _is_c0_stage_base_fully_opaque(base: ColorRect) -> bool:
	if base.color.a != 1.0 or base.modulate.a != 1.0 or base.self_modulate.a != 1.0:
		return false
	var parent := base.get_parent()
	while parent != null:
		if parent is CanvasItem and (parent as CanvasItem).modulate.a != 1.0:
			return false
		parent = parent.get_parent()
	return true


func _expect_c0_non_meal_stage_contract(screen: Control, context: String) -> bool:
	var base := _find_named(screen, "RewardStageBase") as Control
	if base != null and base.is_visible_in_tree():
		push_error("%s must not show RewardStageBase outside MEAL_RESULT." % context)
		return false
	return true


func _expect_c0_flow_button_contract(
	screen: Control,
	node_name: String,
	cue_name: String,
	expected_glyph_id: String,
	expected_left_margin: float,
	context: String
) -> bool:
	var button := _find_named(screen, node_name) as Button
	if button == null:
		push_error("%s missing C0 flow button '%s'." % [context, node_name])
		return false
	var style := button.get_theme_stylebox("normal")
	if style == null or style.get_content_margin(SIDE_LEFT) != expected_left_margin:
		push_error(
			"%s requires %.0fpx left glyph clearance on '%s'."
			% [context, expected_left_margin, node_name]
		)
		return false
	var cue := button.get_node_or_null(NodePath(cue_name)) as Label
	if cue == null or button.get_child_count() != 1 or cue.get_child_count() != 0:
		push_error("%s requires one direct C0 cue '%s' on '%s'." % [context, cue_name, node_name])
		return false
	if not button.draw.get_connections().is_empty():
		push_error("%s requires '%s' to avoid Button.draw glyph rendering." % [context, node_name])
		return false
	if not cue.draw.get_connections().is_empty():
		push_error("%s requires '%s' to avoid Label.draw glyph rendering." % [context, cue_name])
		return false
	if not cue.is_visible_in_tree() or int(cue.get_meta("c0_glyph_count", 0)) != 1:
		push_error("%s requires exactly one visible glyph on '%s'." % [context, node_name])
		return false
	if String(cue.get_meta("c0_glyph_id", "")) != expected_glyph_id:
		push_error(
			"%s requires C0 cue '%s' to be '%s'."
			% [context, cue_name, expected_glyph_id]
		)
		return false
	var expected_glyph_text := "▲" if expected_glyph_id == "level" else "▶"
	if cue.text != expected_glyph_text:
		push_error("%s requires exactly one '%s' glyph on '%s'." % [context, expected_glyph_text, node_name])
		return false
	return true


func _expect_c0_status_contract(screen: Control, context: String) -> bool:
	var money := _find_named(screen, "StatusMoneyValue") as Label
	if money == null or money.text != "10,170 G":
		var actual := "<missing>" if money == null else money.text
		push_error("%s requires comma-grouped money text, got '%s'." % [context, actual])
		return false
	for suffix in ["Player", "Meal", "Cooler", "Money", "PlayTime"]:
		var title_band := _find_named(screen, "StatusSummaryTitleBand%s" % suffix) as PanelContainer
		if title_band == null or not (title_band.get_theme_stylebox("panel") is StyleBoxFlat):
			push_error("%s requires a quiet runtime title band for '%s'." % [context, suffix])
			return false
	return true


func _expect_level_up_overlay(screen: Control, context: String) -> bool:
	if screen.preview_has_level_up_overlay():
		return true
	push_error("%s expected LEVEL_UP_OVERLAY." % context)
	return false


func _debug_named_controls(root: Node, node_names: Array) -> void:
	if OS.get_environment("COOKING_PREVIEW_DEBUG_LABELS") != "1":
		return
	for node_name in node_names:
		var node := _find_named(root, String(node_name))
		var control := node as Control
		if control == null:
			print("PREVIEW DEBUG %s missing" % String(node_name))
			continue
		var label := control as Label
		var text := ""
		if label != null:
			text = label.text
		print(
			"PREVIEW DEBUG %s rect=%s min=%s visible=%s modulate=%s text='%s'"
			% [
				String(node_name),
				control.get_global_rect(),
				control.get_combined_minimum_size(),
				control.is_visible_in_tree(),
				control.modulate,
				_trim(text),
			]
		)


func _find_named(node: Node, node_name: String) -> Node:
	if node.name == node_name:
		return node
	for child in node.get_children():
		var found := _find_named(child, node_name)
		if found != null:
			return found
	return null


func _trim(value: String) -> String:
	var one_line := value.replace("\n", "\\n")
	if one_line.length() <= 80:
		return one_line
	return one_line.substr(0, 77) + "..."


func _expect_status_overlay(screen: Control, context: String) -> bool:
	if screen.preview_has_status_overlay():
		return true
	push_error("%s expected STATUS_SUMMARY overlay." % context)
	return false


func _wait_for_level_up_overlay_to_close(screen: Control, context: String) -> bool:
	var max_frames := 4 if ScreenBase.is_qa_deterministic() else 24
	for _i in range(max_frames):
		await get_tree().process_frame
		if not screen.preview_has_level_up_overlay():
			return true
	push_error("%s expected LEVEL_UP_OVERLAY to close before capture." % context)
	return false


func _expect_current_prep_summary(screen: Control, context: String) -> bool:
	if screen.preview_has_current_prep_summary():
		return true
	push_error("%s expected current preparation summary." % context)
	return false
