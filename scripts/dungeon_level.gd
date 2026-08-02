extends Node2D

var root_node: Branch
var tile_size: int = 16

func _ready() -> void:
	root_node = Branch.new(Vector2i(0, 0), Vector2i(60, 30))
	root_node.split(5)
	queue_redraw()
	pass

func _draw():
	for leaf in root_node.get_leaves():
		draw_rect(
			Rect2(
				leaf.position.x * tile_size,
				leaf.position.y * tile_size,
				leaf.size.x * tile_size,
				leaf.size.y * tile_size
			),
			Color.GREEN,
			false
		)
	pass
