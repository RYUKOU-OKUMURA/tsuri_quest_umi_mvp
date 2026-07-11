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


static func has_distinct_focus_style(control: Control) -> bool:
	if not control.has_theme_stylebox("focus"):
		return false
	var focus := control.get_theme_stylebox("focus")
	if focus == null:
		return false
	for state in ["normal", "hover", "pressed"]:
		if control.has_theme_stylebox(state) and focus == control.get_theme_stylebox(state):
			return false
	return true

