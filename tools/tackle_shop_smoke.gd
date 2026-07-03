extends Node

const ShopScreenScript = preload("res://src/ui/shop_screen.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")

var _screen: Variant
var _navigated_to := ""
var _payload: Dictionary = {}
var _failed := false


func _ready() -> void:
	_seed_progress()
	_screen = _make_screen()
	await get_tree().process_frame
	await get_tree().process_frame

	_expect(_screen._cards_layer != null, "card layer should be present")
	_expect(_screen._detail_title_label != null, "detail title should be present")
	_expect(_screen._action_button != null, "action button should be present")
	_expect(_screen._return_button != null, "return button should be present")
	_expect(_find_item_lists(_screen).is_empty(), "old ItemList must not remain")
	_expect(_card_buttons(_screen, "rod").size() == GameData.get_all_rod_ids().size(), "rod cards should match rod data")
	_expect(_card_button(_screen, "rod", "big_game") != null, "big_game rod card should be present")
	_expect(_card_button(_screen, "rod", "marlin") != null, "marlin rod card should be present")
	_expect(_card_buttons(_screen, "rig").is_empty(), "rig cards should not render while rod tab is active")

	_screen._select_item("iso")
	await get_tree().process_frame
	_expect(_screen._selected_item_id == "iso", "rod card selection should update selected item")
	_expect(not _screen._action_button.disabled, "affordable unowned rod should be purchasable")
	_screen._action_button.pressed.emit()
	_expect("iso" in PlayerProgress.owned_rods, "purchased rod should be owned")
	_expect(PlayerProgress.equipped_rod_id == "iso", "purchased rod should be equipped")
	_expect(PlayerProgress.money == 150, "rod purchase should subtract money")

	PlayerProgress.money = 10000
	_screen._select_item("marlin")
	await get_tree().process_frame
	_expect(not _screen._action_button.disabled, "marlin rod should be purchasable when affordable")
	_screen._action_button.pressed.emit()
	_expect("marlin" in PlayerProgress.owned_rods, "marlin rod should be owned after purchase")
	_expect(PlayerProgress.equipped_rod_id == "marlin", "marlin rod should equip after purchase")
	_expect(PlayerProgress.money == 1000, "marlin purchase should subtract money")

	PlayerProgress.money = 3000
	_screen._select_item("big_game")
	await get_tree().process_frame
	_expect(_screen._action_button.disabled, "unaffordable big_game rod should disable action")
	_expect(_screen._detail_status_label.text.contains("所持金"), "unaffordable rod should explain money shortage")

	PlayerProgress.money = 150
	_screen._set_shop_mode("rig")
	await get_tree().process_frame
	_expect(_card_buttons(_screen, "rig").size() == GameData.get_all_rig_ids().size(), "rig cards should match rig data")
	_expect(_card_buttons(_screen, "rod").is_empty(), "rod cards should not render while rig tab is active")

	_screen._select_item("chokusen")
	await get_tree().process_frame
	_expect(_screen._action_button.disabled, "unaffordable rig should disable action")
	_expect(_screen._detail_status_label.text.contains("所持金"), "unaffordable rig should explain money shortage")

	PlayerProgress.money = 1000
	_screen._refresh()
	await get_tree().process_frame
	_expect(not _screen._action_button.disabled, "affordable rig should enable action")
	_screen._action_button.pressed.emit()
	_expect("chokusen" in PlayerProgress.owned_rigs, "purchased rig should be owned")
	_expect(PlayerProgress.equipped_rig_id == "chokusen", "purchased rig should be equipped")

	_screen._select_item("nomase")
	await get_tree().process_frame
	_expect(_screen._action_button.disabled, "level-locked rig should disable action")
	_expect(_screen._action_button.text.contains("Lv.4"), "level-locked rig should show unlock level")

	_screen._return_button.pressed.emit()
	_expect(_navigated_to == "harbor", "return button should navigate to harbor")

	if _failed:
		return
	print("tackle_shop_smoke: ok")
	get_tree().quit(0)


func _seed_progress() -> void:
	PlayerProgress.level = 2
	PlayerProgress.exp = 0
	PlayerProgress.money = 1000
	PlayerProgress.owned_rods = ["starter"]
	PlayerProgress.equipped_rod_id = "starter"
	PlayerProgress.owned_rigs = [GameData.DEFAULT_RIG_ID]
	PlayerProgress.equipped_rig_id = GameData.DEFAULT_RIG_ID
	PlayerProgress.owned_boats = []
	PlayerProgress.inventory = {}
	PlayerProgress.caught_counts = {}
	PlayerProgress.spot_caught_counts = {}
	PlayerProgress.best_sizes = {}
	PlayerProgress.pending_buff = {}


func _make_screen(payload: Dictionary = {}) -> Control:
	var screen := ShopScreenScript.new()
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


func _card_buttons(root: Node, mode: String) -> Array[Button]:
	var buttons: Array[Button] = []
	_collect_card_buttons(root, mode, buttons)
	return buttons


func _card_button(root: Node, mode: String, item_id: String) -> Button:
	for button in _card_buttons(root, mode):
		if String(button.get_meta("shop_item_id", "")) == item_id:
			return button
	return null


func _collect_card_buttons(node: Node, mode: String, buttons: Array[Button]) -> void:
	for child in node.get_children():
		if child is Button and bool(child.get_meta("shop_item_card", false)):
			if String(child.get_meta("shop_mode", "")) == mode:
				buttons.append(child as Button)
		_collect_card_buttons(child, mode, buttons)


func _find_item_lists(root: Node) -> Array[ItemList]:
	var lists: Array[ItemList] = []
	_collect_item_lists(root, lists)
	return lists


func _collect_item_lists(node: Node, lists: Array[ItemList]) -> void:
	for child in node.get_children():
		if child is ItemList:
			lists.append(child as ItemList)
		_collect_item_lists(child, lists)


func _expect(condition: bool, message: String) -> void:
	if condition or _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
