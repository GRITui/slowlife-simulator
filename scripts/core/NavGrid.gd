class_name NavGrid
extends RefCounted
# NavGrid — A* pathfinding scaffold over the world's 20x16 cell grid.
# Engine-layer utility (owner @spatial-physics): decoupled from any scene —
# callers supply a walkability predicate (e.g. combining GridManager bounds
# with WorldRender ground-tile water checks) so this stays independent of
# the content squad's WorldRender.gd / Main.tscn.

const WATER_TILES := ["water_lotuspond", "deep_pond", "canal"]

var _astar: AStarGrid2D
var grid_size: Vector2i
var cell_size: int

func setup(p_grid_size: Vector2i, p_cell_size: int, is_walkable: Callable) -> void:
	grid_size = p_grid_size
	cell_size = p_cell_size
	_astar = AStarGrid2D.new()
	_astar.region = Rect2i(Vector2i.ZERO, grid_size)
	_astar.cell_size = Vector2(cell_size, cell_size)
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	_astar.update()
	for y in grid_size.y:
		for x in grid_size.x:
			var cell := Vector2i(x, y)
			_astar.set_point_solid(cell, not is_walkable.call(cell))

## Convenience predicate: blocked if out of bounds, a maze cell, or a water/canal ground tile.
static func default_walkable(cell: Vector2i, grid_size: Vector2i, maze_origin: Vector2i, ground_tile_name: String) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= grid_size.x or cell.y >= grid_size.y:
		return false
	if cell.x >= maze_origin.x and cell.x < maze_origin.x + 3 and cell.y >= maze_origin.y and cell.y < maze_origin.y + 3:
		return false
	return ground_tile_name not in WATER_TILES

func is_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < grid_size.x and cell.y < grid_size.y

func is_walkable(cell: Vector2i) -> bool:
	if not is_in_bounds(cell):
		return false
	return not _astar.is_point_solid(cell)

## Returns the cell-path (inclusive of from/to) or an empty array if unreachable
## or either endpoint is solid/out of bounds.
func find_path(from_cell: Vector2i, to_cell: Vector2i) -> Array:
	if not is_in_bounds(from_cell) or not is_in_bounds(to_cell):
		return []
	if _astar.is_point_solid(from_cell) or _astar.is_point_solid(to_cell):
		return []
	var world_path: PackedVector2Array = _astar.get_point_path(from_cell, to_cell)
	if world_path.is_empty():
		return []
	var cells: Array = []
	for p in world_path:
		cells.append(Vector2i(int(p.x / cell_size), int(p.y / cell_size)))
	return cells
