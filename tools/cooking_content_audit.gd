extends Control
## 調理フロー5状態のheadless表示内容監査。
# スクリーンショット取得前でも、状態ごとの必須情報が表示テキストとして
# 画面上に出ていることを検証する。
const ThemeFactory = preload("res://src/ui/ui_theme.gd")
const CookingScreen = preload("res://src/ui/cooking_screen.gd")
const LevelUpPanelScript = preload("res://src/ui/components/level_up_panel.gd")

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
	await _audit_meal_result()
	await _audit_level_up()
	await _audit_status_summary()

	if not _failures.is_empty():
		for failure in _failures:
			push_error(failure)
		get_tree().quit(1)
		return

	print("Cooking content audit passed for 5 states.")
	get_tree().quit(0)


func _audit_required_assets() -> void:
	var paths := [
		"res://assets/showcase/cooking/cooking_room_bg.png",
		"res://assets/showcase/cooking/meal_scene_bg.png",
		"res://assets/showcase/cooking/fish_icon_sheet.png",
		"res://assets/showcase/cooking/dish_icon_sheet.png",
		"res://assets/showcase/cooking/dish_feature_aji_shioyaki.png",
		"res://assets/showcase/cooking/recipe_grid_frame.png",
		"res://assets/showcase/cooking/recipe_card_frame.png",
		"res://assets/showcase/cooking/dish_detail_frame.png",
		"res://assets/showcase/cooking/meal_result_frame.png",
		"res://assets/showcase/cooking/level_up_frame.png",
		"res://assets/showcase/cooking/status_card_frame.png",
	]
	for path in paths:
		if not ResourceLoader.exists(path):
			_failures.append("ASSETS: missing or unimported required cooking asset '%s'." % path)


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
			"材料",
			"アジ ×1",
			"食経験値",
			"+40 EXP",
			"食事効果",
			"次の釣行で最大体力 +5%",
			"調理する",
			"現在の準備",
		]
	)
	screen.queue_free()
	await _tick()


func _audit_exp_gain() -> void:
	_seed_exp_gain_state()
	var screen := await _mount_cooking_screen()
	screen.preview_show_reward_result(_fake_non_level_result(), 80, 100, 150, false)
	await get_tree().create_timer(0.7).timeout
	await _expect_texts(
		"EXP_GAIN",
		screen,
		[
			"ごちそうさま！ 食経験値を獲得",
			"1 食事 完了",
			"2 EXP 加算中",
			"3 成長 進行中",
			"アジの塩焼きの食経験値がたまり",
			"アジの塩焼きを食べた！",
			"+20 EXP",
			"記録済み",
			"次の釣行で最大体力 +5%",
			"次のレベルまで 50 EXP",
		]
	)
	screen.queue_free()
	await _tick()


func _audit_meal_result() -> void:
	_seed_select_state()
	var screen := await _mount_cooking_screen()
	var result := _fake_level_result()
	_seed_after_meal_state()
	screen.preview_show_reward_result(result, 130, 150, 150, true)
	await get_tree().create_timer(0.7).timeout
	await _expect_texts(
		"MEAL_RESULT",
		screen,
		[
			"ごちそうさま！ 成長へつながった",
			"3 成長 解放",
			"アジの塩焼きの食経験値が Lv.5 到達",
			"初めて食べた料理！",
			"今回の合計 +40 EXP",
			"Lv.4 -> Lv.5 / ぬし解放",
			"解放を見る",
		]
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
			"LEVEL UP!",
			"Lv.4   ->   Lv.5",
			"食経験値が成長に変わった",
			"最大体力",
			"巻力",
			"港のぬしに挑戦できるようになった！",
			"食事でLv.5到達",
			"OK",
		]
	)
	panel.queue_free()
	await _tick()


func _audit_status_summary() -> void:
	_seed_after_meal_state()
	var screen := await _mount_cooking_screen()
	screen.preview_show_status_overlay()
	await get_tree().create_timer(0.4).timeout
	await _expect_texts(
		"STATUS_SUMMARY",
		screen,
		[
			"ステータス要約",
			"プレイヤー Lv.5",
			"効果中の料理",
			"アジの塩焼き",
			"次の釣行で最大体力 +5%",
			"クーラーボックス",
			"所持金",
			"プレイ時間",
			"閉じる",
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


func _trim(value: String) -> String:
	if value.length() > 420:
		return value.substr(0, 417) + "..."
	return value
