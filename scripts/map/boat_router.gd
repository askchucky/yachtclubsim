class_name BoatRouter
extends RefCounted

## A* over channel / open water from slip to map edge.


static func neighbors(p: Vector2i) -> Array[Vector2i]:
	return [Vector2i(p.x + 1, p.y), Vector2i(p.x - 1, p.y), Vector2i(p.x, p.y + 1), Vector2i(p.x, p.y - 1)]


static func path_to_edge(grid: HarborGrid, start: Vector2i) -> Array[Vector2i]:
	var reach := grid.channel_reaches_edge()
	var mask: PackedByteArray = reach["mask"]
	if not grid.in_bounds(start.x, start.y):
		return []
	## find nearest navigable neighbor to start (slip itself may not be nav)
	var origin := start
	var found_origin := false
	for n in neighbors(start):
		if grid.in_bounds(n.x, n.y) and mask[grid.idx(n.x, n.y)] == 1:
			origin = n
			found_origin = true
			break
	if not found_origin:
		return []
	## goal: any edge navigable tile
	var goals: Dictionary = {}
	for x in grid.w:
		if mask[grid.idx(x, 0)] == 1:
			goals[Vector2i(x, 0)] = true
		if mask[grid.idx(x, grid.h - 1)] == 1:
			goals[Vector2i(x, grid.h - 1)] = true
	for y in grid.h:
		if mask[grid.idx(0, y)] == 1:
			goals[Vector2i(0, y)] = true
		if mask[grid.idx(grid.w - 1, y)] == 1:
			goals[Vector2i(grid.w - 1, y)] = true
	if goals.is_empty():
		return []
	return _astar(grid, mask, origin, goals)


static func _astar(grid: HarborGrid, mask: PackedByteArray, start: Vector2i, goals: Dictionary) -> Array[Vector2i]:
	var open: Array[Vector2i] = [start]
	var came: Dictionary = {}
	var gscore: Dictionary = {start: 0}
	var fscore: Dictionary = {start: _h(start, goals)}
	var closed: Dictionary = {}
	var guard := 0
	while not open.is_empty() and guard < 8000:
		guard += 1
		var cur := _lowest(open, fscore)
		if goals.has(cur):
			return _reconstruct(came, cur)
		open.erase(cur)
		closed[cur] = true
		for n in neighbors(cur):
			if not grid.in_bounds(n.x, n.y):
				continue
			if mask[grid.idx(n.x, n.y)] != 1:
				continue
			if closed.has(n):
				continue
			var tent: int = int(gscore[cur]) + 1
			if not gscore.has(n) or tent < int(gscore[n]):
				came[n] = cur
				gscore[n] = tent
				fscore[n] = tent + _h(n, goals)
				if not open.has(n):
					open.append(n)
	return []


static func _h(p: Vector2i, goals: Dictionary) -> int:
	var best := 99999
	for g in goals.keys():
		var d: Vector2i = g
		best = mini(best, absi(p.x - d.x) + absi(p.y - d.y))
	return best


static func _lowest(open: Array[Vector2i], fscore: Dictionary) -> Vector2i:
	var best: Vector2i = open[0]
	var best_f := int(fscore.get(best, 999999))
	for p in open:
		var f := int(fscore.get(p, 999999))
		if f < best_f:
			best = p
			best_f = f
	return best


static func _reconstruct(came: Dictionary, cur: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = [cur]
	while came.has(cur):
		cur = came[cur]
		path.push_front(cur)
	return path
