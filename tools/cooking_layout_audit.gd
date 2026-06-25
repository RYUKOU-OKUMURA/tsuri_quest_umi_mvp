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
	screen.queue_free()
	await _tick()


func _audit_exp_gain() -> void:
	_seed_exp_gain_state()
	var screen := await _mount_cooking_screen()
	screen.preview_show_reward_result(_fake_non_level_result(), 80, 100, 150, false)
	await get_tree().create_timer(0.7).timeout
	await _audit_tree("EXP_GAIN", screen)
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
	panel.queue_free()
	await _tick()


func _audit_status_summary() -> void:
	_seed_after_meal_state()
	var screen := await _mount_cooking_screen()
	screen.preview_show_status_overlay()
	await get_tree().create_timer(0.4).timeout
	await _audit_tree("STATUS_SUMMARY", screen)
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
	if card_count < 5:
		_failures.append("%s: RecipeGrid should expose at least 5 recipe cards, got %d." % [state, card_count])


func _find_named(node: Node, node_name: String) -> Node:
	if node.name == node_name:
		return node
	for child in node.get_children():
		var found := _find_named(child, node_name)
		if found != null:
			return found
	return null


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


func _node_path(control: Control) -> String:
	return str(control.get_path())


func _trim(value: String) -> String:
	var single_line := value.replace("\n", " ").strip_edges()
	if single_line.length() > 36:
		return single_line.substr(0, 33) + "..."
	return single_line
