extends RefCounted
class_name MemoryBudget
## TASK-037 — mobile memory budget enforcement (TASK-031 budget table).
## Headless-safe: RenderingServer reports 0 in dummy renderer, so the gate
## check is structural here and meaningful on device / --profiler runs.

const TEXTURE_MEM_BUDGET_MB: float = 20.0
const PARTICLE_MEM_BUDGET_MB: float = 1.0

static func texture_mem_mb() -> float:
	return RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED) / 1048576.0

static func within_texture_budget() -> bool:
	return texture_mem_mb() <= TEXTURE_MEM_BUDGET_MB

static func report() -> String:
	return "TEXT-MEM %.1f/%.0fMB" % [texture_mem_mb(), TEXTURE_MEM_BUDGET_MB]

## ASTC audit helper — counts textures still shipping lossless (compress/mode=0)
## among gameplay art dirs. Report-only for now (enforcement is a follow-up:
## flipping 90+ .import files churns every texture and needs device QA).
static func lossless_import_count() -> int:
	var count: int = 0
	for dir_path in ["res://assets/tilesets", "res://assets/environment", "res://assets/characters", "res://assets/items", "res://assets/ui"]:
		var dir: DirAccess = DirAccess.open(dir_path)
		if dir == null:
			continue
		dir.list_dir_begin()
		var fname: String = dir.get_next()
		while fname != "":
			if fname.ends_with(".png.import"):
				var f: FileAccess = FileAccess.open(dir_path + "/" + fname, FileAccess.READ)
				if f != null and "compress/mode=0" in f.get_as_text():
					count += 1
			fname = dir.get_next()
	return count
