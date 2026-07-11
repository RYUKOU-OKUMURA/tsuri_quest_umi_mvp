extends Node

const TitlePreview = preload("res://tools/title_preview.gd")


func _ready() -> void:
	var accepted := [
		"/tmp/tsuri_title_preview_guard/Library/Application Support/tsuri_quest_umi",
		"/private/tmp/tsuri_title_preview_guard/Library/Application Support/tsuri_quest_umi",
	]
	var rejected := [
		"",
		"/",
		"/Users/example/Library/Application Support/tsuri_quest_umi",
		"/tmp/not_title_preview/Library/Application Support/tsuri_quest_umi",
		"/tmp/tsuri_title_../Users/example",
	]
	for path in accepted:
		if not TitlePreview.is_mutation_root_allowed(path, "1"):
			push_error("安全なpreview mutation rootが拒否されました: %s" % path)
			get_tree().quit(1)
			return
	for path in rejected:
		if TitlePreview.is_mutation_root_allowed(path, "1"):
			push_error("危険なpreview mutation rootが許可されました: %s" % path)
			get_tree().quit(1)
			return
	if TitlePreview.is_mutation_root_allowed(accepted[0], ""):
		push_error("mutation sentinel欠損が許可されました。")
		get_tree().quit(1)
		return
	print("title_preview_guard_smoke: ok")
	get_tree().quit(0)
