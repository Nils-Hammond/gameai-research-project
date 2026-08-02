extends Node2D

var root_node: Branch
var tile_size: int = 16
var split_depth = 5

func _ready() -> void:
	ImGui.imgui_layout.connect(self._on_layout)
	root_node = Branch.new(Vector2i(0, 0), Vector2i(60, 30))
	root_node.split(split_depth)
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

func _on_layout():
	if (ImGui.begin("Settings")):
		split_depth = ImGui.input_int("Split Depth", split_depth, 1, 10)
		if (ImGui.button("regenerate", 0, 0)):
			root_node = Branch.new(Vector2i(0, 0), Vector2i(60, 30))
			root_node.split(split_depth)
			queue_redraw()
	ImGui.end()
