extends SceneTree
# ART-AUTOSHADE-spec verification gate. Two checks:
#
#   1. Dimensions preserved: every .png that the batch pass targeted
#      (assets/items/, assets/environment/ recursive, assets/characters/,
#      assets/particles/) still loads and still has the same w x h as
#      recorded in the pre-pass manifest
#      (assets/.pre_pass_alpha_snapshot.json, written by
#      tools/auto_shade.py before any modification). assets/ui/ and
#      assets/tilesets/ are intentionally NOT in the manifest — tilesets
#      are excluded from the batch pass entirely (see auto_shade.py's
#      BUGFIX comment on BATCH_DIRS: a single directional highlight/
#      shadow blob reads as a repeating "spotlight" artifact once a
#      texture actually tiles across the map).
#
#   2. Alpha invariant: for the same 5-6 spot-check files, every
#      pre-pass alpha==0 pixel is STILL alpha==0 post-pass. The
#      project has shipped an alpha-destroying bug class once already
#      (see tools/gen_rival_portraits.py), so this is the single most
#      important regression guard.
#
# If the manifest is missing, this test SKIPS itself (rather than
# failing) — the batch pass and its test are intended to run together,
# but a partial checkout (manifest absent) shouldn't break unrelated
# CI runs.

const SNAPSHOT_PATH := "res://assets/.pre_pass_alpha_snapshot.json"

# The 4 in-scope batch directories — the manifest keys all live under
# one of these. assets/ui/ and assets/tilesets/ are deliberately
# excluded (ui: the spec says never touch it; tilesets: tileable ground
# textures need a different, seam-safe technique — see auto_shade.py).
const SCAN_ROOTS := [
	"res://assets/items",
	"res://assets/environment",
	"res://assets/characters",
	"res://assets/particles",
]

# A handful of representative spot-checks, one per category where
# possible. Each entry is a (relative_path_under_repo, must_be_above)
# tuple. "must_be_above" is the lower-bound on the post-pass opaque
# color count — proves the pass actually ran (a no-op would leave the
# count at its pre-pass value).
#
# BUGFIX (Code Quality Review): this was originally a single hardcoded
# `n > 8` check for every entry, which fails for small/tiny assets —
# the _TINY_REGION_AREA_PX fix in auto_shade.py (base+highlight only,
# no shadow, for regions under 16px) deliberately produces a SMALLER
# color-count increase for tiny sprites (a 1-pixel particle dot or a
# 9-pixel crop sprout was never going to reach 8+ colors, and forcing
# it to would mean re-introducing the very bug the fix corrects — full
# base-color loss on tiny regions). Each entry now has its own
# realistic per-file threshold instead, set just above that file's
# actual pre-pass color count (proving the pass ran) rather than an
# arbitrary size-blind absolute number.
const SPOT_CHECKS := [
	["assets/items/banana.png",                3],   # 2 colors pre-pass -> 5 post
	["assets/items/rice_grain.png",             5],   # 4 colors pre-pass -> 8 post
	["assets/characters/npc_elder_idle_01.png", 10],  # 8 colors pre-pass -> 22 post
	["assets/environment/dock.png",             4],   # 2 colors pre-pass -> 10 post
	["assets/environment/crops/cabbage_stage1.png", 2],  # 2 colors pre-pass -> 3 post (tiny sprout)
	["assets/particles/smoke_puff.png",         1],   # 1 color pre-pass -> 3 post (tiny particle)
]

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  asset-shading :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  asset-shading :: %s" % label)

func _walk_pngs(roots: Array) -> Array:
	# Returns Array[String] of res:// paths.
	var out: Array = []
	for root_v in roots:
		var root: String = root_v
		var dir: DirAccess = DirAccess.open(root)
		if dir == null:
			continue
		dir.list_dir_begin()
		var name: String = dir.get_next()
		while name != "":
			if name == "." or name == "..":
				name = dir.get_next()
				continue
			var full: String = root + "/" + name
			if dir.current_is_dir():
				out.append_array(_walk_pngs([full]))
			elif name.ends_with(".png") and not name.ends_with(".png.import"):
				out.append(full)
			name = dir.get_next()
	return out

func _load_image(path: String) -> Image:
	# Image.load() returns null on failure (e.g. corrupt file). We
	# surface that as an empty Image so the caller can assert on size.
	var im: Image = Image.new()
	var loaded: Error = im.load(path)
	if loaded != OK:
		return Image.new()
	return im

func _count_opaque_colors(im: Image) -> int:
	# Replicates the PIL .getcolors(maxcolors=w*h) count used by the
	# spec's pre-pass audit, filtering entries by alpha > 0. (PIL
	# uses a single-pass getcolors for performance — Godot's
	# get_region / get_pixel is the equivalent, just slower; for
	# these small assets, this loop is fast enough.)
	var w: int = im.get_width()
	var h: int = im.get_height()
	var seen: Dictionary = {}
	for y in range(h):
		for x in range(w):
			var c: Color = im.get_pixel(x, y)
			if c.a <= 0.0:
				continue
			# Quantize to 8-bit per channel so two slightly-different
			# encoding paths of the same color collapse to one key.
			var key: String = "%d,%d,%d" % [int(round(c.r * 255.0)),
			                                int(round(c.g * 255.0)),
			                                int(round(c.b * 255.0))]
			seen[key] = true
	return seen.size()

