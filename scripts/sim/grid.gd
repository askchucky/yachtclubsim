class_name HarborGrid
extends RefCounted

## Logical harbor grid + placement rules + start maps.

var w: int = SimCatalog.MAP_W
var h: int = SimCatalog.MAP_H
var cells: PackedInt32Array = PackedInt32Array()
var condition: PackedInt32Array = PackedInt32Array() ## 0-100 for pier/slip
var silt: PackedInt32Array = PackedInt32Array() ## channel silt 0-100
var slip_filled: PackedInt32Array = PackedInt32Array() ## 1 if boat in slip
var clubhouse_level: int = 1


func _init() -> void:
	_alloc()


func _alloc() -> void:
	var n := w * h
	cells.resize(n)
	condition.resize(n)
	silt.resize(n)
	slip_filled.resize(n)
	for i in n:
		cells[i] = SimCatalog.CELL_WATER
		condition[i] = 100
		silt[i] = 0
		slip_filled[i] = 0


func idx(x: int, y: int) -> int:
	return y * w + x


func in_bounds(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < w and y < h


func get_cell(x: int, y: int) -> int:
	if not in_bounds(x, y):
		return SimCatalog.CELL_EMPTY
	return cells[idx(x, y)]


func set_cell(x: int, y: int, v: int) -> void:
	if in_bounds(x, y):
		cells[idx(x, y)] = v


func fill_rect(x0: int, y0: int, x1: int, y1: int, v: int) -> void:
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			if in_bounds(x, y):
				set_cell(x, y, v)


func count_cell(kind: int) -> int:
	var n := 0
	for v in cells:
		if v == kind:
			n += 1
	return n


func slip_count() -> int:
	return count_cell(SimCatalog.CELL_SLIP)


func filled_slips() -> int:
	var n := 0
	for i in cells.size():
		if cells[i] == SimCatalog.CELL_SLIP and slip_filled[i] == 1:
			n += 1
	return n


func has_building(kind: int) -> bool:
	return count_cell(kind) > 0


func member_cap() -> int:
	return 200 + (clubhouse_level - 1) * 100


func can_place(tool_id: String, x: int, y: int) -> bool:
	if not in_bounds(x, y):
		return false
	var cur := get_cell(x, y)
	if tool_id == "bulldoze":
		return SimCatalog.is_buildable_overlay(cur) and cur != SimCatalog.CELL_CLUBHOUSE
	var tool := SimCatalog.tool_by_id(tool_id)
	if tool.is_empty():
		return false
	match tool_id:
		"pier":
			return _can_pier(x, y)
		"slip":
			return _can_slip(x, y)
		"breakwater":
			return SimCatalog.is_water(cur) and cur != SimCatalog.CELL_PIER
		"dredge":
			return cur == SimCatalog.CELL_SHALLOW or cur == SimCatalog.CELL_WATER or cur == SimCatalog.CELL_DEEP
		"clubhouse":
			return SimCatalog.is_land(cur) and not has_building(SimCatalog.CELL_CLUBHOUSE)
		"bar", "fuel", "yard", "race", "office":
			return (SimCatalog.is_land(cur) or cur == SimCatalog.CELL_PATH) and not has_building(int(tool["cell"]))
		"path", "tree", "flowers", "lights":
			return SimCatalog.is_land(cur) or cur == SimCatalog.CELL_PATH
	return false


func place(tool_id: String, x: int, y: int) -> bool:
	if not can_place(tool_id, x, y):
		return false
	var i := idx(x, y)
	if tool_id == "bulldoze":
		var was := cells[i]
		if was == SimCatalog.CELL_SLIP:
			slip_filled[i] = 0
		## restore water or sand under overlays on water/land heuristic
		if was == SimCatalog.CELL_PIER or was == SimCatalog.CELL_SLIP or was == SimCatalog.CELL_BREAKWATER:
			cells[i] = SimCatalog.CELL_WATER
		else:
			cells[i] = SimCatalog.CELL_SAND
		condition[i] = 100
		return true
	var tool := SimCatalog.tool_by_id(tool_id)
	var cell := int(tool["cell"])
	cells[i] = cell
	condition[i] = 100
	if tool_id == "dredge":
		silt[i] = 0
	if tool_id == "slip":
		slip_filled[i] = 0
	if tool_id == "clubhouse":
		clubhouse_level = 1
	return true


func _can_pier(x: int, y: int) -> bool:
	var cur := get_cell(x, y)
	if not SimCatalog.is_water(cur) and cur != SimCatalog.CELL_CHANNEL:
		return false
	## must touch shore or another pier
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var n := get_cell(x + d.x, y + d.y)
		if SimCatalog.is_land(n) or n == SimCatalog.CELL_PIER or n == SimCatalog.CELL_CLUBHOUSE or n == SimCatalog.CELL_PATH:
			return true
	return false


func _can_slip(x: int, y: int) -> bool:
	var cur := get_cell(x, y)
	if not SimCatalog.is_water(cur) and cur != SimCatalog.CELL_CHANNEL:
		return false
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if get_cell(x + d.x, y + d.y) == SimCatalog.CELL_PIER:
			return true
	return false


func slip_faces_open_water(x: int, y: int) -> bool:
	## at least one cardinal neighbor is open water/channel (not pier)
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var n := get_cell(x + d.x, y + d.y)
		if SimCatalog.is_water(n) or n == SimCatalog.CELL_CHANNEL:
			return true
	return false


func channel_reaches_edge() -> Dictionary:
	## 1) Channel tiles must reach a map edge (silt can sever this).
	## 2) From those channels, water/deep expand so slips on the fairway are served.
	var channel_seen := PackedByteArray()
	channel_seen.resize(w * h)
	var q: Array[Vector2i] = []
	for x in w:
		_try_enqueue_channel(x, 0, channel_seen, q)
		_try_enqueue_channel(x, h - 1, channel_seen, q)
	for y in h:
		_try_enqueue_channel(0, y, channel_seen, q)
		_try_enqueue_channel(w - 1, y, channel_seen, q)
	var head := 0
	while head < q.size():
		var p: Vector2i = q[head]
		head += 1
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			_try_enqueue_channel(p.x + d.x, p.y + d.y, channel_seen, q)
	var channel_open := false
	for v in channel_seen:
		if v == 1:
			channel_open = true
			break
	var served := channel_seen.duplicate()
	if channel_open:
		var q2: Array[Vector2i] = []
		for i in channel_seen.size():
			if channel_seen[i] == 1:
				q2.append(Vector2i(i % w, int(i / w)))
		head = 0
		while head < q2.size():
			var p2: Vector2i = q2[head]
			head += 1
			for d2 in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx: int = p2.x + d2.x
				var ny: int = p2.y + d2.y
				if not in_bounds(nx, ny):
					continue
				var ii := idx(nx, ny)
				if served[ii] == 1:
					continue
				var c := cells[ii]
				if c == SimCatalog.CELL_WATER or c == SimCatalog.CELL_DEEP or c == SimCatalog.CELL_SHALLOW:
					served[ii] = 1
					q2.append(Vector2i(nx, ny))
	var reachable_slips := 0
	var total_slips := 0
	for y in h:
		for x in w:
			if get_cell(x, y) != SimCatalog.CELL_SLIP:
				continue
			total_slips += 1
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var sx: int = x + d.x
				var sy: int = y + d.y
				if in_bounds(sx, sy) and served[idx(sx, sy)] == 1:
					reachable_slips += 1
					break
	return {
		"open": channel_open and reachable_slips > 0,
		"reachable_slips": reachable_slips,
		"total_slips": total_slips,
		"mask": served,
	}


func _try_enqueue_channel(x: int, y: int, seen: PackedByteArray, q: Array) -> void:
	if not in_bounds(x, y):
		return
	var i := idx(x, y)
	if seen[i] == 1:
		return
	if cells[i] != SimCatalog.CELL_CHANNEL or silt[i] >= 70:
		return
	seen[i] = 1
	q.append(Vector2i(x, y))


func breakwater_cover_at(x: int, y: int) -> float:
	## crude: fraction of breakwater tiles in radius 8 toward open water (south)
	var found := 0
	var checked := 0
	for dy in range(-2, 10):
		for dx in range(-6, 7):
			var nx := x + dx
			var ny := y + dy
			if not in_bounds(nx, ny):
				continue
			checked += 1
			if get_cell(nx, ny) == SimCatalog.CELL_BREAKWATER:
				found += 1
	if checked == 0:
		return 0.0
	return clampf(float(found) / 12.0, 0.0, 1.0)


func earning_slip_count(served: PackedByteArray) -> int:
	var earn := 0
	for y in h:
		for x in w:
			if get_cell(x, y) != SimCatalog.CELL_SLIP:
				continue
			if slip_filled[idx(x, y)] != 1:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx: int = x + d.x
				var ny: int = y + d.y
				if in_bounds(nx, ny) and served[idx(nx, ny)] == 1:
					earn += 1
					break
	return earn


func average_dock_condition() -> float:
	var sum := 0
	var n := 0
	for i in cells.size():
		if cells[i] == SimCatalog.CELL_PIER or cells[i] == SimCatalog.CELL_SLIP:
			sum += condition[i]
			n += 1
	if n == 0:
		return 100.0
	return float(sum) / float(n)


func load_harbor_year() -> void:
	(load("res://scripts/sim/start_maps.gd") as GDScript).new().apply_harbor_year(self)


func load_empty_shore() -> void:
	(load("res://scripts/sim/start_maps.gd") as GDScript).new().apply_empty_shore(self)


func to_dict() -> Dictionary:
	return {
		"w": w,
		"h": h,
		"cells": Array(cells),
		"condition": Array(condition),
		"silt": Array(silt),
		"slip_filled": Array(slip_filled),
		"clubhouse_level": clubhouse_level,
	}


func from_dict(d: Dictionary) -> void:
	w = int(d.get("w", SimCatalog.MAP_W))
	h = int(d.get("h", SimCatalog.MAP_H))
	_alloc()
	var c: Array = d.get("cells", [])
	var cond: Array = d.get("condition", [])
	var s: Array = d.get("silt", [])
	var sf: Array = d.get("slip_filled", [])
	for i in mini(c.size(), cells.size()):
		cells[i] = int(c[i])
	for i in mini(cond.size(), condition.size()):
		condition[i] = int(cond[i])
	for i in mini(s.size(), silt.size()):
		silt[i] = int(s[i])
	for i in mini(sf.size(), slip_filled.size()):
		slip_filled[i] = int(sf[i])
	clubhouse_level = int(d.get("clubhouse_level", 1))
