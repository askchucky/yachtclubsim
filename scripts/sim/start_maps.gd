extends RefCounted

## Harbor Year and Empty Shore starting layouts.


func apply_harbor_year(g) -> void:
	g._alloc()
	g.fill_rect(0, 0, g.w - 1, 16, SimCatalog.CELL_GRASS)
	g.fill_rect(0, 14, g.w - 1, 17, SimCatalog.CELL_SAND)
	g.fill_rect(0, 18, g.w - 1, g.h - 1, SimCatalog.CELL_WATER)
	g.fill_rect(0, 30, g.w - 1, g.h - 1, SimCatalog.CELL_DEEP)
	g.fill_rect(38, 10, 56, 16, SimCatalog.CELL_SAND)
	g.fill_rect(40, 12, 48, 14, SimCatalog.CELL_PATH)
	g.set_cell(44, 11, SimCatalog.CELL_CLUBHOUSE)
	g.set_cell(48, 12, SimCatalog.CELL_BAR)
	g.set_cell(40, 12, SimCatalog.CELL_OFFICE)
	g.set_cell(52, 13, SimCatalog.CELL_RACE)
	g.set_cell(36, 13, SimCatalog.CELL_YARD)
	g.set_cell(50, 15, SimCatalog.CELL_FUEL)
	for t in [[42, 10], [46, 10], [50, 10], [43, 15], [47, 15]]:
		g.set_cell(t[0], t[1], SimCatalog.CELL_TREE)
	for f in [[45, 15], [49, 14]]:
		g.set_cell(f[0], f[1], SimCatalog.CELL_FLOWERS)
	g.set_cell(44, 15, SimCatalog.CELL_LIGHTS)
	_build_pier(g, 32, 17, 16, true)
	_build_pier(g, 44, 17, 16, true)
	_build_pier(g, 58, 17, 16, true)
	for y in range(18, 22):
		for x in range(36, 42):
			_paint_channel(g, x, y)
	for y in range(21, g.h):
		for x in range(37, 41):
			_paint_channel(g, x, y)
	for x in range(33, 38):
		_paint_channel(g, x, 20)
	for x in range(41, 46):
		_paint_channel(g, x, 20)
	for x in range(45, 59):
		_paint_channel(g, x, 21)
	for x in range(28, 72):
		g.set_cell(x, 28, SimCatalog.CELL_BREAKWATER)
	for y in range(22, 29):
		g.set_cell(28, y, SimCatalog.CELL_BREAKWATER)
		g.set_cell(71, y, SimCatalog.CELL_BREAKWATER)
	for x in range(37, 41):
		g.set_cell(x, 28, SimCatalog.CELL_CHANNEL)
		g.silt[g.idx(x, 28)] = 0
	g.clubhouse_level = 1
	var filled := 0
	for i in g.cells.size():
		if g.cells[i] == SimCatalog.CELL_SLIP and filled < 36:
			g.slip_filled[i] = 1
			filled += 1


func apply_empty_shore(g) -> void:
	g._alloc()
	g.fill_rect(0, 0, g.w - 1, 20, SimCatalog.CELL_GRASS)
	g.fill_rect(0, 18, g.w - 1, 22, SimCatalog.CELL_SAND)
	g.fill_rect(0, 23, g.w - 1, g.h - 1, SimCatalog.CELL_SHALLOW)
	g.fill_rect(0, 40, g.w - 1, g.h - 1, SimCatalog.CELL_WATER)
	g.fill_rect(44, 16, 50, 20, SimCatalog.CELL_SAND)
	g.set_cell(47, 17, SimCatalog.CELL_CLUBHOUSE)
	g.set_cell(47, 18, SimCatalog.CELL_PATH)
	g.clubhouse_level = 1


func _paint_channel(g, x: int, y: int) -> void:
	var cur: int = int(g.get_cell(x, y))
	if cur == SimCatalog.CELL_PIER or cur == SimCatalog.CELL_SLIP:
		return
	g.set_cell(x, y, SimCatalog.CELL_CHANNEL)
	g.silt[g.idx(x, y)] = 0


func _build_pier(g, root_x: int, root_y: int, length: int, slips_both: bool) -> void:
	for dy in range(length):
		var y: int = root_y + dy
		g.set_cell(root_x, y, SimCatalog.CELL_PIER)
		g.condition[g.idx(root_x, y)] = 100
		if slips_both and dy >= 1 and dy % 2 == 1 and dy < length - 1:
			for side in [-1, 1]:
				var sx: int = root_x + int(side)
				var cur: int = int(g.get_cell(sx, y))
				if cur == SimCatalog.CELL_WATER or cur == SimCatalog.CELL_DEEP or cur == SimCatalog.CELL_SHALLOW:
					g.set_cell(sx, y, SimCatalog.CELL_SLIP)
					g.condition[g.idx(sx, y)] = 100
