extends Node

class_name Branch

var left_child: Branch
var right_child: Branch
var position: Vector2i
var size: Vector2i

func _init(position, size):
	self.position = position
	self.size = size

func get_leaves():
	if not (left_child && right_child):
		return [self]
	else:
		return left_child.get_leaves() + right_child.get_leaves()

func split(remaining):
	var rand = RandomNumberGenerator.new()
	var split_percent = rand.randf_range(0.3, 0.7)
	var split_horizontal = size.y >= size.x
	
	if (split_horizontal):
		var left_height = int(size.y * split_percent)
		left_child = Branch.new(position, Vector2i(size.x, left_height))
		right_child = Branch.new(
			Vector2i(position.x, position.y + left_height),
			Vector2i(size.x, size.y - left_height)
		)
	else:
		var left_width = int(size.x * split_percent)
		left_child = Branch.new(position, Vector2i(left_width, size.y))
		right_child = Branch.new(
			Vector2i(position.x + left_width, position.y), 
			Vector2i(size.x - left_width, size.y)
		)

	if(remaining > 0):
		left_child.split(remaining - 1)
		right_child.split(remaining - 1)
	pass
