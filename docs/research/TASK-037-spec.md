# TASK-037 - MemoryBudget.gd autoload + ASTC import audit

**Status:** `proposed` | **Priority:** high | **Category:** perf | **Owner:** @engine-inspector
**Renderer:** `gl_compatibility` (iOS A14+, Metal). Budget source: **TASK-031 — ≤ 20 MB total texture**.
**Files (new):** `scripts/autoload/MemoryBudget.gd`, `tests/perf/test_memory_budget.gd`
**Files (config):** `project.godot` (autoload + 1 key), `assets/**/*.import` (mass-edit)
**Constraints:** strict-typed, SignalBus-only communication, debug-only runtime, zero-combat.
## Audit findings
94 PNGs under `assets/`; every `.import` = `compress/mode=0` Lossless + `compress/uastc_level=0` + `mipmaps/generate=false` → PNG-decoded, no GPU compression. `project.godot` lacks `textures/vram_compression/import_etc2_astc=true` (TODO `docs/ios_export_template.md:18`). `ProfilerOverlay.gd` L22 prints `OS.get_static_memory_usage()` only (heap, not VRAM). 76× bamboo ring + 23 PROPS + tileset ≈ 16 MB PNG-decoded → **breach likely before any mipmap**.
## Spec
**1. `scripts/autoload/MemoryBudget.gd`** (strict-typed, early-return in release):
```gdscript
extends Node
const BUDGET_MB: float = 20.0
signal breached(mb: float, paths: PackedStringArray)
signal report_ready(mb: float, count: int)
var _bytes: int = 0
var _paths: PackedStringArray = PackedStringArray()
func _ready() -> void:
    if not OS.is_debug_build() and not "--memory-check" in OS.get_cmdline_user_args(): return
    _scan(DirAccess.open("res://assets/"))
    var mb: float = _bytes / 1048576.0
    report_ready.emit(mb, _paths.size())
    if mb > BUDGET_MB: breached.emit(mb, _paths)
func _scan(d: DirAccess) -> void:
    if d == null: return
    for f in d.get_files():
        if not f.ends_with(".png.import"): continue
        _bytes += _estimate(d.get_current_dir() + "/" + f); _paths.append(f)
    for sub in d.get_directories(): _scan(DirAccess.open(d.get_current_dir() + "/" + sub))
func _estimate(import_path: String) -> int:
    var img := Image.new()
    if img.load(import_path.trim_suffix(".import")) != OK: return 0
    return img.get_width() * img.get_height() * 4   # ASTC 6×6 upper bound
```
**2. `project.godot` delta:** add `textures/vram_compression/import_etc2_astc=true` + `import_s3tc_bptc=false` under `[rendering]`; register `MemoryBudget="*res://scripts/autoload/MemoryBudget.gd"` in `[autoload]` between SignalBus and GameData.
**3. ASTC mass-edit (zsh-safe).** Per file set `compress/mode=2`, `mipmaps/generate=true`, `compress/uastc_level=2`:
```bash
for k in 'compress/mode=0:2' 'mipmaps/generate=false:true' 'compress/uastc_level=0:2'; do
  find res://assets -name '*.png.import' -exec sed -i '' "s/^${k%:*}=/${k#*:}=/" {} +
done && godot --headless --import
```
**4. ProfilerOverlay hook** (append to `scripts/core/ProfilerOverlay.gd`):
```gdscript
if autoload := get_node_or_null("/root/MemoryBudget"):
    autoload.breached.connect(func(mb: float, _p: PackedStringArray) -> void:
        if label: label.text += "\nMEM_BUDGET_BREACH:%.1fMB/%.0fMB" % [mb, 20.0])
```

## Gate test strategy (`tests/perf/test_memory_budget.gd`)
1. **Autoload** — `root.get_node_or_null("MemoryBudget") != null`.
2. **Strict typing** — grep `^var [a-z_]\+ =` in `MemoryBudget.gd` returns no untyped decls.
3. **SignalBus contract** — `report_ready` + `breached` are `signal`; no autoload cross-refs.
4. **Budget** — await `report_ready`; assert `mb <= 20.0` after mass-edit (pre-edit baseline prints actual mb).
5. **No combat leak** — assert no method `attack`/`damage`/`combat` in `MemoryBudget.gd`.
## Acceptance
`import_etc2_astc=true` set; ≥90% of `assets/**/*.import` re-baked with `compress/mode=2` + `mipmaps/generate=true`. Gate green on iPhone-12 perf preset (TASK-031) AND new memory gate. Release build (no `--memory-check`) adds **zero** runtime cost.