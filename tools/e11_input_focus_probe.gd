extends Node

const Common = preload("res://tools/e11_probe_common.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")
const InputFixture = preload("res://tools/e11_input_probe_fixture.gd")

const BASE_REGISTRY := [
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
]

var _findings: Array[Dictionary] = []
var _harness_errors: Array[Dictionary] = []
var _screens: Array[Dictionary] = []
var _registry: Array = []


func _ready() -> void:
	_registry = BASE_REGISTRY.duplicate(true)
	if ResourceLoader.exists("res://src/ui/settings_screen.gd"):
		_registry.append({"id": "settings", "state": "default", "script": "res://src/ui/settings_screen.gd", "payload": {}, "cancel": {"kind": "navigation"}})
	if OS.get_cmdline_user_args().has("--self-test"):
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
		"mode": "strict" if Common.strict_requested() else "baseline",
		"harness_status": "ok" if _harness_errors.is_empty() else "error",
		"product_status": "pass" if _findings.is_empty() else "findings",
		"registry_count": _registry.size(),
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
	_audit_main_routes()
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


func _audit_main_routes() -> void:
	var source := FileAccess.get_file_as_string("res://src/main.gd")
	var regex := RegEx.new()
	regex.compile("res://src/ui/[a-z0-9_]+_screen\\.gd")
	var registered := {}
	for entry in _registry:
		registered[String(entry["script"])] = true
	for result in regex.search_all(source):
		var path := result.get_string()
		if not registered.has(path):
			_harness_errors.append(Common.finding("HARNESS_MAIN_ROUTE_UNREGISTERED", "harness_error", path, "main画面routeがregistryにありません"))


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
	match cancel_kind:
		"navigation": cancel_observed = navigation_count[0] > before_cancel_navigation
		"property": cancel_observed = _cancel_property_matches(screen, cancel_contract)
		"none": cancel_observed = true
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
		"cancel_contract": cancel_kind,
		"elements": elements,
	})
	_findings.append_array(_classification_findings(screen_id, focusables.size(), initial_path, disabled_reached_count, isolated, missing_style_count, cancel_observed, cancel_kind, accept_unobserved_paths))


func _classification_findings(screen_id: String, focusable_count: int, initial_path: String, disabled_reached_count: int, isolated: Array, missing_style_count: int, cancel_observed: bool, cancel_kind: String, accept_unobserved_paths: Array) -> Array[Dictionary]:
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
	if not accept_unobserved_paths.is_empty():
		result.append(Common.finding("INPUT_ACCEPT_UNOBSERVED", "P2", screen_id, "決定入力によるpressedを観測できない到達Buttonがあります", {"count": accept_unobserved_paths.size(), "paths": accept_unobserved_paths}))
	return result


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
	var bad_focus := StyleBoxFlat.new()
	bad.add_theme_stylebox_override("normal", bad_normal)
	bad.add_theme_stylebox_override("focus", bad_focus)
	bad.add_theme_color_override("font_color", Color.WHITE)
	bad.add_theme_color_override("font_focus_color", Color.WHITE)
	bad.add_theme_color_override("icon_normal_color", Color.WHITE)
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
	var good_classification := _classification_findings("fixture_good", 2, "a", 0, [], 0, true, "navigation", [])
	if not good_classification.is_empty():
		_harness_errors.append(Common.finding("HARNESS_CLASSIFY_GOOD", "harness_error", "fixture", "正常入力観測をfindingに分類しました", {"findings": good_classification}))
	var bad_classification := _classification_findings("fixture_bad", 2, "a", 1, ["b"], 0, false, "property", ["a"])
	var bad_codes := bad_classification.map(func(item: Dictionary) -> String: return String(item["code"]))
	for expected_code in ["INPUT_DISABLED_REACHED", "INPUT_FOCUS_ISOLATED", "INPUT_CANCEL_UNOBSERVED", "INPUT_ACCEPT_UNOBSERVED"]:
		if not bad_codes.has(expected_code):
			_harness_errors.append(Common.finding("HARNESS_CLASSIFY_BAD", "harness_error", "fixture", "異常入力観測のfindingが不足しています", {"missing": expected_code, "actual": bad_codes}))
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
