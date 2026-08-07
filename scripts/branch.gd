extends Node

class_name Branch

var left_child: Branch
var right_child: Branch
var position: Vector2i
var size: Vector2i
var depth: int
var settings: BspSettings

func _init(pos, new_size, node_depth, bsp_settings):
	self.position = pos
	self.size = new_size
	self.depth = node_depth
	self.settings = bsp_settings

func get_leaves():
	if not (left_child && right_child):
		return [self]
	else:
		return left_child.get_leaves() + right_child.get_leaves()

func get_random_leaf():
	var leaves = get_leaves()
	return leaves[randi() % leaves.size()]

func is_leaf():
	return not (left_child && right_child)

func get_room() -> Rect2i:
	return Rect2i(position, size)

func get_center() -> Vector2i:
	return Vector2i(position.x + size.x / 2, position.y + size.y / 2)

func split(remaining):
	var split_percent = randf_range(settings.split_min_percent, settings.split_max_percent)
	var split_horizontal = size.y >= size.x if not settings.random_split else randf() < 0.5
	
	if (split_horizontal && size.y * split_percent >= max(settings.min_size, settings.corridor_width)):
		var left_height = int(size.y * split_percent)
		left_child = Branch.new(position, Vector2i(size.x, left_height), depth + 1, settings)
		right_child = Branch.new(
			Vector2i(position.x, position.y + left_height),
			Vector2i(size.x, size.y - left_height), depth + 1, settings
		)
	elif (size.x * split_percent >= max(settings.min_size, settings.corridor_width)):
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
	pass

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

func _get_safe_trim(available_size):
	var min_trim = available_size * settings.trim_min_percent
	var max_trim = available_size * settings.trim_max_percent
	var max_possible_trim = max(0, available_size - settings.min_size)
	var low = min(min_trim, max_possible_trim)
	var high = min(max_trim, max_possible_trim)
	if (high <= 0):
		return 0
	return randi_range(low, high)

func connect_corridors(corridors: Array[Rect2i]):
	if (is_leaf()):
		return
	
	left_child.connect_corridors(corridors)
	right_child.connect_corridors(corridors)
	
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

func build_corridors(width: int) -> Array[Rect2i]:
	if is_leaf():
		return []
	
	var corridors := left_child.build_corridors(width) + right_child.build_corridors(width)
	var leaf1 = left_child.get_random_leaf().get_room()
	var leaf2 = right_child.get_random_leaf().get_room()
	corridors.append_array(CorridorBuilder.connect_rooms(leaf1, leaf2, width))
	return corridors
	
