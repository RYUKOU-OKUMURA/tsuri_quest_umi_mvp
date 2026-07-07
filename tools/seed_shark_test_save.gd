extends Node
## サメ釣り・生簀QA用: スロット2へ Lv50 カンスト状態のセーブを書き込む。
## 本番 user:// へ書くため、必ず tools/seed_shark_test_save.sh 経由で実行すること。

const TARGET_SLOT := 2
const BAIT_FISH_STACK := 99


func _ready() -> void:
	if OS.get_environment("TSURI_SEED_SHARK_TEST_SAVE_ALLOW") != "1":
		push_error(
			"seed_shark_test_save は slot %d へ書き込みます。"
			% TARGET_SLOT
			+ " tools/seed_shark_test_save.sh から実行してください。"
		)
		get_tree().quit(1)
		return

	# tools/ 配下起動はサンドボックスになるため、明示的に解除する
	PlayerProgress._sandbox_mode = false
	PlayerProgress.set_active_save_slot(TARGET_SLOT, false)
	_apply_seed_state()
	PlayerProgress.save_game()

	var save_path := ProjectSettings.globalize_path(PlayerProgress.current_save_path())
	var access := PlayerProgress.fishing_spot_access_status("danger_reef")
	if not bool(access.get("ok", false)):
		push_error(
			"危険海域が解放されていません: %s"
			% String(access.get("message", access.get("reason", "unknown")))
		)
		get_tree().quit(1)
		return
	if PlayerProgress.level != GameData.MAX_LEVEL:
		push_error("レベルがカンスト(%d)ではありません: %d" % [GameData.MAX_LEVEL, PlayerProgress.level])
		get_tree().quit(1)
		return
	if not GameData.is_megalodon_unlocked(PlayerProgress.level, PlayerProgress.shark_bonds):
		push_error("メガロドン解放条件を満たしていません。")
		get_tree().quit(1)
		return
	for shark_id in GameData.get_raiseable_shark_ids():
		if not _has_favorite_food_in_inventory(shark_id):
			push_error("好物の餌が不足しています: %s" % shark_id)
			get_tree().quit(1)
			return

	print("seed_shark_test_save: ok")
	print("  slot: %d" % TARGET_SLOT)
	print("  path: %s" % save_path)
	print("  level: %d (MAX)" % PlayerProgress.level)
	print("  boats: %s" % ", ".join(PlayerProgress.owned_boats))
	print("  sea_chart_fragments: %d/3" % PlayerProgress.sea_chart_fragments)
	print("  equipped_rod: %s" % PlayerProgress.equipped_rod_id)
	print("  equipped_rig: %s" % PlayerProgress.equipped_rig_id)
	print("  owned_rigs: %s" % ", ".join(PlayerProgress.owned_rigs))
	print("  shark_bonds: %d/10 at 100" % _max_bond_count())
	print("  raiseable_sharks_caught: %d/10" % _raiseable_shark_caught_count())
	print("  bait_fish: %s" % _inventory_summary())
	print("  favorite_food_coverage: %s" % _favorite_food_coverage_summary())
	print("")
	print("ゲームを起動し、スロット%dを選んで確認してください。" % TARGET_SLOT)
	print("- 危険海域・鮫の根: ホオジロザメ / ヌシ / メガロドン抽選")
	print("- 港 → サメの生簀: 全10種・なつき度100")
	print("港の出港準備で餌魚を選んでから出航してください。")
	print("仕掛けの目安: nomase=小魚 / chokusen=イソメ / kani=岩ガニ（タックル屋で切替）")
	print("餌魚の目安: キハダ=大型サメ好物 / ヌシ級=メガロドン / アジ=汎用小魚")
	get_tree().quit(0)


func _apply_seed_state() -> void:
	PlayerProgress.level = GameData.MAX_LEVEL
	PlayerProgress.exp = 0
	PlayerProgress.money = 999999
	PlayerProgress.inventory = _max_bait_inventory()
	PlayerProgress.caught_counts = _max_raiseable_shark_caught_counts()
	PlayerProgress.spot_caught_counts = {}
	PlayerProgress.best_sizes = _max_shark_best_sizes()
	PlayerProgress.eaten_recipes = {}
	PlayerProgress.owned_rods = ["starter", "iso", "offshore", "big_game", "marlin"]
	PlayerProgress.equipped_rod_id = "marlin"
	PlayerProgress.owned_rigs = ["sabiki", "uki", "chokusen", "nomase", "jigging", "kani", "shokunin"]
	PlayerProgress.equipped_rig_id = "nomase"
	PlayerProgress.owned_boats = ["skiff", "offshore_boat", "bluewater_boat"]
	PlayerProgress.pending_buff = {}
	PlayerProgress.play_seconds = 36000.0
	PlayerProgress.quest_board = []
	PlayerProgress.quest_completed_count = 10
	PlayerProgress.sea_chart_fragments = PlayerProgress.SEA_CHART_FRAGMENT_MAX
	PlayerProgress.shark_bonds = _max_shark_bonds()


func _max_bait_inventory() -> Dictionary:
	var inventory := {}
	for fish_id in GameData.get_all_fish_ids():
		var fish := GameData.get_fish(fish_id)
		if fish.is_empty() or bool(fish.get("shark", false)):
			continue
		inventory[fish_id] = BAIT_FISH_STACK
	return inventory


func _favorite_food_coverage_summary() -> String:
	var covered := 0
	for shark_id in GameData.get_raiseable_shark_ids():
		if _has_favorite_food_in_inventory(shark_id):
			covered += 1
	return "%d/10 sharks have favorite bait in inventory" % covered


func _has_favorite_food_in_inventory(shark_id: String) -> bool:
	for fish_id_variant in PlayerProgress.inventory.keys():
		var fish_id := String(fish_id_variant)
		if PlayerProgress.fish_count(fish_id) <= 0:
			continue
		var fish := GameData.get_fish(fish_id)
		if fish.is_empty() or bool(fish.get("shark", false)):
			continue
		if GameData.is_favorite_food(shark_id, fish):
			return true
	return false


func _max_shark_bonds() -> Dictionary:
	var bonds := {}
	for shark_id in GameData.get_raiseable_shark_ids():
		bonds[shark_id] = 100
	return bonds


func _max_raiseable_shark_caught_counts() -> Dictionary:
	var counts := {}
	for shark_id in GameData.get_raiseable_shark_ids():
		counts[shark_id] = 1
	return counts


func _max_shark_best_sizes() -> Dictionary:
	var sizes := {}
	for shark_id in GameData.get_raiseable_shark_ids():
		var fish := GameData.get_fish(shark_id)
		if fish.is_empty():
			continue
		sizes[shark_id] = float(fish.get("size_max", 100.0))
	return sizes


func _max_bond_count() -> int:
	var count := 0
	for shark_id in GameData.get_raiseable_shark_ids():
		if int(PlayerProgress.shark_bonds.get(shark_id, 0)) >= 100:
			count += 1
	return count


func _raiseable_shark_caught_count() -> int:
	var count := 0
	for shark_id in GameData.get_raiseable_shark_ids():
		if int(PlayerProgress.caught_counts.get(shark_id, 0)) > 0:
			count += 1
	return count


func _inventory_summary() -> String:
	var kind_count := 0
	var total_count := 0
	for fish_id_variant in PlayerProgress.inventory.keys():
		var count := PlayerProgress.fish_count(String(fish_id_variant))
		if count <= 0:
			continue
		kind_count += 1
		total_count += count
	if kind_count == 0:
		return "none"
	return "%d種・合計%d匹（各%d匹）" % [kind_count, total_count, BAIT_FISH_STACK]
