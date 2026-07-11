extends Control

const ThemeFactory = preload("res://src/ui/ui_theme.gd")
const TitleScreen = preload("res://src/ui/title_screen.gd")
const HarborScreen = preload("res://src/ui/harbor_screen.gd")
const FishingSpotSelectScreen = preload("res://src/ui/fishing_spot_select_screen.gd")
const FishingScreen = preload("res://src/ui/fishing_screen.gd")
const CookingScreen = preload("res://src/ui/cooking_screen.gd")
const MarketScreen = preload("res://src/ui/market_screen.gd")
const ShopScreen = preload("res://src/ui/shop_screen.gd")
const ShipyardScreen = preload("res://src/ui/shipyard_screen.gd")
const StatusScreen = preload("res://src/ui/status_screen.gd")
const FishBookScreen = preload("res://src/ui/fish_book_screen.gd")
const QuestBoardScreen = preload("res://src/ui/quest_board_screen.gd")
const SharkPenScreen = preload("res://src/ui/shark_pen_screen.gd")
const SettingsScreen = preload("res://src/ui/settings_screen.gd")

const OPENING_BGM_PATH := "res://assets/audio/opening_bgm.mp3"
const OPENING_BGM_VOLUME_DB := -10.0
const OPENING_BGM_SCREEN_IDS := ["title", "harbor", "settings"]

var _current_screen
var _fade: ColorRect
var _app_bgm_player: AudioStreamPlayer
var _app_bgm_path := ""
var _save_exit_dialog: ConfirmationDialog


func _ready() -> void:
	theme = ThemeFactory.build_theme()
	SettingsScreen.apply_to_audio_buses(SettingsScreen.load_settings())
	# close requestを保存結果に応じて制御するため、SceneTreeの自動終了を無効化する。
	get_tree().auto_accept_quit = false
	PlayerProgress.save_failed.connect(_on_save_failed)
	# 画面遷移フェード（最前面）
	_fade = ColorRect.new()
	_fade.color = Color(0.0, 0.0, 0.0, 1.0)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)
	_show_screen("title")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if _should_save_on_close():
			if not PlayerProgress.save_game():
				_show_save_exit_dialog()
				return
		get_tree().quit()


func _should_save_on_close() -> bool:
	return _current_screen == null or _current_screen.get_script() != TitleScreen


func _on_save_failed(message: String) -> void:
	if _current_screen != null and _current_screen.has_method("show_common_notification"):
		_current_screen.call("show_common_notification", message)


func _show_save_exit_dialog() -> void:
	if _save_exit_dialog == null:
		_save_exit_dialog = ConfirmationDialog.new()
		_save_exit_dialog.title = "保存できませんでした"
		_save_exit_dialog.dialog_text = "進行を保存できませんでした。再試行しますか？"
		_save_exit_dialog.ok_button_text = "再試行"
		_save_exit_dialog.cancel_button_text = "戻る"
		_save_exit_dialog.confirmed.connect(_retry_save_and_quit)
		var quit_without_save := _save_exit_dialog.add_button("保存せず終了", false, "quit_without_save")
		quit_without_save.pressed.connect(func() -> void: get_tree().quit())
		add_child(_save_exit_dialog)
	_save_exit_dialog.popup_centered(Vector2i(520, 220))


func _retry_save_and_quit() -> void:
	if PlayerProgress.save_game():
		get_tree().quit()
	else:
		_show_save_exit_dialog()


func _show_screen(screen_id: String, payload: Dictionary = {}) -> void:
	# フェードアウト → 差し替え → フェードイン
	var tw := create_tween()
	tw.tween_property(_fade, "color", Color(0.0, 0.0, 0.0, 1.0), 0.12)
	tw.tween_callback(_swap.bind(screen_id, payload))
	tw.tween_interval(0.03)
	tw.tween_property(_fade, "color", Color(0.0, 0.0, 0.0, 0.0), 0.15)


func _swap(screen_id: String, payload: Dictionary) -> void:
	var screen_script: Script
	var resolved_screen_id := screen_id
	match screen_id:
		"title":
			screen_script = TitleScreen
		"harbor":
			screen_script = HarborScreen
		"fishing_spots":
			screen_script = FishingSpotSelectScreen
		"fishing":
			screen_script = FishingScreen
		"cooking":
			screen_script = CookingScreen
		"market":
			screen_script = MarketScreen
		"shop":
			screen_script = ShopScreen
		"shipyard":
			screen_script = ShipyardScreen
		"status":
			screen_script = StatusScreen
		"fish_book":
			screen_script = FishBookScreen
		"quest_board":
			screen_script = QuestBoardScreen
		"shark_pen":
			screen_script = SharkPenScreen
		"settings":
			screen_script = SettingsScreen
		_:
			push_warning("未知の画面IDです: %s" % screen_id)
			screen_script = HarborScreen
			resolved_screen_id = "harbor"

	if _current_screen != null:
		remove_child(_current_screen)
		_current_screen.queue_free()

	_current_screen = screen_script.new()
	_current_screen.configure(payload)
	_current_screen.navigate_requested.connect(_on_navigate_requested)
	add_child(_current_screen)
	_update_bgm_for_screen(resolved_screen_id)


func _on_navigate_requested(screen_id: String, payload: Dictionary) -> void:
	_show_screen(screen_id, payload)


func _update_bgm_for_screen(screen_id: String) -> void:
	if OPENING_BGM_SCREEN_IDS.has(screen_id):
		play_app_bgm(OPENING_BGM_PATH, OPENING_BGM_VOLUME_DB)
	else:
		_stop_opening_bgm()


func play_app_bgm(path: String, volume_db: float = -10.0) -> void:
	if path.strip_edges().is_empty():
		stop_app_bgm()
		return
	if (
		_app_bgm_player != null
		and is_instance_valid(_app_bgm_player)
		and _app_bgm_path == path
	):
		if not _app_bgm_player.playing:
			_app_bgm_player.play()
		return
	stop_app_bgm()
	if not ResourceLoader.exists(path) and not FileAccess.file_exists(path):
		push_warning("BGMが見つかりません: %s" % path)
		return
	var stream := load(path) as AudioStream
	if stream == null:
		push_warning("BGMを読み込めません: %s" % path)
		return
	var mp3_stream := stream as AudioStreamMP3
	if mp3_stream != null:
		mp3_stream.loop = true
	_app_bgm_player = AudioStreamPlayer.new()
	_app_bgm_player.name = "AppBGMPlayer"
	_app_bgm_player.stream = stream
	_app_bgm_player.bus = &"BGM"
	_app_bgm_player.volume_db = volume_db
	_app_bgm_player.finished.connect(_on_app_bgm_finished)
	add_child(_app_bgm_player)
	_app_bgm_path = path
	_app_bgm_player.play()


func stop_app_bgm(path: String = "") -> void:
	if _app_bgm_player == null or not is_instance_valid(_app_bgm_player):
		_app_bgm_player = null
		_app_bgm_path = ""
		return
	if not path.strip_edges().is_empty() and _app_bgm_path != path:
		return
	var player := _app_bgm_player
	_app_bgm_player = null
	_app_bgm_path = ""
	player.stop()
	player.queue_free()


func _stop_opening_bgm() -> void:
	stop_app_bgm(OPENING_BGM_PATH)


func _on_app_bgm_finished() -> void:
	if _app_bgm_player != null and is_instance_valid(_app_bgm_player) and is_inside_tree():
		_app_bgm_player.play()
