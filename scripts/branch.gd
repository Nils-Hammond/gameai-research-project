extends Node

class_name Branch

var left_child: Branch
var right_child: Branch
var position: Vector2i
var size: Vector2i
var depth: int
var settings: BspSettings

func _init(pos: Vector2i, new_size: Vector2i, node_depth: int, bsp_settings: BspSettings):
	self.position = pos
	self.size = new_size
	self.depth = node_depth
	self.settings = bsp_settings

func get_leaves() -> Array[Branch]:
	if not (left_child && right_child):
		return [self]
	else:
		return left_child.get_leaves() + right_child.get_leaves()

func get_random_leaf() -> Branch:
	var leaves = get_leaves()
	return leaves[randi() % leaves.size()]

func is_leaf() -> bool:
	return not (left_child && right_child)

func get_room() -> Rect2i:
	return Rect2i(position, size)

func get_rooms() -> Array[Rect2i]:
	var rooms: Array[Rect2i] = []
	for leaf in get_leaves():
		rooms.append(leaf.get_room())
	return rooms

func get_center() -> Vector2i:
	return Vector2i(position.x + size.x / 2, position.y + size.y / 2)

func split(remaining: int):
	var split_percent = randf_range(settings.split_min_percent, settings.split_max_percent)
	var split_horizontal = size.y >= size.x if not settings.random_split else randf() < 0.5
	
	if randf() < settings.force_dead_end_chance:
		return
	
	if (split_horizontal && size.y >= 2 * max(settings.min_size, settings.corridor_width)):
		var left_height = int(size.y * split_percent)
		left_child = Branch.new(position, Vector2i(size.x, left_height), depth + 1, settings)
		right_child = Branch.new(
			Vector2i(position.x, position.y + left_height),
			Vector2i(size.x, size.y - left_height), depth + 1, settings
		)
	elif (size.x >= 2 * max(settings.min_size, settings.corridor_width)):
		var left_width = int(size.x * split_percent)
		left_child = Branch.new(position, Vector2i(left_width, size.y), depth + 1, settings)
		right_child = Branch.new(
			Vector2i(position.x + left_width, position.y), 
			Vector2i(size.x - left_width, size.y), depth + 1, settings
		)

	if(remaining > 0):
		if (left_child):
			left_child.split(remaining - 1)
		if (right_child):
			right_child.split(remaining - 1)

func trim():
	if (is_leaf()):
		var x_trim = _get_safe_trim(size.x)
		var y_trim = _get_safe_trim(size.y)
		
		var left_trim = int(x_trim * randf())
		var right_trim = x_trim - left_trim
		var top_trim = int(y_trim * randf())
		var bottom_trim = y_trim - top_trim
	
		position.x += left_trim
		position.y += top_trim
		size.x -= right_trim + left_trim
		size.y -= bottom_trim + top_trim
	
	if (left_child):
		left_child.trim()
	if (right_child):
		right_child.trim()

func _get_safe_trim(available_size: int):
	var min_trim = available_size * settings.trim_min_percent
	var max_trim = available_size * settings.trim_max_percent
	var max_possible_trim = max(0, available_size - max(settings.min_size, settings.corridor_width))
	var low = min(min_trim, max_possible_trim)
	var high = min(max_trim, max_possible_trim)
	if (high <= 0):
		return 0
	return randi_range(low, high)

func basic_build_corridors(corridors: Array[Rect2i]):
	if (is_leaf()):
		return
	
	left_child.basic_build_corridors(corridors)
	right_child.basic_build_corridors(corridors)
	
	var a = left_child.get_center()
	var b = right_child.get_center()
	var half = settings.corridor_width / 2
	
	if a.y == b.y:
		corridors.append(Rect2i(
			Vector2i(min(a.x, b.x) - half, a.y - half),
			Vector2i(abs(a.x - b.x) + settings.corridor_width, settings.corridor_width)
		))
	else:
		corridors.append(Rect2i(
			Vector2i(a.x - half, min(a.y, b.y) - half),
			Vector2i(settings.corridor_width, abs(a.y - b.y) + settings.corridor_width)
		))

func build_corridors(width: int, all_rooms: Array[Rect2i]) -> Array[Rect2i]:
	if is_leaf():
		return []
	
	var corridors := left_child.build_corridors(width, all_rooms) + right_child.build_corridors(width, all_rooms)
	var room_pair = _pick_pair(left_child, right_child)
	corridors.append_array(CorridorBuilder.connect_rooms(room_pair[0], room_pair[1], width, all_rooms))
	return corridors

func _pick_pair(left: Branch, right:Branch) -> Array:
	if not settings.connect_closest_rooms:
		return [left.get_random_leaf().get_room(), right.get_random_leaf().get_room()]
	return _closest_pair(left, right)

func _closest_pair(left: Branch, right: Branch) -> Array:
	if left.is_leaf() && right.is_leaf():
		return [left.get_room(), right.get_room()]
	if left.is_leaf():
		return _closer_pair(_closest_pair(left, right.left_child), _closest_pair(left, right.right_child))
	if right.is_leaf():
		return _closer_pair(_closest_pair(left.left_child, right), _closest_pair(left.right_child, right))
	
	var candidates = [
		_closest_pair(left.left_child, right.left_child),
		_closest_pair(left.left_child, right.right_child),
		_closest_pair(left.right_child, right.left_child),
		_closest_pair(left.right_child, right.right_child)
	]
	var best = candidates[0]
	for c in candidates:
		best = _closer_pair(best, c)
	return best

static func _closer_pair(pair_a: Array, pair_b: Array) -> Array:
	return pair_a if _dist_sq(pair_a[0], pair_a[1]) <= _dist_sq(pair_b[0], pair_b[1]) else pair_b

static func _dist_sq(a: Rect2i, b: Rect2i) -> int:
	var d = (a.position + a.size / 2) - (b.position + b.size / 2)
	return d.x * d.x + d.y * d.y
