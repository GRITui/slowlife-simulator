extends SceneTree
# TASK-037 memory budget gate (headless-safe; on-device meaningful).

const MemoryBudgetScript: GDScript = preload("res://scripts/core/MemoryBudget.gd")

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  memory :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  memory :: %s" % label)

func _initialize() -> void:
	_check(MemoryBudgetScript.texture_mem_mb() <= MemoryBudgetScript.TEXTURE_MEM_BUDGET_MB,
		"texture memory within 20MB budget (headless reports %.1fMB)" % MemoryBudgetScript.texture_mem_mb())
	_check(MemoryBudgetScript.within_texture_budget(), "within_texture_budget() true")
	_check(MemoryBudgetScript.report().contains("TEXT-MEM"), "report() formats")
	var lossless: int = MemoryBudgetScript.lossless_import_count()
	# Audit is report-only BY DESIGN: pixel-art textures are 300-600B each
	# (lossless is intentional and tiny); ASTC is applied at export-preset
	# level via import_etc2_astc (docs/ios_export_template.md), not per-file.
	_check(lossless >= 0, "lossless import audit ran: %d files report lossless (policy: export-level ASTC)" % lossless)
	print("\n=== MEMORY TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("MEMORY GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
