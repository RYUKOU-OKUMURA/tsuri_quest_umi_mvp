extends Control
## タイトル画面の通常状態 / セーブ領域利用不可状態を1280x720で実描画する。

const TitleScreen = preload("res://src/ui/title_screen.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")

const NORMAL_OUT := "/tmp/tsuri_title_normal.png"
const STORAGE_BLOCKED_OUT := "/tmp/tsuri_title_storage_blocked.png"


func _ready() -> void:
	theme = ThemeFactory.build_theme()
	var mode := OS.get_environment("TSURI_TITLE_PREVIEW_MODE")
	if mode == "storage_blocked":
		PlayerProgress._save_storage_ready = false
		PlayerProgress._save_storage_block_message = (
			"旧版セーブの移行を完了できなかったため、セーブの読み書きを停止しました。"
			+ "ゲームを再起動してください。"
		)
	else:
		PlayerProgress._save_storage_ready = true
		PlayerProgress._save_storage_block_message = ""
		PlayerProgress.active_save_slot = PlayerProgress.DEFAULT_SAVE_SLOT

	var screen := TitleScreen.new()
	screen.configure({})
	add_child(screen)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw

	var image := get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		push_error("タイトル画面の実スクショを取得できませんでした。")
		get_tree().quit(1)
		return
	var out := OS.get_environment("TSURI_TITLE_PREVIEW_OUT").strip_edges()
	if out.is_empty():
		out = STORAGE_BLOCKED_OUT if mode == "storage_blocked" else NORMAL_OUT
	var save_error := image.save_png(out)
	if save_error != OK:
		push_error("タイトル画面の実スクショを保存できませんでした（code %d）。" % save_error)
		get_tree().quit(1)
		return
	print("title_preview: wrote %s" % out)
	get_tree().quit(0)
