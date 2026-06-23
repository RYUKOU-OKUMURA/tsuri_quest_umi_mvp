extends Control

const ThemeFactory = preload("res://src/ui/ui_theme.gd")
const TitleScreen = preload("res://src/ui/title_screen.gd")
const HarborScreen = preload("res://src/ui/harbor_screen.gd")
const FishingScreen = preload("res://src/ui/fishing_screen.gd")
const CookingScreen = preload("res://src/ui/cooking_screen.gd")
const MarketScreen = preload("res://src/ui/market_screen.gd")
const ShopScreen = preload("res://src/ui/shop_screen.gd")
const StatusScreen = preload("res://src/ui/status_screen.gd")

var _current_screen
var _fade: ColorRect


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
	match screen_id:
		"title":
			screen_script = TitleScreen
		"harbor":
			screen_script = HarborScreen
		"fishing":
			screen_script = FishingScreen
		"cooking":
			screen_script = CookingScreen
		"market":
			screen_script = MarketScreen
		"shop":
			screen_script = ShopScreen
		"status":
			screen_script = StatusScreen
		_:
			push_warning("未知の画面IDです: %s" % screen_id)
			screen_script = HarborScreen

	if _current_screen != null:
		remove_child(_current_screen)
		_current_screen.queue_free()

	_current_screen = screen_script.new()
	_current_screen.configure(payload)
	_current_screen.navigate_requested.connect(_on_navigate_requested)
	add_child(_current_screen)


func _on_navigate_requested(screen_id: String, payload: Dictionary) -> void:
	_show_screen(screen_id, payload)
