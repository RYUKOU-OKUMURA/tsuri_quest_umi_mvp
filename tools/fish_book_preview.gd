extends Control
## 魚図鑑画面のキャプチャツール（SubViewport オフスクリーン描画）。

const FishBookScreen = preload("res://src/ui/fish_book_screen.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")
const OUT := "/tmp/tsuri_fish_book.png"
const VW := Vector2i(1280, 720)


func _ready() -> void:
	var viewport := SubViewport.new()
	viewport.size = VW
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)

	_seed_progress()
	var screen := FishBookScreen.new()
	screen.theme = ThemeFactory.build_theme()
	screen.configure({})
	screen.size = Vector2(VW)
	viewport.add_child(screen)

	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.35).timeout

	var image := viewport.get_texture().get_image()
	if image == null or image.is_empty():
		push_error("Cannot capture fish book preview with the current display driver.")
		get_tree().quit(1)
		return
	image.save_png(OUT)
	print("fish_book_preview: wrote %s" % OUT)
	get_tree().quit(0)


func _seed_progress() -> void:
	PlayerProgress.level = 7
	PlayerProgress.money = 12840
	PlayerProgress.equipped_rod_id = "starter"
	PlayerProgress.caught_counts = {
		"aji": 12,
		"saba": 8,
		"kasago": 6,
		"mebaru": 7,
		"mejina": 5,
		"shirogisu": 9,
		"hirame": 2,
		"buri": 3,
		"madai": 4,
	}
	PlayerProgress.best_sizes = {
		"aji": 34.2,
		"saba": 38.6,
		"kasago": 26.4,
		"mebaru": 24.1,
		"mejina": 41.8,
		"shirogisu": 25.3,
		"hirame": 52.7,
		"buri": 78.6,
		"madai": 48.2,
	}
	PlayerProgress.spot_caught_counts = {
		"harbor_pier": {"aji": 12, "mebaru": 2, "shirogisu": 5},
		"shallow_sand": {"shirogisu": 4, "hirame": 2},
		"rock_breakwater": {"kasago": 6, "mebaru": 5},
		"outer_tide": {"saba": 8},
		"south_reef": {"madai": 4},
		"bluewater_route": {"buri": 3},
	}
