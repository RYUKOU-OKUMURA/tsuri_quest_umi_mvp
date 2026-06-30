extends Control
## 水上キャスト画面の READY〜BITE 状態を連続キャプチャする確認ツール。

const ThemeFactory = preload("res://src/ui/ui_theme.gd")
const FishingScreen = preload("res://src/ui/fishing_screen.gd")

const VW := Vector2i(1280, 720)
const OUT_READY := "/tmp/tsuri_fishing_surface_ready.png"
const OUT_CASTING := "/tmp/tsuri_fishing_surface_casting.png"
const OUT_WAITING := "/tmp/tsuri_fishing_surface_waiting.png"
const OUT_APPROACH := "/tmp/tsuri_fishing_surface_approach.png"
const OUT_BITE := "/tmp/tsuri_fishing_surface_bite.png"


func _ready() -> void:
	PlayerProgress.money = 12450

	var vp := SubViewport.new()
	vp.size = VW
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)

	var screen := FishingScreen.new()
	screen.theme = ThemeFactory.build_theme()
	screen.configure({})
	screen.size = Vector2(VW)
	vp.add_child(screen)

	await _settle()
	_save(vp, OUT_READY)

	screen._simulator.cast()
	await get_tree().create_timer(0.16).timeout
	await _settle()
	_save(vp, OUT_CASTING)

	await _wait_until(screen, FishingSimulator.State.WAITING, 1.4)
	await get_tree().create_timer(0.26).timeout
	await _settle()
	_save(vp, OUT_WAITING)

	await _wait_until(screen, FishingSimulator.State.APPROACH, 3.4)
	await get_tree().create_timer(0.38).timeout
	await _settle()
	_save(vp, OUT_APPROACH)

	await _wait_until(screen, FishingSimulator.State.BITE, 2.4)
	await get_tree().create_timer(0.10).timeout
	await _settle()
	_save(vp, OUT_BITE)

	print("fishing_surface_states_preview:")
	print(OUT_READY)
	print(OUT_CASTING)
	print(OUT_WAITING)
	print(OUT_APPROACH)
	print(OUT_BITE)
	get_tree().quit()


func _wait_until(screen: Node, target_state: int, timeout: float) -> void:
	var elapsed := 0.0
	while elapsed < timeout:
		if screen._simulator.state == target_state:
			return
		await get_tree().create_timer(0.05).timeout
		elapsed += 0.05
	push_error("Timed out waiting for fishing state %d, current=%d" % [target_state, screen._simulator.state])


func _settle() -> void:
	await get_tree().process_frame
	await get_tree().process_frame


func _save(vp: SubViewport, out_path: String) -> void:
	if FileAccess.file_exists(out_path):
		DirAccess.remove_absolute(out_path)
	var img := vp.get_texture().get_image()
	if img == null:
		push_error("SubViewport get_image() returned null for %s" % out_path)
		return
	img.save_png(out_path)
