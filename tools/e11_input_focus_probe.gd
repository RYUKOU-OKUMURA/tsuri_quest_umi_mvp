extends Node

const Common = preload("res://tools/e11_probe_common.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")

const REGISTRY := [
	{"id": "title", "state": "default", "script": "res://src/ui/title_screen.gd", "payload": {}, "setup": []},
	{"id": "harbor", "state": "default", "script": "res://src/ui/harbor_screen.gd", "payload": {}, "setup": []},
	{"id": "fishing_spots", "state": "default", "script": "res://src/ui/fishing_spot_select_screen.gd", "payload": {}},
	{"id": "fishing", "state": "ready", "script": "res://src/ui/fishing_screen.gd", "payload": {"spot_id": "harbor_pier"}},
	{"id": "cooking", "state": "recipe_select", "script": "res://src/ui/cooking_screen.gd", "payload": {}},
	{"id": "market", "state": "default", "script": "res://src/ui/market_screen.gd", "payload": {}},
	{"id": "shop", "state": "default", "script": "res://src/ui/shop_screen.gd", "payload": {}},
	{"id": "shipyard", "state": "default", "script": "res://src/ui/shipyard_screen.gd", "payload": {}},
	{"id": "status", "state": "default", "script": "res://src/ui/status_screen.gd", "payload": {}},
	{"id": "fish_book", "state": "default", "script": "res://src/ui/fish_book_screen.gd", "payload": {}},
	{"id": "quest_board", "state": "default", "script": "res://src/ui/quest_board_screen.gd", "payload": {}},
	{"id": "shark_pen", "state": "default", "script": "res://src/ui/shark_pen_screen.gd", "payload": {}},
]

var _findings: Array[Dictionary] = []
var _harness_errors: Array[Dictionary] = []
var _screens: Array[Dictionary] = []


func _ready() -> void:
	if OS.get_cmdline_user_args().has("--self-test"):
		_run_self_test()
		if OS.get_cmdline_user_args().has("--self-test-harness-error"):
			_harness_errors.append(Common.finding("HARNESS_INJECTED", "harness_error", "fixture", "終了コード2の自己検証用"))
	else:
		await _scan_project()
	var report := {
		"schema_version": Common.SCHEMA_VERSION,
		"probe": "e11_input_focus",
		"mode": "strict" if Common.strict_requested() else "baseline",
		"harness_status": "ok" if _harness_errors.is_empty() else "error",
		"product_status": "pass" if _findings.is_empty() else "findings",
		"registry_count": REGISTRY.size(),
		"screens": _screens,
		"findings": _findings,
		"harness_errors": _harness_errors,
	}
	if not Common.write_report(report, "/tmp/e11_input_focus_probe.json"):
		get_tree().quit(2)
	elif not _harness_errors.is_empty():
		get_tree().quit(2)
	elif Common.strict_requested() and not _findings.is_empty():
		get_tree().quit(1)
	else:
		get_tree().quit(0)


func _scan_project() -> void:
	get_tree().root.theme = ThemeFactory.build_theme()
	for entry in REGISTRY:
		var script := load(String(entry["script"])) as Script
		if script == null:
			_harness_errors.append(Common.finding("HARNESS_SCREEN_LOAD", "harness_error", String(entry["id"]), "画面scriptを読み込めません"))
			continue
		var screen := script.new() as Control
		if screen == null:
			_harness_errors.append(Common.finding("HARNESS_SCREEN_CREATE", "harness_error", String(entry["id"]), "画面を生成できません"))
			continue
		if screen.has_method("configure"):
			screen.call("configure", (entry["payload"] as Dictionary).duplicate(true))
		add_child(screen)
		await get_tree().process_frame
		await get_tree().process_frame
		await _apply_setup(screen, entry.get("setup", []))
		await _scan_screen(String(entry["id"]), String(entry["state"]), screen)
		remove_child(screen)
		screen.queue_free()
		await get_tree().process_frame


func _apply_setup(screen: Control, steps: Array) -> void:
	for step_value in steps:
		var step := step_value as Dictionary
		match String(step.get("kind", "")):
			"call":
				var method := StringName(step.get("method", ""))
				if not screen.has_method(method):
					_harness_errors.append(Common.finding("HARNESS_SETUP_METHOD", "harness_error", str(screen.name), "状態setup methodがありません", {"method": str(method)}))
					return
				screen.callv(method, step.get("args", []))
			"input":
				await _send_action(String(step.get("action", "")))
			_:
				_harness_errors.append(Common.finding("HARNESS_SETUP_KIND", "harness_error", str(screen.name), "未知の状態setupです", {"step": step}))
				return
		await get_tree().process_frame


