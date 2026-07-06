extends Node

const AuditTablePrinter = preload("res://tools/audit_table_printer.gd")

const TRIALS := 100000
const EXPECTED_CHANCE := 0.22
const TOLERANCE := 0.005

var _failed := false


func _ready() -> void:
	_check_applicability()
	_check_distribution()
	if _failed:
		get_tree().quit(1)
		return
	print("shark_ambush_audit: ok")
	get_tree().quit(0)


func _check_applicability() -> void:
	var non_shark := GameData.get_fish("kihada")
	var shark := GameData.get_fish("nekozame")
	var nushi := GameData.get_fish("nushi_danger_reef")
	_expect_true(GameData.can_shark_ambush("danger_reef", non_shark), "danger reef non-shark should allow ambush")
	_expect_true(not GameData.can_shark_ambush("deep_ocean", non_shark), "other spots should not allow ambush")
	_expect_true(not GameData.can_shark_ambush("danger_reef", shark), "shark fish should not allow ambush")
	_expect_true(not GameData.can_shark_ambush("danger_reef", nushi), "nushi shark should not allow ambush")


func _check_distribution() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260706
	var hits := 0
	var min_threshold := 999.0
	var max_threshold := -999.0
	var threshold_sum := 0.0
	for _index in range(TRIALS):
		var plan := GameData.shark_ambush_plan(rng.randf(), rng.randf())
		if not bool(plan.get("active", false)):
			continue
		hits += 1
		var threshold := float(plan.get("threshold", 0.0))
		min_threshold = minf(min_threshold, threshold)
		max_threshold = maxf(max_threshold, threshold)
		threshold_sum += threshold
	var rate := float(hits) / float(TRIALS)
	var average_threshold := threshold_sum / float(maxi(1, hits))
	_expect_true(absf(rate - EXPECTED_CHANCE) <= TOLERANCE, "ambush rate out of tolerance: %.4f" % rate)
	_expect_true(min_threshold >= GameData.SHARK_AMBUSH_THRESHOLD_MIN, "ambush threshold below min: %.3f" % min_threshold)
	_expect_true(max_threshold <= GameData.SHARK_AMBUSH_THRESHOLD_MAX, "ambush threshold above max: %.3f" % max_threshold)
	_expect_true(average_threshold >= 0.415 and average_threshold <= 0.435, "ambush threshold average out of range: %.3f" % average_threshold)
	var edge_low := GameData.shark_ambush_plan(-1.0, -1.0)
	var edge_high := GameData.shark_ambush_plan(1.0, 2.0)
	_expect_true(bool(edge_low.get("active", false)), "negative chance should clamp and trigger")
	_expect_true(is_equal_approx(float(edge_low.get("threshold", 0.0)), GameData.SHARK_AMBUSH_THRESHOLD_MIN), "negative threshold should clamp to min")
	_expect_true(not bool(edge_high.get("active", false)), "chance 1.0 should not trigger")
	AuditTablePrinter.print_table(
		"shark_ambush_audit: plan distribution",
		["Trials", "Hits", "Rate", "MinThreshold", "MaxThreshold", "AvgThreshold"],
		[[TRIALS, hits, "%.3f%%" % (rate * 100.0), "%.3f" % min_threshold, "%.3f" % max_threshold, "%.3f" % average_threshold]]
	)


func _expect_true(condition: bool, message: String) -> void:
	if condition or _failed:
		return
	_failed = true
	push_error(message)
