extends Control
## 調理フローの状態別キャプチャツール。
# PlayerProgress を一時的に捏造し、保存を伴う cook_and_eat() は呼ばない。
const ThemeFactory = preload("res://src/ui/ui_theme.gd")
const CookingScreen = preload("res://src/ui/cooking_screen.gd")
const LevelUpPanelScript = preload("res://src/ui/components/level_up_panel.gd")

const OUT_ALL := "/tmp/tsuri_cooking.png"
const OUT_SELECT := "/tmp/tsuri_cooking_select.png"
const OUT_RESULT := "/tmp/tsuri_cooking_result.png"
const OUT_EXP := "/tmp/tsuri_cooking_exp.png"
const OUT_LEVELUP := "/tmp/tsuri_cooking_levelup.png"
const OUT_STATUS := "/tmp/tsuri_cooking_status.png"
const VW := Vector2i(1280, 720)


func _ready() -> void:
	theme = ThemeFactory.build_theme()

	var vp := SubViewport.new()
	vp.size = VW
	vp.disable_3d = true
	vp.transparent_bg = false
	vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)

	_seed_select_state()
	var screen := await _mount_screen(vp)
	if not _save_viewport(vp, OUT_SELECT):
		get_tree().quit(1)
		return
	_save_viewport(vp, OUT_ALL)

	screen.queue_free()
	await get_tree().process_frame

	_seed_select_state()
	screen = await _mount_screen(vp)
	var old_stats := PlayerProgress.get_base_stats()
	var fake_result := _fake_meal_result()
	_seed_after_meal_state()
	screen.preview_show_meal_reward_result(fake_result, true)

	await get_tree().process_frame
	await get_tree().process_frame
	if not _save_viewport(vp, OUT_RESULT):
		get_tree().quit(1)
		return

	screen.queue_free()
	await get_tree().process_frame

	_seed_select_state()
	screen = await _mount_screen(vp)
	_seed_after_meal_state()
	screen.preview_show_reward_result(fake_result, 130, 150, 150, true)
	await get_tree().process_frame
	await get_tree().process_frame
	if not _save_viewport(vp, OUT_EXP):
		get_tree().quit(1)
		return

	var panel := LevelUpPanelScript.new()
	screen.add_child(panel)
	panel.show_level_up(4, 5, old_stats, PlayerProgress.get_base_stats())

	await get_tree().create_timer(0.7).timeout
	await get_tree().process_frame
	if not _save_viewport(vp, OUT_LEVELUP):
		get_tree().quit(1)
		return

	panel.queue_free()
	screen.preview_show_status_overlay()
	await get_tree().process_frame
	await get_tree().process_frame
	if not _save_viewport(vp, OUT_STATUS):
		get_tree().quit(1)
		return

	get_tree().quit()


func _mount_screen(vp: SubViewport) -> Control:
	var screen := CookingScreen.new()
	screen.theme = ThemeFactory.build_theme()
	screen.configure({"suppress_level_overlay": true})
	screen.size = Vector2(VW)
	vp.add_child(screen)
	await get_tree().process_frame
	await get_tree().process_frame
	return screen


func _seed_select_state() -> void:
	PlayerProgress.level = 4
	PlayerProgress.exp = 130
	PlayerProgress.money = 1250
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
	PlayerProgress.inventory["aji"] = 3
	PlayerProgress.pending_buff = {
		"recipe_id": "salt_grill",
		"name": "アジの塩焼き",
		"stat": "max_energy",
		"value": 0.05,
		"text": "次の釣行で最大体力 +5%",
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


func _save_viewport(vp: SubViewport, path: String) -> bool:
	if DisplayServer.get_name() == "headless":
		_push_headless_capture_error(path)
		return false
	var img := vp.get_texture().get_image()
	if img == null:
		push_error("SubViewport get_image() returned null for %s" % path)
		return false
	img.save_png(path)
	return true


func _push_headless_capture_error(path: String) -> void:
	push_error(
		(
			"Cannot capture %s with the headless/dummy display driver. "
			+ "Run this scene with a real display driver, for example without --headless, "
			+ "to generate cooking screenshots."
		)
		% path
	)
