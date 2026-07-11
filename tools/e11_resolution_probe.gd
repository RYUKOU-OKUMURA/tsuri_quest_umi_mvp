extends Node

const Common = preload("res://tools/e11_probe_common.gd")
const CASES := [Vector2i(1280, 720), Vector2i(1280, 800), Vector2i(1024, 768)]
const DESIGN := Vector2(1280.0, 720.0)

var _findings: Array[Dictionary] = []
var _harness_errors: Array[Dictionary] = []
var _measurements: Array[Dictionary] = []


func _ready() -> void:
	if OS.get_cmdline_user_args().has("--self-test"):
		_run_self_test()
	else:
		await _measure_project()
	var report := {
		"schema_version": Common.SCHEMA_VERSION,
		"probe": "e11_resolution",
		"mode": "strict" if Common.strict_requested() else "baseline",
		"harness_status": "ok" if _harness_errors.is_empty() else "error",
		"product_status": "pass" if _findings.is_empty() else "findings",
		"stretch": {
			"mode": str(ProjectSettings.get_setting("display/window/stretch/mode", "")),
			"aspect": str(ProjectSettings.get_setting("display/window/stretch/aspect", "")),
		},
		"runtime": {
			"viewport_visible_rect": _rect_json(get_viewport().get_visible_rect()),
			"window_size": _vec_json(get_window().size),
		},
		"measurements": _measurements,
		"findings": _findings,
		"harness_errors": _harness_errors,
	}
	if not Common.write_report(report, "/tmp/e11_resolution_probe.json"):
		get_tree().quit(2)
	elif not _harness_errors.is_empty():
		get_tree().quit(2)
	elif Common.strict_requested() and not _findings.is_empty():
		get_tree().quit(1)
	else:
		get_tree().quit(0)


func _measure_project() -> void:
	var viewport_size := Vector2(
		float(ProjectSettings.get_setting("display/window/size/viewport_width", 0)),
		float(ProjectSettings.get_setting("display/window/size/viewport_height", 0))
	)
	var mode := str(ProjectSettings.get_setting("display/window/stretch/mode", ""))
	var aspect := str(ProjectSettings.get_setting("display/window/stretch/aspect", ""))
	if viewport_size != DESIGN:
		_findings.append(Common.finding("DISPLAY_DESIGN_SIZE", "P1", "project", "設計viewportが1280x720ではありません", {"actual": _vec_json(viewport_size)}))
	if mode != "canvas_items":
		_findings.append(Common.finding("DISPLAY_STRETCH_MODE", "P1", "project", "stretch modeがcanvas_itemsではありません", {"actual": mode}))
	if aspect != "keep":
		_findings.append(Common.finding("DISPLAY_STRETCH_ASPECT", "P1", "project", "stretch aspectがkeepではありません", {"actual": aspect, "expected": "keep"}))
	for window_size in CASES:
		get_window().size = window_size
		await get_tree().process_frame
		await get_tree().process_frame
		var measurement := _measurement(window_size)
		measurement["observed"] = {
			"window_size": _vec_json(get_window().size),
			"viewport_visible_rect": _rect_json(get_viewport().get_visible_rect()),
			"content_scale_size": _vec_json(get_window().content_scale_size),
			"content_scale_aspect": get_window().content_scale_aspect,
			"content_scale_mode": get_window().content_scale_mode,
		}
		var matches_expected_keep: bool = (
			get_window().size == window_size
			and get_window().content_scale_size == Vector2i(DESIGN)
			and get_window().content_scale_aspect == Window.CONTENT_SCALE_ASPECT_KEEP
		)
		measurement["matches_expected_keep"] = matches_expected_keep
		if not matches_expected_keep:
			_findings.append(Common.finding("DISPLAY_RUNTIME_KEEP_MISMATCH", "P1", "%dx%d" % [window_size.x, window_size.y], "runtime観測値が想定keep契約と一致しません", {"observed": measurement["observed"], "expected_content_rect": measurement["expected_content_rect"]}))
		if get_window().size != window_size:
			_harness_errors.append(Common.finding("HARNESS_WINDOW_RESIZE", "harness_error", str(window_size), "指定window sizeをruntimeで観測できません", {"observed": _vec_json(get_window().size)}))
		_measurements.append(measurement)


func _measurement(window_size: Vector2i) -> Dictionary:
	var scale: float = minf(float(window_size.x) / DESIGN.x, float(window_size.y) / DESIGN.y)
	var content_size: Vector2 = DESIGN * scale
	var offset: Vector2 = (Vector2(window_size) - content_size) / 2.0
	var bars := {
		"left": Rect2(0, 0, offset.x, window_size.y),
		"right": Rect2(window_size.x - offset.x, 0, offset.x, window_size.y),
		"top": Rect2(offset.x, 0, content_size.x, offset.y),
		"bottom": Rect2(offset.x, window_size.y - offset.y, content_size.x, offset.y),
	}
	var bars_json := {}
	for key in bars:
		bars_json[key] = _rect_json(bars[key])
	return {
		"window_size": _vec_json(window_size),
		"window_aspect": float(window_size.x) / float(window_size.y),
		"viewport_size": _vec_json(DESIGN),
		"expected_content_rect": _rect_json(Rect2(offset, content_size)),
		"content_aspect": content_size.x / content_size.y,
		"scale": scale,
		"black_bars": bars_json,
	}


func _run_self_test() -> void:
	var exact := _measurement(Vector2i(1280, 720))
	var four_three := _measurement(Vector2i(1024, 768))
	var exact_rect := exact["expected_content_rect"] as Dictionary
	var four_three_rect := four_three["expected_content_rect"] as Dictionary
	if not is_equal_approx(float(exact_rect["width"]), 1280.0) or not is_equal_approx(float(exact_rect["x"]), 0.0):
		_harness_errors.append(Common.finding("HARNESS_FIXTURE_EXACT", "harness_error", "fixture", "16:9正常fixtureを誤分類しました"))
	if not is_equal_approx(float(four_three_rect["height"]), 576.0) or not is_equal_approx(float(four_three_rect["y"]), 96.0):
		_harness_errors.append(Common.finding("HARNESS_FIXTURE_4_3", "harness_error", "fixture", "4:3黒帯fixtureの計算が不正です"))
	_measurements = [exact, four_three]


func _vec_json(value: Vector2) -> Dictionary:
	return {"width": value.x, "height": value.y}


func _rect_json(value: Rect2) -> Dictionary:
	return {"x": value.position.x, "y": value.position.y, "width": value.size.x, "height": value.size.y}
