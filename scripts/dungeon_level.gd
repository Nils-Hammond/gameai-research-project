extends Node2D

var root_node: Branch

var split_depth = 5
var bsp_settings: BspSettings

var corridors: Array[Rect2i] = []

func _ready() -> void:
	bsp_settings = BspSettings.new()
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
	if (ImGui.begin_ex("Settings", ImGui.WINDOW_ALWAYS_AUTO_RESIZE)):
		ImGui.text("Split Depth")
		split_depth = ImGui.input_int("##Split Depth", split_depth, 1, 10)
		
		ImGui.text("Corridor Width")
		bsp_settings.corridor_width = ImGui.input_int("##Corridor Width", bsp_settings.corridor_width, 1, 10)
		
		ImGui.text("Minimum Room Size")
		bsp_settings.min_size = ImGui.input_int("##Minimum Room Size", bsp_settings.min_size, 1, 10)
				
		ImGui.text("Split Range")
		var split_percents = Vector2(bsp_settings.split_min_percent,bsp_settings.split_max_percent)
		split_percents = ImGui.slider_float2("##Split Range", split_percents, 0, 1)
		split_percents[0] = min(split_percents[0], split_percents[1])
		split_percents[1] = max(split_percents[0], split_percents[1])
		bsp_settings.split_min_percent = split_percents[0]
		bsp_settings.split_max_percent = split_percents[1]

		bsp_settings.random_split = ImGui.checkbox("Random Split Direction", bsp_settings.random_split)
		
		ImGui.text("Trim Range")
		var trim_percents = Vector2(bsp_settings.trim_min_percent, bsp_settings.trim_max_percent)
		trim_percents = ImGui.slider_float2("Trim Range", trim_percents, 0, 0.99)
		trim_percents[0] = min(trim_percents[0], trim_percents[1])
		trim_percents[1] = max(trim_percents[0], trim_percents[1])
		bsp_settings.trim_min_percent = trim_percents[0]
		bsp_settings.trim_max_percent = trim_percents[1]
		
		if (ImGui.button("Regenerate", 0, 0)):
			build_tree(Vector2i(0, 0), Vector2i(1000, 600))
	ImGui.end()

func build_tree(pos, size):
	root_node = Branch.new(pos, size, 0, bsp_settings)
	root_node.split(split_depth)
	root_node.trim()
	corridors = root_node.build_corridors(bsp_settings.corridor_width)
	queue_redraw()