func _scan_screen(screen_id: String, state_id: String, screen: Control) -> void:
	var focusables: Array[Control] = []
	_collect_focusables(screen, focusables)
	var owner := get_viewport().gui_get_focus_owner()
	var disabled_count := 0
	var disabled_reached_count := 0
	var stalled_direction_count := 0
	var missing_style_count := 0
	var elements: Array[Dictionary] = []
	for control in focusables:
		var disabled := control is BaseButton and (control as BaseButton).disabled
		if disabled:
			disabled_count += 1
		var neighbors := _neighbor_map(control)
		if not Common.has_distinct_focus_style(control):
			missing_style_count += 1
		elements.append({
			"path": str(screen.get_path_to(control)),
			"class": control.get_class(),
			"disabled": disabled,
			"visible": control.is_visible_in_tree(),
			"neighbors": neighbors,
			"visible_focus_style": Common.has_distinct_focus_style(control),
		})
	var accept_observed := false
	var cancel_observed := false
	var navigation_count := [0]
	if screen.has_signal("navigate_requested"):
		screen.navigate_requested.connect(func(_id: String, _payload: Dictionary) -> void: navigation_count[0] += 1)
	if owner != null and screen.is_ancestor_of(owner):
		for action in ["ui_left", "ui_right", "ui_up", "ui_down"]:
			owner.grab_focus()
			await _send_action(action)
			var reached := get_viewport().gui_get_focus_owner()
			if reached == owner:
				stalled_direction_count += 1
			if reached is BaseButton and (reached as BaseButton).disabled:
				disabled_reached_count += 1
		owner.grab_focus()
		if owner is BaseButton:
			var pressed_count := [0]
			(owner as BaseButton).pressed.connect(func() -> void: pressed_count[0] += 1)
			await _send_action("ui_accept")
			accept_observed = pressed_count[0] > 0 or navigation_count[0] > 0
		var before_cancel_navigation: int = navigation_count[0]
		await _send_action("ui_cancel")
		cancel_observed = navigation_count[0] > before_cancel_navigation
	_screens.append({
		"id": screen_id,
		"state": state_id,
		"initial_focus": str(screen.get_path_to(owner)) if owner != null and screen.is_ancestor_of(owner) else "",
		"focusable_count": focusables.size(),
		"disabled_count": disabled_count,
		"disabled_reached_count": disabled_reached_count,
		"stalled_direction_count": stalled_direction_count,
		"missing_visible_focus_style_count": missing_style_count,
		"accept_observed": accept_observed,
		"cancel_observed": cancel_observed,
		"elements": elements,
	})
	if focusables.is_empty():
		_findings.append(Common.finding("INPUT_NO_FOCUSABLE", "P1", screen_id, "フォーカス可能要素がありません"))
	if owner == null or not screen.is_ancestor_of(owner):
		_findings.append(Common.finding("INPUT_NO_INITIAL_FOCUS", "P1", screen_id, "初期focusを観測できません"))
	if disabled_reached_count > 0:
		_findings.append(Common.finding("INPUT_DISABLED_REACHED", "P1", screen_id, "方向操作でdisabled要素へ到達しました", {"count": disabled_reached_count}))
	if stalled_direction_count == 4 and focusables.size() > 1:
		_findings.append(Common.finding("INPUT_NEIGHBOR_STALLED", "P1", screen_id, "初期focusから全方向の遷移が停止しています"))
	if missing_style_count > 0:
		_findings.append(Common.finding("INPUT_FOCUS_STYLE_MISSING", "P1", screen_id, "可視focus styleを確認できない要素があります", {"count": missing_style_count}))
	if not cancel_observed:
		_findings.append(Common.finding("INPUT_CANCEL_UNOBSERVED", "P2", screen_id, "戻る入力によるnavigationを観測できません"))
	if not accept_observed:
		_findings.append(Common.finding("INPUT_ACCEPT_UNOBSERVED", "P2", screen_id, "決定入力によるpressed/navigationを観測できません"))


func _send_action(action: String) -> void:
	var pressed := InputEventAction.new()
	pressed.action = action
	pressed.pressed = true
	get_viewport().push_input(pressed)
	await get_tree().process_frame
	var released := InputEventAction.new()
	released.action = action
	released.pressed = false
	get_viewport().push_input(released)
	await get_tree().process_frame


func _collect_focusables(node: Node, result: Array[Control]) -> void:
	if node is Control:
		var control := node as Control
		if control.focus_mode != Control.FOCUS_NONE and control.is_visible_in_tree():
			result.append(control)
	for child in node.get_children():
		_collect_focusables(child, result)


func _neighbor_map(control: Control) -> Dictionary:
	return {
		"left": not control.focus_neighbor_left.is_empty(),
		"right": not control.focus_neighbor_right.is_empty(),
		"up": not control.focus_neighbor_top.is_empty(),
		"down": not control.focus_neighbor_bottom.is_empty(),
		"next": not control.focus_next.is_empty(),
		"previous": not control.focus_previous.is_empty(),
	}


func _run_self_test() -> void:
	var good := Button.new()
	good.add_theme_stylebox_override("normal", StyleBoxFlat.new())
	good.add_theme_stylebox_override("focus", StyleBoxLine.new())
	var bad := Button.new()
	bad.disabled = true
	bad.focus_mode = Control.FOCUS_ALL
	if _fixture_is_abnormal(good):
		_harness_errors.append(Common.finding("HARNESS_FIXTURE_GOOD", "harness_error", "fixture", "正常focus styleを異常分類しました"))
	if not _fixture_is_abnormal(bad):
		_harness_errors.append(Common.finding("HARNESS_FIXTURE_BAD", "harness_error", "fixture", "異常focus styleを正常分類しました"))
	_screens = [{"id": "fixture_good", "classification": "pass"}, {"id": "fixture_bad", "classification": "finding"}]
	good.free()
	bad.free()


func _fixture_is_abnormal(control: Button) -> bool:
	return (control.disabled and control.focus_mode != Control.FOCUS_NONE) or not Common.has_distinct_focus_style(control)
