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

const OPENING_BGM_PATH := "res://assets/audio/opening_bgm.mp3"
const OPENING_BGM_VOLUME_DB := -10.0
const OPENING_BGM_SCREEN_IDS := ["title", "harbor"]

var _current_screen
var _fade: ColorRect
var _bgm_player: AudioStreamPlayer


func _ready() -> void:
	theme = ThemeFactory.build_theme()
	# 画面遷移フェード（最前面）
	_fade = ColorRect.new()
	_fade.color = Color(0.0, 0.0, 0.0, 1.0)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)
	_show_screen("title")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		PlayerProgress.save_game()
		get_tree().quit()


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
		_start_opening_bgm()
	else:
		_stop_opening_bgm()


func _start_opening_bgm() -> void:
	if _bgm_player != null and is_instance_valid(_bgm_player):
		if not _bgm_player.playing:
			_bgm_player.play()
		return
	if not ResourceLoader.exists(OPENING_BGM_PATH) and not FileAccess.file_exists(OPENING_BGM_PATH):
		push_warning("オープニングBGMが見つかりません: %s" % OPENING_BGM_PATH)
		return
	var stream := load(OPENING_BGM_PATH) as AudioStream
	if stream == null:
		push_warning("オープニングBGMを読み込めません: %s" % OPENING_BGM_PATH)
		return
	var mp3_stream := stream as AudioStreamMP3
	if mp3_stream != null:
		mp3_stream.loop = true
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.name = "OpeningBGMPlayer"
	_bgm_player.stream = stream
	_bgm_player.volume_db = OPENING_BGM_VOLUME_DB
	_bgm_player.finished.connect(_on_opening_bgm_finished)
	add_child(_bgm_player)
	_bgm_player.play()


func _stop_opening_bgm() -> void:
	if _bgm_player == null or not is_instance_valid(_bgm_player):
		_bgm_player = null
		return
	_bgm_player.stop()


func _on_opening_bgm_finished() -> void:
	if _bgm_player != null and is_instance_valid(_bgm_player) and is_inside_tree():
		_bgm_player.play()