func _initialize() -> void:
	# If the snapshot doesn't exist, the batch pass hasn't run yet.
	# Skip rather than fail so a fresh checkout doesn't break CI.
	if not FileAccess.file_exists(SNAPSHOT_PATH):
		print("== ASSET-SHADING TESTS: skipped (no %s — run tools/auto_shade.py first) ==" % SNAPSHOT_PATH)
		quit(0)
		return

	# ---- 1. Load the manifest
	var f: FileAccess = FileAccess.open(SNAPSHOT_PATH, FileAccess.READ)
	if f == null:
		print("  FAIL  asset-shading :: cannot read snapshot at %s" % SNAPSHOT_PATH)
		print("== ASSET-SHADING TESTS: 0 passed, 1 failed ==")
		quit(1)
		return
	var manifest_text: String = f.get_as_text()
	f.close()
	var manifest: Dictionary = JSON.parse_string(manifest_text)
	if typeof(manifest) != TYPE_DICTIONARY:
		print("  FAIL  asset-shading :: manifest is not a JSON object")
		print("== ASSET-SHADING TESTS: 0 passed, 1 failed ==")
		quit(1)
		return

	# ---- 2. Dimensions preserved for every file in the manifest
	var expected_paths: Array = manifest.keys()
	expected_paths.sort()
	_check(expected_paths.size() > 0, "manifest has %d entries" % expected_paths.size())
	var dim_failures: int = 0
	for rel_v in expected_paths:
		var rel: String = rel_v
		var meta: Dictionary = manifest[rel]
		var expected_w: int = int(meta["w"])
		var expected_h: int = int(meta["h"])
		var full: String = "res://" + rel
		var im: Image = _load_image(full)
		if im.is_empty():
			dim_failures += 1
			print("    (load failed for %s)" % rel)
			continue
		if im.get_width() != expected_w or im.get_height() != expected_h:
			dim_failures += 1
			print("    (dim mismatch for %s: %dx%d != %dx%d)" %
				[rel, im.get_width(), im.get_height(), expected_w, expected_h])
	_check(dim_failures == 0, "all %d files load and match pre-pass dimensions (failures: %d)" % [expected_paths.size(), dim_failures])

	# ---- 3. Spot-check: post-pass opaque color count exceeds each
	#         entry's own pre-pass baseline (see SPOT_CHECKS above), AND
	#         the file still loads. Proves the pass actually ran, not
	#         just a no-op that preserved dimensions.
	for entry in SPOT_CHECKS:
		var rel: String = entry[0]
		var must_be_above: int = entry[1]
		var full: String = "res://" + rel
		var im: Image = _load_image(full)
		if im.is_empty():
			_check(false, "spot-check %s loads" % rel)
			continue
		var n: int = _count_opaque_colors(im)
		_check(n > must_be_above, "spot-check %s has > %d opaque colors (got %d)" % [rel, must_be_above, n])

	# ---- 4. Alpha invariant: every pre-pass alpha==0 pixel is STILL
	#         alpha==0 post-pass. Compare against the snapshot's
	#         base64-encoded alpha channel. This is the single most
	#         important regression guard given the alpha-destroying
	#         bug class already shipped once in this project.
	for entry in SPOT_CHECKS:
		var rel: String = entry[0]
		var meta: Dictionary = manifest.get(rel, {})
		if meta.is_empty():
			_check(false, "alpha invariant %s — not in manifest" % rel)
			continue
		var expected_alpha_b64: String = meta["alpha"]
		var expected_w: int = int(meta["w"])
		var expected_h: int = int(meta["h"])
		var full: String = "res://" + rel
		var im: Image = _load_image(full)
		if im.is_empty() or im.get_width() != expected_w or im.get_height() != expected_h:
			_check(false, "alpha invariant %s — cannot load or wrong size" % rel)
			continue
		# Reconstruct the post-pass alpha sequence as a packed String
		# of bytes (we compare against expected via length + each
		# index, since GDScript String is already a byte sequence).
		var transparent_mismatches: int = 0
		var total_transparent: int = 0
		# Decode the base64 alpha bytes into a PackedByteArray.
		var expected_bytes: PackedByteArray = Marshalls.base64_to_raw(expected_alpha_b64)
		var idx: int = 0
		for y in range(expected_h):
			for x in range(expected_w):
				var exp_a: int = expected_bytes[idx]
				idx += 1
				if exp_a == 0:
					total_transparent += 1
					var c: Color = im.get_pixel(x, y)
					if c.a > 0.0:
						transparent_mismatches += 1
		_check(transparent_mismatches == 0,
			"alpha invariant %s — all %d pre-pass-transparent pixels still transparent (mismatches: %d)" %
				[rel, total_transparent, transparent_mismatches])

	print("\n=== ASSET-SHADING TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("ASSET-SHADING GATE FAILED")
	quit(1 if _failed > 0 else 0)
