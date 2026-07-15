extends Node

const Common = preload("res://tools/e11_probe_common.gd")
const InputFixture = preload("res://tools/e11_input_probe_fixture.gd")

const REQUIRED_KEYBOARD_ACTIONS: Array[StringName] = [
	&"ui_accept",
	&"ui_cancel",
	&"ui_left",
	&"ui_right",
	&"ui_up",
	&"ui_down",
	&"ui_focus_next",
	&"ui_focus_prev",
]
const SCREEN_REGISTRY := [
	{"id": "title", "state": "default", "script": "res://src/ui/title_screen.gd", "payload": {}, "cancel": {"kind": "none"}},
	{"id": "harbor", "state": "default", "script": "res://src/ui/harbor_screen.gd", "payload": {}, "cancel": {"kind": "none"}},
	{"id": "fishing_spots", "state": "default", "script": "res://src/ui/fishing_spot_select_screen.gd", "payload": {}, "cancel": {"kind": "navigation"}},
	{"id": "fishing", "state": "ready", "script": "res://src/ui/fishing_screen.gd", "payload": {"spot_id": "harbor_pier"}, "cancel": {"kind": "navigation"}},
	{"id": "cooking", "state": "recipe_select", "script": "res://src/ui/cooking_screen.gd", "payload": {}, "cancel": {"kind": "navigation"}},
	{"id": "market", "state": "default", "script": "res://src/ui/market_screen.gd", "payload": {}, "cancel": {"kind": "navigation"}},
	{"id": "shop", "state": "default", "script": "res://src/ui/shop_screen.gd", "payload": {}, "cancel": {"kind": "navigation"}},
	{"id": "shipyard", "state": "default", "script": "res://src/ui/shipyard_screen.gd", "payload": {}, "cancel": {"kind": "navigation"}},
	{"id": "status", "state": "default", "script": "res://src/ui/status_screen.gd", "payload": {}, "cancel": {"kind": "navigation"}},
	{"id": "fish_book", "state": "default", "script": "res://src/ui/fish_book_screen.gd", "payload": {}, "cancel": {"kind": "navigation"}},
	{"id": "quest_board", "state": "default", "script": "res://src/ui/quest_board_screen.gd", "payload": {}, "cancel": {"kind": "navigation"}},
	{"id": "shark_pen", "state": "default", "script": "res://src/ui/shark_pen_screen.gd", "payload": {}, "cancel": {"kind": "navigation"}},
	{"id": "settings", "state": "default", "script": "res://src/ui/settings_screen.gd", "payload": {}, "cancel": {"kind": "navigation"}},
]

var _findings: Array[Dictionary] = []
var _harness_errors: Array[Dictionary] = []
var _screens: Array[Dictionary] = []
var _registry: Array = []
var _input_actions: Array[Dictionary] = []
var _event_harness_errors := {}


