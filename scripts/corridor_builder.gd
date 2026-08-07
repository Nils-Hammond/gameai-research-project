extends Node

class_name CorridorBuilder

enum Bend {HORIZONTAL_FIRST, VERTICAL_FIRST}

static func connect_rooms(from: Rect2i, to: Rect2i, width: int) -> Array[Rect2i]:
	var straight = _try_straight_corridor(from, to, width)
	if (not straight.is_empty()):
		return straight
	else:
		var bend = Bend.HORIZONTAL_FIRST if randi() % 2 == 0 else Bend.VERTICAL_FIRST
		return _bent_corridor(from, to, width, bend)

static func _try_straight_corridor(from: Rect2i, to: Rect2i, width: int) -> Array[Rect2i]:
	# Try horizontal corridor
	var minY = max(from.position.y, to.position.y)
	var maxY = min(from.end.y, to.end.y)
	if (maxY - minY >= width):
		var y = (minY + maxY) / 2 - width / 2
		var left = from if from.position.x <= to.position.x else to
		var right = to if from.position.x <= to.position.x else from
		var gap = right.position.x - left.end.x
		if gap > 0:
			return [Rect2i(Vector2i(left.end.x, y), Vector2i(gap, width))]
	
	# Try vertical corridor
	var minX = max(from.position.x, to.position.x)
	var maxX = min(from.end.x, to.end.x)
	if (maxX - minX >= width):
		var x = (minX + maxX) / 2 - width / 2
		var top = from if from.position.y <= to.position.y else to
		var bottom = to if from.position.y <= to.position.y else from
		var gap = bottom.position.y - top.end.y
		if gap > 0:
			return [Rect2i(Vector2i(x, top.end.y), Vector2i(width, gap))]
	
	# No straight corridor possible
	return []

static func _bent_corridor(from: Rect2i, to: Rect2i, width: int, bend: Bend) -> Array[Rect2i]:
	var half = width / 2
	var from_center = from.position + from.size / 2
	var to_center = to.position + to.size / 2
	var corner: Vector2i
	if (bend == Bend.HORIZONTAL_FIRST):
		corner = Vector2i(to_center.x, from_center.y)
	else:
		corner = Vector2i(from_center.x, to_center.y)
	
	var section1 = Rect2i(
		Vector2i(min(from_center.x, corner.x) - half, min(from_center.y, corner.y) - half),
		Vector2i(abs(from_center.x - corner.x) + width, abs(from_center.y - corner.y) + width)
	)
	var section2 = Rect2i(
		Vector2i(min(corner.x, to_center.x) - half, min(corner.y, to_center.y) - half),
		Vector2i(abs(corner.x - to_center.x) + width, abs(corner.y - to_center.y) + width)
	)
	return [section1, section2]
