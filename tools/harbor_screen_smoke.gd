extends Node

const HarborScreenScript = preload("res://src/ui/harbor_screen.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")

var _navigated_to := ""
var _payload: Dictionary = {}
var _failed := false


func _ready() -> void:
	await _verify_locked_shark_pen_and_lure()
	await _verify_lure_payload()
	await _verify_shark_pen_navigation()
	await _verify_megalodon_omen()

	if _failed:
		return
	print("harbor_screen_smoke: ok")
	get_tree().quit(0)


func _verify_locked_shark_pen_and_lure() -> void:
	_navigated_to = ""
	_payload = {}
	PlayerProgress.level = 29
	PlayerProgress.owned_boats = ["bluewater_boat"]
	PlayerProgress.sea_chart_fragments = 3
	PlayerProgress.inventory = {"kihada": 1}
	PlayerProgress.caught_counts = {"nekozame": 1}
	var screen := _make_screen()
	await get_tree().process_frame
	_expect(not screen._can_open_shark_pen(), "shark pen should stay locked below Lv.30")
	_expect(screen._shark_lure_button.disabled, "shark lure button should stay locked before danger reef access")
	screen._open_shark_pen()
	_expect(_navigated_to.is_empty(), "locked shark pen should not navigate")
	_expect(screen._facility_detail_body_label.text.contains("Lv.30"), "locked shark pen action should show lock detail")
	screen.queue_free()
	await get_tree().process_frame

	PlayerProgress.level = 30
	PlayerProgress.caught_counts = {}
	screen = _make_screen()
	await get_tree().process_frame
	_expect(not screen._can_open_shark_pen(), "shark pen should stay locked when no shark has been caught")
	screen._open_shark_pen()
	_expect(_navigated_to.is_empty(), "no-shark locked shark pen should not navigate")
	_expect(screen._facility_detail_body_label.text.contains("危険海域"), "no-shark locked shark pen should show lock detail")
	screen.queue_free()
	await get_tree().process_frame


func _verify_lure_payload() -> void:
	_navigated_to = ""
	_payload = {}
	PlayerProgress.level = 30
	PlayerProgress.owned_boats = ["bluewater_boat"]
	PlayerProgress.sea_chart_fragments = 3
	PlayerProgress.inventory = {"kihada": 2, "nekozame": 1}
	PlayerProgress.caught_counts = {}
	var screen := _make_screen()
	await get_tree().process_frame
	var lure_name := String(GameData.get_fish("kihada").get("name", "kihada"))
	_expect(not screen._shark_lure_button.disabled, "shark lure button should unlock with danger reef access and food fish")
	screen._cycle_shark_lure_fish()
	_expect(screen._shark_lure_button.text.contains(lure_name), "shark lure button should show selected fish")
	var payload: Dictionary = screen._fishing_spots_payload()
	_expect(String(payload.get("shark_lure_fish_id", "")) == "kihada", "harbor should pass selected shark lure fish to fishing spots")
	_expect(String(payload.get("shark_lure_fish_id", "")) != "nekozame", "harbor should not pass shark as lure fish")
	screen.queue_free()
	await get_tree().process_frame


func _verify_shark_pen_navigation() -> void:
	_navigated_to = ""
	_payload = {}
	PlayerProgress.level = 30
	PlayerProgress.owned_boats = ["bluewater_boat"]
	PlayerProgress.sea_chart_fragments = 3
	PlayerProgress.inventory = {"kihada": 1}
	PlayerProgress.caught_counts = {"nekozame": 1}
	var screen := _make_screen()
	await get_tree().process_frame
	_expect(screen._can_open_shark_pen(), "shark pen should unlock after Lv.30 and a caught shark")
	screen._open_shark_pen()
	_expect(_navigated_to == "shark_pen", "unlocked shark pen should navigate")
	screen.queue_free()
	await get_tree().process_frame


func _verify_megalodon_omen() -> void:
	PlayerProgress.level = GameData.MAX_LEVEL
	PlayerProgress.owned_boats = ["bluewater_boat"]
	PlayerProgress.sea_chart_fragments = 3
	PlayerProgress.inventory = {"nushi_deep_ocean": 1}
	PlayerProgress.caught_counts = {"nekozame": 1}
	PlayerProgress.shark_bonds = {}
	for shark_id in GameData.get_normal_shark_ids():
		PlayerProgress.shark_bonds[shark_id] = 100
	var screen := _make_screen()
	await get_tree().process_frame
	_expect(screen._preparation_body_label.text.contains("深海の何か"), "harbor should show megalodon omen when unlocked and uncaught")
	screen.queue_free()
	await get_tree().process_frame


func _make_screen(payload: Dictionary = {}) -> Control:
	var screen := HarborScreenScript.new()
	screen.theme = ThemeFactory.build_theme()
	screen.configure(payload)
	screen.size = Vector2(1280.0, 720.0)
	screen.navigate_requested.connect(
		func(screen_id: String, payload: Dictionary) -> void:
			_navigated_to = screen_id
			_payload = payload.duplicate(true)
	)
	add_child(screen)
	return screen


func _expect(condition: bool, message: String) -> void:
	if condition or _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
