extends Control
## 魚市場画面の1280x720表示確認用キャプチャ。

const MarketScreen = preload("res://src/ui/market_screen.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")

const VW := Vector2i(1280, 720)
const OUT_SELECT := "/tmp/tsuri_market_select.png"
const OUT_CONFIRM := "/tmp/tsuri_market_confirm.png"
const OUT_SOLD := "/tmp/tsuri_market_sold.png"
const OUT_EMPTY := "/tmp/tsuri_market_empty.png"
const OUT_CTA_NORMAL := "/tmp/tsuri_market_cta_normal.png"
const OUT_CTA_HOVER := "/tmp/tsuri_market_cta_hover.png"
const OUT_CTA_PRESSED := "/tmp/tsuri_market_cta_pressed.png"
const OUT_CTA_FOCUS := "/tmp/tsuri_market_cta_focus.png"
const OUT_CTA_DISABLED := "/tmp/tsuri_market_cta_disabled.png"

var _had_capture_error := false


func _ready() -> void:
	_seed_progress()
	await _capture_select()
	_seed_progress()
	await _capture_confirm()
	_seed_progress()
	await _capture_sold()
	_seed_empty()
	await _capture_plain(OUT_EMPTY)
	for state_and_path in [
		["normal", OUT_CTA_NORMAL],
		["hover", OUT_CTA_HOVER],
		["pressed", OUT_CTA_PRESSED],
		["focus", OUT_CTA_FOCUS],
		["disabled", OUT_CTA_DISABLED],
	]:
		_seed_progress()
		await _capture_cta_input_state(state_and_path[0], state_and_path[1])

	print("market_preview:")
	print(OUT_SELECT)
	print(OUT_CONFIRM)
	print(OUT_SOLD)
	print(OUT_EMPTY)
	print(OUT_CTA_NORMAL)
	print(OUT_CTA_HOVER)
	print(OUT_CTA_PRESSED)
	print(OUT_CTA_FOCUS)
	print(OUT_CTA_DISABLED)
	get_tree().quit(1 if _had_capture_error else 0)


func _seed_progress() -> void:
	PlayerProgress.level = 5
	PlayerProgress.exp = 42
	PlayerProgress.money = 3680
	PlayerProgress.owned_rods = ["starter", "iso", "offshore"]
	PlayerProgress.equipped_rod_id = "offshore"
	PlayerProgress.owned_rigs = [GameData.DEFAULT_RIG_ID, "uki", "chokusen"]
	PlayerProgress.equipped_rig_id = "chokusen"
	PlayerProgress.owned_boats = ["skiff"]
	PlayerProgress.inventory = {
		"aji": 8,
		"madai": 2,
		"saba": 5,
		"kasago": 3,
		"hirame": 1,
		"mejina": 4,
		"iwashi": 12,
		"kawahagi": 2,
		"kobudai": 1,
	}
	PlayerProgress.caught_counts = {
		"aji": 18,
		"madai": 4,
		"saba": 8,
		"kasago": 5,
		"hirame": 2,
		"mejina": 6,
		"iwashi": 16,
		"kawahagi": 3,
		"kobudai": 1,
	}
	PlayerProgress.best_sizes = {}
	PlayerProgress.spot_caught_counts = {}
	PlayerProgress.pending_buff = {}


func _seed_empty() -> void:
	PlayerProgress.level = 3
	PlayerProgress.exp = 18
	PlayerProgress.money = 1540
	PlayerProgress.owned_rods = ["starter", "iso"]
	PlayerProgress.equipped_rod_id = "iso"
	PlayerProgress.owned_rigs = [GameData.DEFAULT_RIG_ID]
	PlayerProgress.equipped_rig_id = GameData.DEFAULT_RIG_ID
	PlayerProgress.owned_boats = []
	PlayerProgress.inventory = {}
	PlayerProgress.caught_counts = {"aji": 3, "saba": 1}
	PlayerProgress.best_sizes = {}
	PlayerProgress.spot_caught_counts = {}
	PlayerProgress.pending_buff = {}