func _ready() -> void:
	_registry = SCREEN_REGISTRY.duplicate(true)
	var self_test := OS.get_cmdline_user_args().has("--self-test")
	if self_test:
		await _run_self_test()
		if OS.get_cmdline_user_args().has("--self-test-finding"):
			_findings.append(Common.finding("FIXTURE_PRODUCT_FINDING", "P1", "fixture", "終了コード1の自己検証用"))
		if OS.get_cmdline_user_args().has("--self-test-harness-error"):
			_harness_errors.append(Common.finding("HARNESS_INJECTED", "harness_error", "fixture", "終了コード2の自己検証用"))
	else:
		await _scan_project()
	var report := {
		"schema_version": Common.SCHEMA_VERSION,
		"probe": "e11_input_focus",
		"mode": "self_test" if self_test else ("strict" if Common.strict_requested() else "baseline"),
		"strict_requested": Common.strict_requested(),
		"harness_status": "ok" if _harness_errors.is_empty() else "error",
		"product_status": "pass" if _findings.is_empty() else "findings",
		"registry_count": _registry.size(),
		"input_event_type": "InputEventKey",
		"input_actions": _input_actions,
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
	var theme_factory := load("res://src/ui/ui_theme.gd")
	if theme_factory == null or not theme_factory.has_method("build_theme"):
		_harness_errors.append(Common.finding("HARNESS_THEME_LOAD", "harness_error", "project", "共通themeを読み込めません"))
		return
	get_tree().root.theme = theme_factory.call("build_theme") as Theme
	_audit_registry_inventory()
	_audit_main_routes()
	_audit_input_actions()
	for entry in _registry:
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
		await _scan_screen(entry, screen)
		remove_child(screen)
		screen.queue_free()
		await get_tree().process_frame


func _audit_registry_inventory() -> void:
	var discovered_paths: Array[String] = []
	for file_name in DirAccess.get_files_at("res://src/ui"):
		if file_name.ends_with("_screen.gd"):
			discovered_paths.append("res://src/ui/%s" % file_name)
	discovered_paths.sort()
	_harness_errors.append_array(_registry_inventory_findings(_registry, discovered_paths))


func _registry_inventory_findings(registry: Array, discovered_paths: Array[String]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var registry_ids := {}
	var registry_paths := {}
	for entry_value in registry:
		var entry := entry_value as Dictionary
		var screen_id := String(entry.get("id", ""))
		var script_path := String(entry.get("script", ""))
		if screen_id.is_empty() or script_path.is_empty():
			result.append(Common.finding("HARNESS_REGISTRY_ENTRY", "harness_error", "registry", "registry entryのid/scriptが空です", {"entry": entry}))
			continue
		if registry_ids.has(screen_id):
			result.append(Common.finding("HARNESS_REGISTRY_DUPLICATE_ID", "harness_error", screen_id, "registryの画面IDが重複しています"))
		registry_ids[screen_id] = true
		if registry_paths.has(script_path):
			result.append(Common.finding("HARNESS_REGISTRY_DUPLICATE_SCRIPT", "harness_error", script_path, "registryの画面scriptが重複しています"))
		registry_paths[script_path] = true
	var discovered_set := {}
	for path in discovered_paths:
		discovered_set[path] = true
		if not registry_paths.has(path):
			result.append(Common.finding("HARNESS_SCREEN_UNREGISTERED", "harness_error", path, "製品画面scriptがregistryにありません"))
	for path in registry_paths:
		if not discovered_set.has(path):
			result.append(Common.finding("HARNESS_SCREEN_MISSING", "harness_error", String(path), "registryの画面scriptが製品ツリーにありません"))
	return result


func _audit_input_actions() -> void:
	var action_events := {}
	var explicit_actions := {}
	for action in REQUIRED_KEYBOARD_ACTIONS:
		var events: Array[InputEvent] = InputMap.action_get_events(action) if InputMap.has_action(action) else []
		if InputMap.has_action(action):
			action_events[action] = events
		explicit_actions[action] = ProjectSettings.has_setting("input/%s" % action)
		var keyboard_events: Array[String] = []
		var non_keyboard_events: Array[String] = []
		for event in events:
			if event is InputEventKey:
				keyboard_events.append((event as InputEventKey).as_text())
			else:
				non_keyboard_events.append(event.get_class())
		_input_actions.append({
			"action": String(action),
			"explicit": bool(explicit_actions[action]),
			"keyboard_events": keyboard_events,
			"non_keyboard_events": non_keyboard_events,
		})
	_findings.append_array(_input_action_contract_findings(action_events, explicit_actions))


func _input_action_contract_findings(action_events: Dictionary, explicit_actions: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for action in REQUIRED_KEYBOARD_ACTIONS:
		if not action_events.has(action):
			result.append(Common.finding("INPUT_ACTION_MISSING", "P1", String(action), "必須input actionがありません"))
			continue
		if not bool(explicit_actions.get(action, false)):
			result.append(Common.finding("INPUT_ACTION_NOT_EXPLICIT", "P1", String(action), "project.godotにinput actionが明示されていません"))
		var keyboard_count := 0
		var non_keyboard_classes: Array[String] = []
		for event in action_events[action]:
			if event is InputEventKey:
				keyboard_count += 1
			else:
				non_keyboard_classes.append(event.get_class())
		if keyboard_count == 0:
			result.append(Common.finding("INPUT_ACTION_NO_KEYBOARD", "P1", String(action), "必須input actionにkeyboard割当がありません"))
		if not non_keyboard_classes.is_empty():
			result.append(Common.finding("INPUT_ACTION_NON_KEYBOARD", "P1", String(action), "keyboard以外の割当があります", {"classes": non_keyboard_classes}))
	return result


func _audit_main_routes() -> void:
	var source := FileAccess.get_file_as_string("res://src/main.gd")
	_harness_errors.append_array(_main_route_findings(source, _registry))


func _main_route_findings(source: String, registry: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var preload_regex := RegEx.new()
	preload_regex.compile("const\\s+([A-Za-z0-9_]+)\\s*=\\s*preload\\(\"(res://src/ui/[a-z0-9_]+_screen\\.gd)\"\\)")
	var symbol_to_path := {}
	var path_to_symbol := {}
	for matched in preload_regex.search_all(source):
		var symbol := matched.get_string(1)
		var path := matched.get_string(2)
		symbol_to_path[symbol] = path
		path_to_symbol[path] = symbol
	var branch_regex := RegEx.new()
	branch_regex.compile("(?m)^\\s*\"([^\"]+)\":\\s*\\n\\s*screen_script\\s*=\\s*([A-Za-z0-9_]+)")
	var id_to_symbol := {}
	for matched in branch_regex.search_all(source):
		id_to_symbol[matched.get_string(1)] = matched.get_string(2)
	var registry_ids := {}
	var registry_paths := {}
	for entry_value in registry:
		var entry := entry_value as Dictionary
		var screen_id := String(entry["id"])
		var script_path := String(entry["script"])
		registry_ids[screen_id] = true
		registry_paths[script_path] = true
		if not path_to_symbol.has(script_path):
			result.append(Common.finding("HARNESS_MAIN_PRELOAD_MISSING", "harness_error", screen_id, "registry画面のmain preloadがありません", {"script": script_path}))
			continue
		if not id_to_symbol.has(screen_id):
			result.append(Common.finding("HARNESS_MAIN_MATCH_MISSING", "harness_error", screen_id, "registry画面のmain screen_id分岐がありません", {"script": script_path}))
			continue
		if id_to_symbol[screen_id] != path_to_symbol[script_path]:
			result.append(Common.finding("HARNESS_MAIN_ROUTE_MISMATCH", "harness_error", screen_id, "main分岐がregistryと異なるscreen scriptを解決します", {"expected": path_to_symbol[script_path], "actual": id_to_symbol[screen_id]}))
	for screen_id in id_to_symbol:
		var symbol := String(id_to_symbol[screen_id])
		if symbol_to_path.has(symbol) and not registry_ids.has(screen_id):
			result.append(Common.finding("HARNESS_MAIN_ROUTE_UNREGISTERED", "harness_error", String(screen_id), "main screen_id分岐がregistryにありません", {"script": symbol_to_path[symbol]}))
	for script_path in path_to_symbol:
		if not registry_paths.has(script_path):
			result.append(Common.finding("HARNESS_MAIN_PRELOAD_UNREGISTERED", "harness_error", String(script_path), "main screen preloadがregistryにありません"))
	return result


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


func _scan_screen(entry: Dictionary, screen: Control) -> void:
	var screen_id := String(entry["id"])
	var state_id := String(entry["state"])
	var focusables: Array[Control] = []
	_collect_focusables(screen, focusables)
	var owner := get_viewport().gui_get_focus_owner()
	var disabled_count := 0
	var disabled_reached_count := 0
	var missing_style_count := 0
	var elements: Array[Dictionary] = []
	var enabled_paths := {}
	for control in focusables:
		var disabled := control is BaseButton and (control as BaseButton).disabled
		if disabled:
			disabled_count += 1
		else:
			enabled_paths[str(screen.get_path_to(control))] = true
		var neighbors := _neighbor_map(control)
		var visual := Common.focus_visual_observation(control)
		var visual_contract := String(entry.get("focus_visual_contract", "stylebox"))
		var visual_ok: bool = visual.get("status", "unknown") == "distinct" or visual_contract == "custom_draw"
		if not visual_ok:
			missing_style_count += 1
		elements.append({
			"path": str(screen.get_path_to(control)),
			"class": control.get_class(),
			"disabled": disabled,
			"visible": control.is_visible_in_tree(),
			"neighbors": neighbors,
			"focus_visual": visual,
			"visible_focus_style": visual_ok,
		})
	var graph := {}
	for control in focusables:
		if not is_instance_valid(control) or (control is BaseButton and (control as BaseButton).disabled):
			continue
		var source_path := str(screen.get_path_to(control))
		graph[source_path] = {}
		for action in ["ui_left", "ui_right", "ui_up", "ui_down", "ui_focus_next", "ui_focus_prev"]:
			control.grab_focus()
			await _send_action(action)
			var reached := get_viewport().gui_get_focus_owner()
			var reached_path := ""
			if reached != null and screen.is_ancestor_of(reached):
				reached_path = str(screen.get_path_to(reached))
				if reached is BaseButton and (reached as BaseButton).disabled:
					disabled_reached_count += 1
			graph[source_path][action] = reached_path
	var initial_path := str(screen.get_path_to(owner)) if owner != null and screen.is_ancestor_of(owner) else ""
	var reachable := _reachable_paths(initial_path, graph)
	var isolated: Array[String] = []
	for path in enabled_paths:
		if not reachable.has(path):
			isolated.append(path)
	var cycle_count := _cycle_count(graph, reachable)
	var accept_observed_count := 0
	var accept_unobserved_paths: Array[String] = []
	var cancel_observed := false
	var navigation_count := [0]
	if screen.has_signal("navigate_requested"):
		screen.navigate_requested.connect(func(_id: String, _payload: Dictionary) -> void: navigation_count[0] += 1)
	for control in focusables:
		if not is_instance_valid(control) or not (control is BaseButton) or (control as BaseButton).disabled:
			continue
		var path := str(screen.get_path_to(control))
		if reachable.has(path):
			var pressed_count := [0]
			(control as BaseButton).pressed.connect(func() -> void: pressed_count[0] += 1)
			control.grab_focus()
			await _send_action("ui_accept")
			if pressed_count[0] > 0:
				accept_observed_count += 1
			else:
				accept_unobserved_paths.append(path)
	var cancel_contract := entry.get("cancel", {"kind": "unknown"}) as Dictionary
	var cancel_kind := String(cancel_contract.get("kind", "unknown"))
	var before_cancel_navigation: int = navigation_count[0]
	await _send_action("ui_cancel")
	var cancel_observed_count := 0
	match cancel_kind:
		"navigation":
			cancel_observed_count = navigation_count[0] - before_cancel_navigation
			cancel_observed = cancel_observed_count == 1
		"property":
			cancel_observed = _cancel_property_matches(screen, cancel_contract)
			cancel_observed_count = 1 if cancel_observed else 0
		"none":
			cancel_observed = true
		_: cancel_observed = false
	_screens.append({
		"id": screen_id,
		"state": state_id,
		"initial_focus": initial_path,
		"focusable_count": focusables.size(),
		"reachable_count": reachable.size(),
		"isolated_paths": isolated,
		"cycle_count": cycle_count,
		"focus_graph": graph,
		"disabled_count": disabled_count,
		"disabled_reached_count": disabled_reached_count,
		"missing_visible_focus_style_count": missing_style_count,
		"accept_observed_count": accept_observed_count,
		"accept_unobserved_paths": accept_unobserved_paths,
		"cancel_observed": cancel_observed,
		"cancel_observed_count": cancel_observed_count,
		"cancel_contract": cancel_kind,
		"elements": elements,
	})
	_findings.append_array(_classification_findings(screen_id, focusables.size(), initial_path, disabled_reached_count, isolated, missing_style_count, cancel_observed, cancel_observed_count, cancel_kind, accept_unobserved_paths))


func _classification_findings(screen_id: String, focusable_count: int, initial_path: String, disabled_reached_count: int, isolated: Array, missing_style_count: int, cancel_observed: bool, cancel_observed_count: int, cancel_kind: String, accept_unobserved_paths: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if focusable_count == 0:
		result.append(Common.finding("INPUT_NO_FOCUSABLE", "P1", screen_id, "フォーカス可能要素がありません"))
	if initial_path.is_empty():
		result.append(Common.finding("INPUT_NO_INITIAL_FOCUS", "P1", screen_id, "初期focusを観測できません"))
	if disabled_reached_count > 0:
		result.append(Common.finding("INPUT_DISABLED_REACHED", "P1", screen_id, "方向操作でdisabled要素へ到達しました", {"count": disabled_reached_count}))
	if not isolated.is_empty():
		result.append(Common.finding("INPUT_FOCUS_ISOLATED", "P1", screen_id, "初期focusから到達できない要素があります", {"count": isolated.size(), "paths": isolated}))
	if missing_style_count > 0:
		result.append(Common.finding("INPUT_FOCUS_STYLE_MISSING", "P1", screen_id, "可視focus styleを確認できない要素があります", {"count": missing_style_count}))
	if not cancel_observed:
		result.append(Common.finding("INPUT_CANCEL_UNOBSERVED", "P2", screen_id, "戻る入力が状態契約を満たしません", {"contract": cancel_kind}))
	if cancel_kind == "navigation" and cancel_observed_count > 1:
		result.append(Common.finding("INPUT_CANCEL_DUPLICATED", "P1", screen_id, "戻る入力が一度に複数回処理されました", {"count": cancel_observed_count}))
	if not accept_unobserved_paths.is_empty():
		result.append(Common.finding("INPUT_ACCEPT_UNOBSERVED", "P2", screen_id, "決定入力によるpressedを観測できない到達Buttonがあります", {"count": accept_unobserved_paths.size(), "paths": accept_unobserved_paths}))
	return result


func _send_action(action: String) -> void:
	var template := _keyboard_event_for_action(StringName(action))
	if template == null:
		return
	var pressed := template.duplicate() as InputEventKey
	pressed.pressed = true
	pressed.echo = false
	get_viewport().push_input(pressed)
	await get_tree().process_frame
	var released := template.duplicate() as InputEventKey
	released.pressed = false
	released.echo = false
	get_viewport().push_input(released)
	await get_tree().process_frame


func _keyboard_event_for_action(action: StringName) -> InputEventKey:
	if InputMap.has_action(action):
		for event in InputMap.action_get_events(action):
			if event is InputEventKey:
				return event as InputEventKey
	if not _event_harness_errors.has(action):
		_event_harness_errors[action] = true
		_harness_errors.append(Common.finding("HARNESS_KEY_EVENT_MISSING", "harness_error", String(action), "実keyboard eventを注入できません"))
	return null


func _reachable_paths(initial: String, graph: Dictionary) -> Dictionary:
	var reached := {}
	if initial.is_empty() or not graph.has(initial):
		return reached
	var queue: Array[String] = [initial]
	while not queue.is_empty():
		var current: String = queue.pop_front()
		if reached.has(current):
			continue
		reached[current] = true
		for destination in (graph.get(current, {}) as Dictionary).values():
			var path := String(destination)
			if not path.is_empty() and graph.has(path) and not reached.has(path):
				queue.append(path)
	return reached


func _cycle_count(graph: Dictionary, reachable: Dictionary) -> int:
	var colors := {}
	var count := [0]
	for source in reachable:
		if int(colors.get(source, 0)) == 0:
			_count_cycle_back_edges(String(source), graph, reachable, colors, count)
	return count[0]


func _count_cycle_back_edges(source: String, graph: Dictionary, reachable: Dictionary, colors: Dictionary, count: Array) -> void:
	colors[source] = 1
	for destination in (graph.get(source, {}) as Dictionary).values():
		var target := String(destination)
		if target.is_empty() or not reachable.has(target):
			continue
		var color := int(colors.get(target, 0))
		if color == 1:
			count[0] = int(count[0]) + 1
		elif color == 0:
			_count_cycle_back_edges(target, graph, reachable, colors, count)
	colors[source] = 2


func _cancel_property_matches(screen: Control, contract: Dictionary) -> bool:
	var node := screen.get_node_or_null(NodePath(String(contract.get("path", ""))))
	var property := StringName(contract.get("property", ""))
	if node == null or property.is_empty():
		_harness_errors.append(Common.finding("HARNESS_CANCEL_CONTRACT", "harness_error", str(screen.name), "cancel property契約が不正です", {"contract": contract}))
		return false
	return node.get(property) == contract.get("expected")


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
	var bad_normal := StyleBoxFlat.new()
	bad_normal.bg_color = Color.BLACK
	var bad_hover := StyleBoxFlat.new()
	bad_hover.bg_color = Color.DIM_GRAY
	var bad_focus := StyleBoxFlat.new()
	bad_focus.bg_color = Color.DIM_GRAY
	bad.add_theme_stylebox_override("normal", bad_normal)
	bad.add_theme_stylebox_override("hover", bad_hover)
	bad.add_theme_stylebox_override("focus", bad_focus)
	bad.add_theme_color_override("font_color", Color.GRAY)
	bad.add_theme_color_override("font_hover_color", Color.WHITE)
	bad.add_theme_color_override("font_focus_color", Color.WHITE)
	bad.add_theme_color_override("icon_normal_color", Color.GRAY)
	bad.add_theme_color_override("icon_hover_color", Color.WHITE)
	bad.add_theme_color_override("icon_focus_color", Color.WHITE)
	if _fixture_is_abnormal(good):
		_harness_errors.append(Common.finding("HARNESS_FIXTURE_GOOD", "harness_error", "fixture", "正常focus styleを異常分類しました"))
	if not _fixture_is_abnormal(bad):
		_harness_errors.append(Common.finding("HARNESS_FIXTURE_BAD", "harness_error", "fixture", "異常focus styleを正常分類しました"))
	var good_graph := {"a": {"ui_right": "b"}, "b": {"ui_left": "a"}}
	var good_reachable := _reachable_paths("a", good_graph)
	if good_reachable.size() != 2 or _cycle_count(good_graph, good_reachable) == 0:
		_harness_errors.append(Common.finding("HARNESS_GRAPH_GOOD", "harness_error", "fixture", "正常な到達・循環graphを誤分類しました"))
	var isolated_graph := {"a": {"ui_right": "a"}, "b": {"ui_left": "b"}}
	if _reachable_paths("a", isolated_graph).has("b"):
		_harness_errors.append(Common.finding("HARNESS_GRAPH_ISOLATED", "harness_error", "fixture", "孤立nodeを到達可能に分類しました"))
	var deep_disabled_graph := {"a": {"ui_right": "b"}, "b": {"ui_right": "disabled"}, "disabled": {}}
	if _disabled_graph_edge_count(deep_disabled_graph, {"disabled": true}) != 1:
		_harness_errors.append(Common.finding("HARNESS_GRAPH_DISABLED", "harness_error", "fixture", "深いdisabled到達辺を検出できません"))
	var fixture_registry := [{"id": "fixture", "script": "res://src/ui/fixture_screen.gd"}]
	if not _registry_inventory_findings(fixture_registry, ["res://src/ui/fixture_screen.gd"]).is_empty():
		_harness_errors.append(Common.finding("HARNESS_REGISTRY_VALID", "harness_error", "fixture", "正常registryを異常分類しました"))
	var extra_registry_codes := _registry_inventory_findings(fixture_registry, ["res://src/ui/fixture_screen.gd", "res://src/ui/extra_screen.gd"]).map(func(item: Dictionary) -> String: return String(item["code"]))
	if not extra_registry_codes.has("HARNESS_SCREEN_UNREGISTERED"):
		_harness_errors.append(Common.finding("HARNESS_REGISTRY_EXTRA", "harness_error", "fixture", "未登録画面を検出できません", {"actual": extra_registry_codes}))
	var missing_registry_codes := _registry_inventory_findings(fixture_registry, []).map(func(item: Dictionary) -> String: return String(item["code"]))
	if not missing_registry_codes.has("HARNESS_SCREEN_MISSING"):
		_harness_errors.append(Common.finding("HARNESS_REGISTRY_MISSING", "harness_error", "fixture", "欠落画面を検出できません", {"actual": missing_registry_codes}))
	var duplicate_registry_codes := _registry_inventory_findings(fixture_registry + fixture_registry, ["res://src/ui/fixture_screen.gd"]).map(func(item: Dictionary) -> String: return String(item["code"]))
	if not duplicate_registry_codes.has("HARNESS_REGISTRY_DUPLICATE_ID") or not duplicate_registry_codes.has("HARNESS_REGISTRY_DUPLICATE_SCRIPT"):
		_harness_errors.append(Common.finding("HARNESS_REGISTRY_DUPLICATE", "harness_error", "fixture", "registry重複を検出できません", {"actual": duplicate_registry_codes}))
	var good_action_events := {}
	var good_explicit_actions := {}
	for action in REQUIRED_KEYBOARD_ACTIONS:
		good_action_events[action] = [InputEventKey.new()]
		good_explicit_actions[action] = true
	if not _input_action_contract_findings(good_action_events, good_explicit_actions).is_empty():
		_harness_errors.append(Common.finding("HARNESS_INPUT_MAP_VALID", "harness_error", "fixture", "正常keyboard action mapを異常分類しました"))
	var bad_action_events := good_action_events.duplicate(true)
	var bad_explicit_actions := good_explicit_actions.duplicate(true)
	bad_action_events.erase(&"ui_cancel")
	bad_action_events[&"ui_accept"] = [InputEventJoypadButton.new()]
	bad_explicit_actions[&"ui_left"] = false
	var bad_action_codes := _input_action_contract_findings(bad_action_events, bad_explicit_actions).map(func(item: Dictionary) -> String: return String(item["code"]))
	for expected_action_code in ["INPUT_ACTION_MISSING", "INPUT_ACTION_NOT_EXPLICIT", "INPUT_ACTION_NO_KEYBOARD", "INPUT_ACTION_NON_KEYBOARD"]:
		if not bad_action_codes.has(expected_action_code):
			_harness_errors.append(Common.finding("HARNESS_INPUT_MAP_INVALID", "harness_error", "fixture", "異常action mapのfindingが不足しています", {"missing": expected_action_code, "actual": bad_action_codes}))
	var cancel_fixture := InputFixture.new()
	add_child(cancel_fixture)
	get_viewport().gui_release_focus()
	await _send_action("ui_cancel")
	if not cancel_fixture.cancel_received:
		_harness_errors.append(Common.finding("HARNESS_CANCEL_NO_FOCUS", "harness_error", "fixture", "focusなしの戻る入力を観測できません"))
	remove_child(cancel_fixture)
	cancel_fixture.queue_free()
	var accept_fixture := Button.new()
	add_child(accept_fixture)
	var accept_count := [0]
	accept_fixture.pressed.connect(func() -> void: accept_count[0] += 1)
	accept_fixture.grab_focus()
	await _send_action("ui_accept")
	if accept_count[0] != 1:
		_harness_errors.append(Common.finding("HARNESS_ACCEPT", "harness_error", "fixture", "到達Buttonの決定入力を観測できません"))
	remove_child(accept_fixture)
	accept_fixture.queue_free()
	var good_classification := _classification_findings("fixture_good", 2, "a", 0, [], 0, true, 1, "navigation", [])
	if not good_classification.is_empty():
		_harness_errors.append(Common.finding("HARNESS_CLASSIFY_GOOD", "harness_error", "fixture", "正常入力観測をfindingに分類しました", {"findings": good_classification}))
	var bad_classification := _classification_findings("fixture_bad", 2, "a", 1, ["b"], 0, false, 0, "property", ["a"])
	var bad_codes := bad_classification.map(func(item: Dictionary) -> String: return String(item["code"]))
	for expected_code in ["INPUT_DISABLED_REACHED", "INPUT_FOCUS_ISOLATED", "INPUT_CANCEL_UNOBSERVED", "INPUT_ACCEPT_UNOBSERVED"]:
		if not bad_codes.has(expected_code):
			_harness_errors.append(Common.finding("HARNESS_CLASSIFY_BAD", "harness_error", "fixture", "異常入力観測のfindingが不足しています", {"missing": expected_code, "actual": bad_codes}))
	var duplicate_cancel_codes := _classification_findings("fixture_duplicate_cancel", 1, "a", 0, [], 0, false, 2, "navigation", []).map(func(item: Dictionary) -> String: return String(item["code"]))
	if not duplicate_cancel_codes.has("INPUT_CANCEL_DUPLICATED"):
		_harness_errors.append(Common.finding("HARNESS_CANCEL_DUPLICATE", "harness_error", "fixture", "戻るの二重処理を検出できません", {"actual": duplicate_cancel_codes}))
	var settings_registry := [{"id": "settings", "script": "res://src/ui/settings_screen.gd"}]
	var valid_settings_source := "const SettingsScreen = preload(\"res://src/ui/settings_screen.gd\")\nfunc route(id):\n match id:\n  \"settings\":\n   screen_script = SettingsScreen\n"
	if not _main_route_findings(valid_settings_source, settings_registry).is_empty():
		_harness_errors.append(Common.finding("HARNESS_ROUTE_VALID", "harness_error", "fixture", "正常settings routeを異常分類しました"))
	var missing_preload_source := "func route(id):\n match id:\n  \"settings\":\n   screen_script = SettingsScreen\n"
	var missing_preload_codes := _main_route_findings(missing_preload_source, settings_registry).map(func(item: Dictionary) -> String: return String(item["code"]))
	if not missing_preload_codes.has("HARNESS_MAIN_PRELOAD_MISSING"):
		_harness_errors.append(Common.finding("HARNESS_ROUTE_PRELOAD", "harness_error", "fixture", "settings preload欠落を検出できません", {"actual": missing_preload_codes}))
	var missing_match_source := "const SettingsScreen = preload(\"res://src/ui/settings_screen.gd\")\n"
	var missing_match_codes := _main_route_findings(missing_match_source, settings_registry).map(func(item: Dictionary) -> String: return String(item["code"]))
	if not missing_match_codes.has("HARNESS_MAIN_MATCH_MISSING"):
		_harness_errors.append(Common.finding("HARNESS_ROUTE_MATCH", "harness_error", "fixture", "settings match欠落を検出できません", {"actual": missing_match_codes}))
	_screens = [{"id": "fixture_good", "classification": "pass"}, {"id": "fixture_bad", "classification": "finding"}]
	good.free()
	bad.free()


func _fixture_is_abnormal(control: Button) -> bool:
	return not Common.has_distinct_focus_style(control)


func _disabled_graph_edge_count(graph: Dictionary, disabled_paths: Dictionary) -> int:
	var count := 0
	for edges in graph.values():
		for destination in (edges as Dictionary).values():
			if disabled_paths.has(String(destination)):
				count += 1
	return count
