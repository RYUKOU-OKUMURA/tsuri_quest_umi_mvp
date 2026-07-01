extends Node

const ShipyardScreenScript = preload("res://src/ui/shipyard_screen.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")

var _screen: Variant
var _navigated_to := ""
var _payload: Dictionary = {}
var _failed := false


func _ready() -> void:
	_seed_progress()
	_screen = _make_screen()
	await get_tree().process_frame

	_expect(_screen._background_rect.texture != null, "shipyard background should load")
	_expect(_screen._boat_card_labels.size() == 3, "shipyard should render three boat cards")
	_expect(_screen._boat_card_price_labels.size() == 3, "shipyard should render boat price badges")
	_expect(_screen._boat_card_range_labels.size() == 3, "shipyard should render boat range labels")
	_expect(_screen._selected_boat_id == "skiff", "first unowned boat should be selected")
	_expect(_screen._buy_button.disabled, "initial 500G should not allow skiff purchase")
	_expect(_screen._boat_card_price_labels.get("skiff").text == "3,600 G", "skiff card should show readable price")
	_expect(_screen._detail_status_label.text == "資金不足", "detail should show purchase state")
	_expect(_screen._shortage_label.text.contains("あと"), "detail should show shortage amount")
	_expect(_screen._route_after_label.text == "購入後 1/3", "route legend should show selected purchase result")
	_expect(_screen._footer_label.text.contains("あと"), "initial footer should explain missing money")

	PlayerProgress.money = 4000
	_screen._refresh()
	_expect(not _screen._buy_button.disabled, "skiff should become purchasable with enough money")
	_expect(_screen._detail_status_label.text == "購入可能", "detail state should update when money is enough")
	_expect(_screen._shortage_label.text.is_empty(), "shortage amount should hide when purchasable")
	_screen._buy_selected_boat()
	_expect(PlayerProgress.has_boat("skiff"), "buying skiff should add owned boat")
	_expect(PlayerProgress.money == 400, "buying skiff should subtract price")
	_expect(_screen._buy_button.disabled, "owned skiff purchase button should be disabled")
	_expect(_screen._boat_card_price_labels.get("skiff").text == "所持", "owned boat card should show ownership")
	_expect(PlayerProgress.can_access_fishing_spot("south_reef"), "skiff should unlock south reef at Lv.5")

	var money_after_skiff := PlayerProgress.money
	_screen._buy_selected_boat()
	_expect(PlayerProgress.money == money_after_skiff, "repurchasing owned skiff should not change money")
	_expect(PlayerProgress.owned_boats.count("skiff") == 1, "repurchasing owned skiff should not duplicate ownership")

	_screen._select_boat("offshore_boat")
	_expect(_screen._buy_button.disabled, "offshore boat should be unaffordable after skiff purchase")
	_screen._buy_selected_boat()
	_expect(not PlayerProgress.has_boat("offshore_boat"), "unaffordable offshore boat should not be purchased")

	PlayerProgress.level = 6
	PlayerProgress.owned_boats = ["skiff"]
	_expect(not PlayerProgress.can_access_fishing_spot("bluewater_route"), "skiff should not unlock bluewater route")
	PlayerProgress.owned_boats = ["offshore_boat"]
	_expect(PlayerProgress.can_access_fishing_spot("bluewater_route"), "offshore boat should unlock bluewater route")
	PlayerProgress.level = 9
	_expect(not PlayerProgress.can_access_fishing_spot("deep_ocean"), "offshore boat should not unlock deep ocean")
	PlayerProgress.owned_boats = ["bluewater_boat"]
	_expect(PlayerProgress.can_access_fishing_spot("deep_ocean"), "bluewater boat should unlock deep ocean")
	PlayerProgress.level = 5
	PlayerProgress.owned_boats = []
	_expect(PlayerProgress.can_access_fishing_spot("harbor_boulder"), "boss boulder should not require a boat")

	var return_button := _find_meta_button(_screen, "shipyard_return")
	_expect(return_button != null, "shipyard return button should exist")
	if return_button != null:
		return_button.pressed.emit()
	_expect(_navigated_to == "harbor", "shipyard return should navigate to harbor")

	if _failed:
		return
	print("shipyard_smoke: ok")
	get_tree().quit(0)


func _seed_progress() -> void:
	PlayerProgress.level = 5
	PlayerProgress.exp = 0
	PlayerProgress.money = 500
	PlayerProgress.owned_boats = []
	PlayerProgress.equipped_rod_id = "starter"


func _make_screen(payload: Dictionary = {}) -> Control:
	var screen := ShipyardScreenScript.new()
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


func _find_meta_button(root: Node, meta_name: String) -> Button:
	for child in root.get_children():
		if child is Button and bool(child.get_meta(meta_name, false)):
			return child as Button
		var nested := _find_meta_button(child, meta_name)
		if nested != null:
			return nested
	return null


func _expect(condition: bool, message: String) -> void:
	if condition or _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
