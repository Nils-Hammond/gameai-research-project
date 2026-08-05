extends Node

class_name Branch

var min_width = 40
var min_height = 40

var min_trim: = 1
var max_trim: = 50

var corridor_margin = 5

var left_child: Branch
var right_child: Branch
var position: Vector2i
var size: Vector2i

func _init(pos, new_size):
	self.position = pos
	self.size = new_size

func get_leaves():
	if not (left_child && right_child):
		return [self]
	else:
		return left_child.get_leaves() + right_child.get_leaves()

func is_leaf():
	return not (left_child && right_child)

func get_center() -> Vector2i:
	return Vector2i(position.x + size.x / 2, position.y + size.y / 2)

func split(remaining):
	var rand = RandomNumberGenerator.new()
	var split_percent = rand.randf_range(0.3, 0.7)
	var split_horizontal = size.y >= size.x
	
	if (split_horizontal && size.y * split_percent >= min_height):
		var left_height = int(size.y * split_percent)
		left_child = Branch.new(position, Vector2i(size.x, left_height))
		right_child = Branch.new(
			Vector2i(position.x, position.y + left_height),
			Vector2i(size.x, size.y - left_height)
		)
	elif (size.x * split_percent >= min_width):
		var left_width = int(size.x * split_percent)
		left_child = Branch.new(position, Vector2i(left_width, size.y))
		right_child = Branch.new(
			Vector2i(position.x + left_width, position.y), 
			Vector2i(size.x - left_width, size.y)
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
		var left_trim = _get_safe_trim(rand, size.x, min_width)
		var right_trim = _get_safe_trim(rand, size.x - left_trim, min_width)
		var top_trim = _get_safe_trim(rand, size.y, min_height)
		var bottom_trim = _get_safe_trim(rand, size.y - top_trim, min_height)
	
		position.x += left_trim
		position.y += top_trim
		size.x -= right_trim + left_trim
		size.y -= bottom_trim + top_trim
	
	if (left_child):
		left_child.trim()
	if (right_child):
		right_child.trim()

func _get_safe_trim(rand, available_size, min_size):
	var max_possible_trim = max(0, available_size - min_size)
	var low = min(min_trim, max_possible_trim)
	var high = min(max_trim, max_possible_trim)
	if (high <= 0):
		return 0
	return rand.randi_range(low, high)
