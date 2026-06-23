extends "res://src/ui/screen_base.gd"
## 調理によるレベルアップ祝福演出オーバーレイ。
#  - JRPGDialog 枠（深底＋金縁）を画面中央に表示
#  - Lv.X → Lv.Y、能力上昇、ぬし解放を伝える
#  - 表示時に scale-punch（TRANS_BACK）＋画面揺れ＋ヒットストップ
#  - OK で縮小フェードして閉じる（closed シグナル発火 → queue_free）
# screen_base の make_label/make_shadow_label/make_button/_wire_button_juice を再利用し、
# 他画面と見た目を統一。配色は Palette に依存（dialog 枠は深底なので文字は明色）。
signal closed

var _dialog: PanelContainer
var _subtitle: Label
var _gains: Label
var _boss: Label


func _build_screen() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP   # 下層の操作をブロック（祝福中は誤操作防止）

	# 背景を半透明で暗化し、演出に視線を集める
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_dialog = PanelContainer.new()
	_dialog.theme_type_variation = "JRPGDialog"
	_dialog.custom_minimum_size = Vector2(540.0, 0.0)
	center.add_child(_dialog)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	_dialog.add_child(box)

	var title := make_shadow_label("LEVEL UP！", 44, Palette.GOLD_BRIGHT, 5)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	_subtitle = make_label("", 30, Palette.TEXT_BONE, 3)
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_subtitle)

	box.add_child(_spacer(6.0))

	_gains = make_label("", 21, Color("#cfe4f3"), 2)
	_gains.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gains.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_gains)

	_boss = make_label("", 23, Palette.GAUGE_RED_HI, 3)
	_boss.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_boss)

	box.add_child(_spacer(10.0))

	var ok := make_button("OK", _close, 240.0, true)
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(ok)


func _spacer(height: float) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, height)
	return spacer


func show_level_up(
	level_from: int, level_to: int, old_stats: Dictionary, new_stats: Dictionary
) -> void:
	_subtitle.text = "Lv.%d   →   Lv.%d" % [level_from, level_to]
	_gains.text = _build_gains_text(old_stats, new_stats)
	var boss_unlocked := (
		level_from < GameData.BOSS_UNLOCK_LEVEL and level_to >= GameData.BOSS_UNLOCK_LEVEL
	)
	_boss.text = "★ 港のぬしに挑戦できるようになった！" if boss_unlocked else ""
	_boss.visible = boss_unlocked
	_present()


func _build_gains_text(old_stats: Dictionary, new_stats: Dictionary) -> String:
	var lines: Array[String] = []
	var d_energy := int(
		round(float(new_stats.get("max_energy", 0)) - float(old_stats.get("max_energy", 0)))
	)
	var d_reel := float(new_stats.get("reel_power", 0)) - float(old_stats.get("reel_power", 0))
	var d_tech := int(new_stats.get("technique", 0)) - int(old_stats.get("technique", 0))
	var d_focus := int(new_stats.get("focus", 0)) - int(old_stats.get("focus", 0))
	if d_energy != 0:
		lines.append("最大体力　+%d" % d_energy)
	if d_reel > 0.01:
		lines.append("巻力　+%.1f" % d_reel)
	if d_tech != 0:
		lines.append("技量　+%d" % d_tech)
	if d_focus != 0:
		lines.append("集中力　+%d" % d_focus)
	if lines.is_empty():
		return ""
	return "能力が上がった！\n" + "\n".join(PackedStringArray(lines))


func _present() -> void:
	_dialog.modulate.a = 0.0
	_dialog.scale = Vector2(0.82, 0.82)
	# レイアウト確定後に中心へ pivot を合わせる（scale が中心基準で膨らむ）
	await get_tree().process_frame
	_dialog.pivot_offset = _dialog.size * 0.5
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property(_dialog, "scale", Vector2.ONE, 0.34)
	tw.parallel().tween_property(_dialog, "modulate:a", 1.0, 0.18)
	Juicer.add_trauma(0.4)
	Juicer.hit_stop(0.05)


func _close() -> void:
	closed.emit()
	_dialog.pivot_offset = _dialog.size * 0.5
	var tw := create_tween()
	tw.set_ease(Tween.EASE_IN)
	tw.set_trans(Tween.TRANS_QUAD)
	tw.tween_property(_dialog, "scale", Vector2(0.86, 0.86), 0.16)
	tw.parallel().tween_property(_dialog, "modulate:a", 0.0, 0.16)
	tw.tween_callback(queue_free)
