extends Control
## 船着き場画面の1280x720表示確認用キャプチャ。

const ThemeFactory = preload("res://src/ui/ui_theme.gd")
const ShipyardScreen = preload("res://src/ui/shipyard_screen.gd")

const DEFAULT_OUT := "/tmp/tsuri_shipyard_screen.png"
const VW := Vector2i(1280, 720)


func _ready() -> void:
	var options := _preview_options()
	var state := String(options["state"])
	var output := String(options["output"])
	theme = ThemeFactory.build_theme()
	_setup_preview_progress(state)
	var vp := SubViewport.new()
	vp.size = VW
	vp.disable_3d = true
	vp.transparent_bg = false
	vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)

	var screen := ShipyardScreen.new()
	screen.theme = ThemeFactory.build_theme()
	screen.configure({})
	screen.size = Vector2(VW)
	vp.add_child(screen)

	await _await_capture_ready(vp)
	match state:
		"available_focus":
			screen._select_boat("skiff")
			screen._buy_button.grab_focus()
		"insufficient":
			screen._select_boat("skiff")
			var insufficient_card := screen._boat_card_buttons.get("skiff") as Button
			insufficient_card.grab_focus()
		"purchased_focus_fallback":
			screen._select_boat("skiff")
			var selected := screen._boat_card_buttons.get("skiff") as Button
			selected.grab_focus()
		"all_owned":
			screen._select_boat("bluewater_boat")
			var all_owned_card := screen._boat_card_buttons.get("bluewater_boat") as Button
			all_owned_card.grab_focus()
		_:
			screen._select_boat("bluewater_boat")
	await _await_capture_ready(vp)

	if state == "available_focus" and vp.gui_get_focus_owner() != screen._buy_button:
		push_error("available preview should focus purchase")
		get_tree().quit(1)
		return
	if state == "purchased_focus_fallback":
		var selected := screen._boat_card_buttons.get("skiff") as Button
		if not screen._buy_button.disabled or vp.gui_get_focus_owner() != selected:
			push_error("purchased preview should disable purchase and focus selected card")
			get_tree().quit(1)
			return
	if state == "insufficient" and (
			not screen._buy_button.disabled
			or vp.gui_get_focus_owner() != screen._boat_card_buttons.get("skiff")
	):
		push_error("insufficient preview should focus selected card and disable purchase")
		get_tree().quit(1)
		return
	if state == "all_owned" and (
			not screen._buy_button.disabled
			or vp.gui_get_focus_owner() != screen._boat_card_buttons.get("bluewater_boat")
	):
		push_error("all-owned preview should focus the final selected boat")
		get_tree().quit(1)
		return

	if FileAccess.file_exists(output):
		DirAccess.remove_absolute(output)
	RenderingServer.force_draw()
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	if img == null or img.is_empty():
		push_error("SubViewport get_image() returned null for %s" % output)
		get_tree().quit(1)
		return
	else:
		var save_error := img.save_png(output)
		if save_error != OK:
			push_error("preview save failed (%s): %s" % [save_error, output])
			get_tree().quit(1)
			return
	print(output)
	get_tree().quit(0)


func _setup_preview_progress(state: String) -> void:
	PlayerProgress.level = 5
	PlayerProgress.exp = 42
	if state == "available_focus":
		PlayerProgress.money = 4000
		PlayerProgress.owned_boats = []
	elif state == "insufficient":
		PlayerProgress.money = 500
		PlayerProgress.owned_boats = []
	elif state == "purchased_focus_fallback":
		PlayerProgress.money = 400
		PlayerProgress.owned_boats = ["skiff"]
	elif state == "all_owned":
		PlayerProgress.money = 999999
		PlayerProgress.owned_boats = ["skiff", "offshore_boat", "bluewater_boat"]
	else:
		PlayerProgress.money = 400
		PlayerProgress.owned_boats = ["skiff"]
	PlayerProgress.equipped_rod_id = "starter"


func _preview_options() -> Dictionary:
	var options := {"state": "legacy", "output": DEFAULT_OUT}
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--state="):
			options["state"] = argument.trim_prefix("--state=")
		elif argument.begins_with("--output="):
			options["output"] = argument.trim_prefix("--output=")
	return options


func _await_capture_ready(vp: SubViewport) -> void:
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	for _i in range(5):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
