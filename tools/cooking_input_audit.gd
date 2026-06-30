extends Control
## 調理場のカード選択ヒット領域監査。
# 見た目上カード内にある料理名・料理画像・素材バッジを押しても、
# 親カードの選択処理が発火することを検証する。

const ThemeFactory = preload("res://src/ui/ui_theme.gd")
const CookingScreen = preload("res://src/ui/cooking_screen.gd")

const VIEWPORT_SIZE := Vector2(1280.0, 720.0)

var _stage: Control


func _ready() -> void:
	theme = ThemeFactory.build_theme()
	_stage = Control.new()
	_stage.name = "CookingInputAuditStage1280x720"
	_stage.position = Vector2.ZERO
	_stage.size = VIEWPORT_SIZE
	_stage.custom_minimum_size = VIEWPORT_SIZE
	add_child(_stage)

	_seed_select_state()
	var screen := await _mount_cooking_screen()
	await _expect_click_selects_recipe(screen, "RecipeDishImage_sashimi", "sashimi")
	await _expect_click_selects_recipe(screen, "RecipeTitle_salt_grill", "salt_grill")
	await _expect_click_selects_recipe(screen, "RecipeMaterialBadge_sashimi", "sashimi")
	await _expect_click_selects_fish(screen, "FishRowSaba", "saba")

	print("Cooking input audit passed for recipe and fish card child hit targets.")
	get_tree().quit(0)


func _mount_cooking_screen() -> Control:
	var screen := CookingScreen.new()
	screen.theme = ThemeFactory.build_theme()
	screen.configure({"suppress_level_overlay": true})
	screen.size = VIEWPORT_SIZE
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stage.add_child(screen)
	await _tick()
	return screen


func _expect_click_selects_recipe(screen: Control, node_name: String, expected_recipe_id: String) -> void:
	var node := _find_named(screen, node_name)
	if node == null or not (node is Control):
		_fail("missing clickable recipe child '%s'." % node_name)
		return
	await _click_control(node as Control)
	var selected := String(screen.get("_selected_recipe_id"))
	if selected != expected_recipe_id:
		_fail(
			"clicking '%s' should select recipe '%s', got '%s'. %s"
			% [node_name, expected_recipe_id, selected, _debug_control_target(node as Control)]
		)


func _expect_click_selects_fish(screen: Control, node_name: String, expected_fish_id: String) -> void:
	var node := _find_named(screen, node_name)
	if node == null or not (node is Control):
		_fail("missing clickable fish child '%s'." % node_name)
		return
	await _click_control(node as Control)
	var selected := String(screen.get("_selected_fish_id"))
	if selected != expected_fish_id:
		_fail(
			"clicking '%s' should select fish '%s', got '%s'. %s"
			% [node_name, expected_fish_id, selected, _debug_control_target(node as Control)]
		)


func _click_control(control: Control) -> void:
	var rect := control.get_global_rect()
	if rect.size.x <= 1.0 or rect.size.y <= 1.0:
		_fail("control '%s' should have a non-zero rect, got %s." % [control.name, rect])
		return
	var position := rect.get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = position
	motion.global_position = position
	get_viewport().push_input(motion, true)
	var down := InputEventMouseButton.new()
	down.position = position
	down.global_position = position
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	get_viewport().push_input(down, true)
	var up := InputEventMouseButton.new()
	up.position = position
	up.global_position = position
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	get_viewport().push_input(up, true)
	await _tick()


func _find_named(node: Node, node_name: String) -> Node:
	if node.name == node_name:
		return node
	for child in node.get_children():
		var found := _find_named(child, node_name)
		if found != null:
			return found
	return null


func _debug_control_target(control: Control) -> String:
	var hovered := get_viewport().gui_get_hovered_control()
	var hovered_name := "<none>" if hovered == null else String(hovered.name)
	var root := control
	while root.get_parent() is Control and not String(root.name).begins_with("RecipeCard_") and not String(root.name).begins_with("FishRow"):
		root = root.get_parent() as Control
	return "target_filter=%d root=%s root_filter=%d hovered=%s" % [
		control.mouse_filter,
		root.name,
		root.mouse_filter,
		hovered_name,
	]


func _tick() -> void:
	await get_tree().process_frame
	await get_tree().process_frame


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)


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
