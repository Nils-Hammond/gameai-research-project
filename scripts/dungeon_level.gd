extends Node2D

var root_node: Branch
var tile_size: int = 16
var split_depth = 5

var corridors: Array[Rect2i] = []

func _ready() -> void:
	ImGui.imgui_layout.connect(self._on_layout)
	build_tree(Vector2i(0, 0), Vector2i(1000, 600))
	pass

func _draw():
	for corridor in corridors:
		draw_rect(corridor, Color.RED, true)
	for leaf in root_node.get_leaves():
		draw_rect(
			Rect2(
				leaf.position.x,
				leaf.position.y,
				leaf.size.x,
				leaf.size.y
			),
			Color.GREEN,
			true
		)
	pass

func _on_layout():
	if (ImGui.begin("Settings")):
		split_depth = ImGui.input_int("Split Depth", split_depth, 1, 10)
		if (ImGui.button("regenerate", 0, 0)):
			build_tree(Vector2i(0, 0), Vector2i(1000, 600))
	ImGui.end()

func build_tree(pos, size):
	root_node = Branch.new(pos, size)
	root_node.split(split_depth)
	corridors = []
	root_node.connect_corridors(corridors)
	root_node.trim()
	queue_redraw()