func _capture_select() -> void:
	var screen: Control = await _make_screen(VW)
	screen._set_quantity("aji", 3)
	screen._set_quantity("madai", 1)
	screen._select_visible_row(1)
	await _capture_screen(screen, OUT_SELECT)


func _capture_confirm() -> void:
	var screen: Control = await _make_screen(VW)
	screen._set_quantity("hirame", 1)
	screen._show_confirm_overlay()
	await _capture_screen(screen, OUT_CONFIRM)


func _capture_sold() -> void:
	var screen: Control = await _make_screen(VW)
	screen._set_quantity("aji", 2)
	screen._set_quantity("hirame", 1)
	screen._confirm_sell()
	await _capture_screen(screen, OUT_SOLD)


func _capture_plain(out_path: String) -> void:
	var screen: Control = await _make_screen(VW)
	await _capture_screen(screen, out_path)


func _capture_cta_input_state(state_name: String, out_path: String) -> void:
	var screen: Control = await _make_screen(VW)
	screen._set_quantity("aji", 3)
	screen._set_quantity("madai", 1)
	var button := screen._cart_action_button as Button
	var viewport := screen.get_viewport()
	var button_center := button.get_global_rect().get_center()
	await _move_pointer(viewport, Vector2(8.0, 8.0))
	button.release_focus()
	match state_name:
		"normal":
			pass
		"hover":
			await _move_pointer(viewport, button_center)
			_expect_capture_state(button.is_hovered(), "hover input should set the real hovered state")
		"pressed":
			var press_events := {"down": 0}
			button.button_down.connect(func() -> void: press_events["down"] += 1)
			await _move_pointer(viewport, button_center)
			await _push_mouse_button(viewport, button_center, true)
			_expect_capture_state(int(press_events["down"]) == 1, "button-down input should emit the real pressed transition")
		"focus":
			button.grab_focus()
			await get_tree().process_frame
			_expect_capture_state(button.has_focus(), "grab_focus should set the real focus state")
		"disabled":
			button.disabled = true
			await get_tree().process_frame
			_expect_capture_state(button.disabled, "disabled capture should use the real disabled property")
	await _capture_screen(screen, out_path)


func _move_pointer(viewport: Viewport, position: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = position
	event.global_position = position
	viewport.push_input(event, true)
	await get_tree().process_frame
	await get_tree().process_frame


func _push_mouse_button(viewport: Viewport, position: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	event.position = position
	event.global_position = position
	viewport.push_input(event, true)
	await get_tree().process_frame
	await get_tree().process_frame


func _expect_capture_state(condition: bool, message: String) -> void:
	if condition:
		return
	_had_capture_error = true
	push_error(message)


func _make_screen(viewport_size: Vector2i) -> Control:
	var vp := SubViewport.new()
	vp.disable_3d = true
	vp.transparent_bg = false
	vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.size = viewport_size
	add_child(vp)
	await get_tree().process_frame
	await get_tree().process_frame

	var screen := MarketScreen.new()
	screen.theme = ThemeFactory.build_theme()
	screen.configure({})
	screen.size = Vector2(viewport_size)
	vp.add_child(screen)

	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	return screen


func _capture_screen(screen: Control, out_path: String) -> void:
	await get_tree().create_timer(0.5).timeout
	RenderingServer.force_draw()
	await get_tree().process_frame

	var vp := screen.get_parent() as SubViewport
	if FileAccess.file_exists(out_path):
		DirAccess.remove_absolute(out_path)
	var img := vp.get_texture().get_image()
	if img == null or img.is_empty():
		_had_capture_error = true
		push_error("SubViewport get_image() returned null for %s" % out_path)
	else:
		img.save_png(out_path)
	vp.queue_free()
	await get_tree().process_frame
