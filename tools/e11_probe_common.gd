class_name E11ProbeCommon
extends RefCounted

const SCHEMA_VERSION := 1


static func finding(code: String, severity: String, target: String, message: String, evidence: Dictionary = {}) -> Dictionary:
	return {
		"code": code,
		"severity": severity,
		"target": target,
		"message": message,
		"evidence": evidence,
	}


static func write_report(report: Dictionary, default_path: String) -> bool:
	var output_path := default_path
	var args := OS.get_cmdline_user_args()
	for index in range(args.size() - 1):
		if args[index] == "--output":
			output_path = args[index + 1]
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		push_error("E11 probe reportを書き込めません: %s" % output_path)
		return false
	file.store_string(JSON.stringify(report, "\t") + "\n")
	print("E11_PROBE_REPORT=%s" % output_path)
	return true


static func strict_requested() -> bool:
	return OS.get_cmdline_user_args().has("--strict")


static func focus_visual_observation(control: Control) -> Dictionary:
	if not control.has_theme_stylebox("focus"):
		return {"status": "unknown", "reason": "focus styleなし"}
	var focus := control.get_theme_stylebox("focus")
	if focus == null:
		return {"status": "unknown", "reason": "focus styleがnull"}
	var focus_signature := _stylebox_signature(focus)
	var state_signatures := {}
	var style_same := false
	for state in ["normal", "hover", "pressed"]:
		if control.has_theme_stylebox(state):
			state_signatures[state] = _stylebox_signature(control.get_theme_stylebox(state))
			if focus_signature == state_signatures[state]:
				style_same = true
	var focus_colors := {}
	for color_name in ["font_focus_color", "font_color", "font_hover_color", "font_pressed_color", "icon_focus_color", "icon_normal_color"]:
		if control.has_theme_color(color_name):
			focus_colors[color_name] = control.get_theme_color(color_name).to_html(true)
	var color_distinct: bool = (
		focus_colors.has("font_focus_color")
		and focus_colors.get("font_focus_color") != focus_colors.get("font_color")
	) or (
		focus_colors.has("icon_focus_color")
		and focus_colors.get("icon_focus_color") != focus_colors.get("icon_normal_color")
	)
	if style_same and not color_distinct:
		return {"status": "same", "focus": focus_signature, "states": state_signatures, "colors": focus_colors}
	return {"status": "distinct", "focus": focus_signature, "states": state_signatures, "colors": focus_colors}


static func has_distinct_focus_style(control: Control) -> bool:
	return focus_visual_observation(control).get("status", "unknown") == "distinct"


static func _stylebox_signature(style: StyleBox) -> Dictionary:
	return _resource_signature(style, {}, 0)


static func _resource_signature(resource: Resource, visited: Dictionary, depth: int) -> Dictionary:
	if resource == null:
		return {"class": "null"}
	var instance_id := resource.get_instance_id()
	if visited.has(instance_id):
		return {"class": resource.get_class(), "cycle": true}
	visited[instance_id] = true
	var signature := {"class": resource.get_class()}
	for property in resource.get_property_list():
		var name := String(property.get("name", ""))
		var usage := int(property.get("usage", 0))
		if name.is_empty() or not (usage & PROPERTY_USAGE_STORAGE) or name in ["resource_local_to_scene", "resource_name", "resource_path", "script"]:
			continue
		var value = resource.get(name)
		if value is Resource:
			var nested := value as Resource
			if not nested.resource_path.is_empty():
				signature[name] = {"class": nested.get_class(), "path": nested.resource_path}
			elif depth < 3:
				signature[name] = _resource_signature(nested, visited, depth + 1)
			else:
				signature[name] = {"class": nested.get_class(), "depth_limit": true}
		else:
			signature[name] = var_to_str(value)
	visited.erase(instance_id)
	return signature
