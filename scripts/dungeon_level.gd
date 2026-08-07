extends Node2D

var root_node: Branch

var split_depth = 5
var corridor_width = 20
var min_room_size = 60

var corridors: Array[Rect2i] = []

func _ready() -> void:
	ImGui.imgui_layout.connect(self._on_layout)
	build_tree(Vector2i(0, 0), Vector2i(1000, 600))
	pass

func _draw():
	for corridor in corridors:
		draw_rect(corridor, Color.RED, true)
		
	var max_depth = get_max_depth()
	for leaf in root_node.get_leaves():
		var t = float(leaf.depth) / max(1, max_depth)
		draw_rect(
			Rect2(
				leaf.position.x,
				leaf.position.y,
				leaf.size.x,
				leaf.size.y
			),
			Color.BLUE.lerp(Color.GREEN, t),
			true
		)
	pass

func get_max_depth() -> int:
	var max_d = 0
	for leaf in root_node.get_leaves():
		max_d = max(max_d, leaf.depth)
	return max_d

func _on_layout():
	if (ImGui.begin("Settings")):
		split_depth = ImGui.input_int("Split Depth", split_depth, 1, 10)
		#corridor_width = ImGui.input_int("Corridor Width", corridor_width, 1, 10)
		#min_room_size = ImGui.input_int("Minimum Room Size", min_room_size, 1, 10)
		if (ImGui.button("regenerate", 0, 0)):
			build_tree(Vector2i(0, 0), Vector2i(1000, 600))
	ImGui.end()

func build_tree(pos, size):
	root_node = Branch.new(pos, size, 0)
	root_node.split(split_depth)
	root_node.trim()
	corridors = root_node.build_corridors(corridor_width)
	queue_redraw()
