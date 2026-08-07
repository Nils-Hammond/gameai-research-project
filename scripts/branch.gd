extends Node

class_name Branch

var min_size = 60

var min_trim: = 1

var corridor_width = 20

var left_child: Branch
var right_child: Branch
var position: Vector2i
var size: Vector2i
var depth: int

func _init(pos, new_size, node_depth):
	self.position = pos
	self.size = new_size
	self.depth = node_depth

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
	var rand = RandomNumberGenerator.new()
	var split_percent = rand.randf_range(0.3, 0.7)
	var split_horizontal = size.y >= size.x
	
	if (split_horizontal && size.y * split_percent >= max(min_size, corridor_width)):
		var left_height = int(size.y * split_percent)
		left_child = Branch.new(position, Vector2i(size.x, left_height), depth + 1)
		right_child = Branch.new(
			Vector2i(position.x, position.y + left_height),
			Vector2i(size.x, size.y - left_height), depth + 1
		)
	elif (size.x * split_percent >= max(min_size, corridor_width)):
		var left_width = int(size.x * split_percent)
		left_child = Branch.new(position, Vector2i(left_width, size.y), depth + 1)
		right_child = Branch.new(
			Vector2i(position.x + left_width, position.y), 
			Vector2i(size.x - left_width, size.y), depth + 1
		)

	if(remaining > 0):
		if (left_child):
			left_child.split(remaining - 1)
		if (right_child):
			right_child.split(remaining - 1)
	pass

func trim():
	if (is_leaf()):
		var rand = RandomNumberGenerator.new()
		var left_trim = _get_safe_trim(rand, size.x, min_size)
		var right_trim = _get_safe_trim(rand, size.x - left_trim, min_size)
		var top_trim = _get_safe_trim(rand, size.y, min_size)
		var bottom_trim = _get_safe_trim(rand, size.y - top_trim, min_size)
	
		position.x += left_trim
		position.y += top_trim
		size.x -= right_trim + left_trim
		size.y -= bottom_trim + top_trim
	
	if (left_child):
		left_child.trim()
	if (right_child):
		right_child.trim()

func _get_safe_trim(rand, available_size, min_size):
	var max_trim = available_size / 2
	var max_possible_trim = max(0, available_size - min_size)
	var low = min(min_trim, max_possible_trim)
	var high = min(max_trim, max_possible_trim)
	if (high <= 0):
		return 0
	return rand.randi_range(low, high)

func connect_corridors(corridors: Array[Rect2i]):
	if (is_leaf()):
		return
	
	left_child.connect_corridors(corridors)
	right_child.connect_corridors(corridors)
	
	var a = left_child.get_center()
	var b = right_child.get_center()
	var half = corridor_width / 2
	
	if a.y == b.y:
		corridors.append(Rect2i(
			Vector2i(min(a.x, b.x) - half, a.y - half),
			Vector2i(abs(a.x - b.x) + corridor_width, corridor_width)
		))
	else:
		corridors.append(Rect2i(
			Vector2i(a.x - half, min(a.y, b.y) - half),
			Vector2i(corridor_width, abs(a.y - b.y) + corridor_width)
		))

func build_corridors(width: int) -> Array[Rect2i]:
	if is_leaf():
		return []
	
	var corridors := left_child.build_corridors(width) + right_child.build_corridors(width)
	var leaf1 = left_child.get_random_leaf().get_room()
	var leaf2 = right_child.get_random_leaf().get_room()
	corridors.append_array(CorridorBuilder.connect_rooms(leaf1, leaf2, width))
	return corridors
	
