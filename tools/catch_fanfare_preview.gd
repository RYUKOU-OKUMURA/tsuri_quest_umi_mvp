extends Control
## 釣り上げファンファーレのQA用キャプチャツール。

const FishingScreenScript = preload("res://src/ui/fishing_screen.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")
const DEFAULT_OUT := "/tmp/tsuri_catch_fanfare.png"
const VW := Vector2i(1280, 720)


func _ready() -> void:
	var out := OS.get_environment("TSURI_CATCH_FANFARE_OUT")
	if out.is_empty():
		out = DEFAULT_OUT
	if FileAccess.file_exists(out):
		var remove_error := DirAccess.remove_absolute(out)
		if remove_error != OK:
			push_warning("Failed to remove stale catch fanfare capture: %s" % out)

	PlayerProgress.level = max(PlayerProgress.level, GameData.BOSS_UNLOCK_LEVEL)
	PlayerProgress.money = 12450
	var scenario := OS.get_environment("TSURI_CATCH_FANFARE_SCENARIO")
	var fish_id := OS.get_environment("TSURI_CATCH_FANFARE_FISH_ID")
	if fish_id.is_empty():
		if scenario == "favorite_bait":
			fish_id = "hoshizame"
		else:
			fish_id = "aji" if scenario in ["first", "record", "title"] else "boss_kurodai"
	var spot_id := "danger_reef" if scenario == "favorite_bait" else GameData.BOSS_FISHING_SPOT_ID if fish_id == "boss_kurodai" else GameData.DEFAULT_FISHING_SPOT_ID

	var vp := SubViewport.new()
	vp.size = VW
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)

	var screen := FishingScreenScript.new()
	screen.theme = ThemeFactory.build_theme()
	screen.configure({"spot_id": spot_id})
	screen.size = Vector2(VW)
	vp.add_child(screen)
	await get_tree().process_frame
	await get_tree().process_frame

	var fish := GameData.get_fish(fish_id).duplicate(true)
	screen._current_fish = fish
	screen._simulator.prepare(fish, screen._trip_stats)
	screen._view.bind_simulator(screen._simulator)
	screen._surface_view.bind_simulator(screen._simulator)
	screen._fight_sidebar.bind(screen._simulator, fish, screen._trip_stats)
	screen._fight_hud.bind(screen._simulator, fish, screen._trip_stats)
	screen._view.modulate.a = 1.0
	screen._surface_view.modulate.a = 0.0
	var size_cm := 92.0 if scenario == "favorite_bait" else 48.2 if fish_id == "boss_kurodai" else 23.4
	if scenario in ["record", "title"]:
		size_cm = 24.5
	var size_env := OS.get_environment("TSURI_CATCH_FANFARE_SIZE_CM")
	if not size_env.is_empty():
		size_cm = size_env.to_float()
	var catch_result := _catch_result_for_scenario(scenario, fish_id, size_cm)
	screen._catch_fanfare.play(fish, size_cm, catch_result)

	await get_tree().create_timer(1.15).timeout
	var img := vp.get_texture().get_image()
	if img == null:
		push_error("SubViewport get_image() returned null; run with a real display driver.")
		get_tree().quit(1)
		return
	img.save_png(out)
	get_tree().quit(0)


func _catch_result_for_scenario(scenario: String, fish_id: String, _size_cm: float) -> Dictionary:
	match scenario:
		"first":
			return {
				"fish_id": fish_id,
				"first_catch": true,
				"boss_first_clear_reward": {},
				"record_broken": false,
				"previous_best_cm": 0.0,
				"new_titles": [],
			}
		"record":
			return {
				"fish_id": fish_id,
				"first_catch": false,
				"boss_first_clear_reward": {},
				"record_broken": true,
				"previous_best_cm": 20.0,
				"new_titles": [],
			}
		"title":
			return {
				"fish_id": fish_id,
				"first_catch": false,
				"boss_first_clear_reward": {},
				"record_broken": true,
				"previous_best_cm": 20.0,
				"new_titles": ["total_10", "species_10"],
			}
		"favorite_bait":
			return {
				"fish_id": fish_id,
				"first_catch": true,
				"sent_to_shark_pen": true,
				"boss_first_clear_reward": {},
				"record_broken": false,
				"previous_best_cm": 0.0,
				"favorite_bait_discovery_text": "ホシザメはアジが大好物みたいだ！",
				"new_titles": [],
			}
		_:
			var catch_result := {"first_catch": true}
			if fish_id == "boss_kurodai":
				catch_result["boss_first_clear_reward"] = {"money": 3000}
			return catch_result
