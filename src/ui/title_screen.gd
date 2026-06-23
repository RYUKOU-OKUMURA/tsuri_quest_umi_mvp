extends "res://src/ui/screen_base.gd"

var _confirm_reset: ConfirmationDialog


func _build_screen() -> void:
	add_sea_background()
	add_child(add_sparkles(26))
	var root := make_root_margin(34)
	var layout := VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 22)
	root.add_child(layout)

	var title_panel := make_panel(true)
	title_panel.custom_minimum_size = Vector2(780, 260)
	layout.add_child(title_panel)
	var title_box := VBoxContainer.new()
	title_box.alignment = BoxContainer.ALIGNMENT_CENTER
	title_box.add_theme_constant_override("separation", 12)
	title_panel.add_child(title_box)

	var title := make_label("釣りクエスト", 58, Color("#ffe4a3"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_box.add_child(title)
	var subtitle := make_label("〜 海釣り編 〜", 32, Color("#9ad8f5"))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_box.add_child(subtitle)
	var concept := make_label("釣る。料理する。食べて強くなる。", 21, Color("#e6f2f8"))
	concept.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_box.add_child(concept)

	var menu_panel := make_panel()
	menu_panel.custom_minimum_size = Vector2(520, 0)
	menu_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	layout.add_child(menu_panel)
	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	menu_panel.add_child(buttons)

	var continue_button := make_button("つづきから", func() -> void: navigate("harbor"), 430)
	continue_button.disabled = not PlayerProgress.has_save_file()
	buttons.add_child(continue_button)

	var new_text := "最初から" if PlayerProgress.has_save_file() else "ゲームを始める"
	buttons.add_child(make_button(new_text, _on_new_game_pressed, 430))
	var readme_button := make_button("仕様書・操作は README.md を参照", func() -> void: pass, 430)
	readme_button.disabled = true
	buttons.add_child(readme_button)

	var version_label := make_label("MVP Prototype v0.1 / Godot 4.7", 15, Color("#8faec4"))
	version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(version_label)

	_confirm_reset = ConfirmationDialog.new()
	_confirm_reset.title = "セーブデータの初期化"
	_confirm_reset.dialog_text = "現在の進行を消して、最初から始めます。よろしいですか？"
	_confirm_reset.ok_button_text = "最初から始める"
	_confirm_reset.cancel_button_text = "キャンセル"
	_confirm_reset.confirmed.connect(_start_new_game)
	add_child(_confirm_reset)


func _on_new_game_pressed() -> void:
	if PlayerProgress.has_save_file():
		_confirm_reset.popup_centered(Vector2i(620, 220))
	else:
		_start_new_game()


func _start_new_game() -> void:
	PlayerProgress.reset_game()
	navigate("harbor")
