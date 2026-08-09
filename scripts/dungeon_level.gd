extends Node2D

var panel_width = 250

var root_node: Branch

var split_depth = 3
var bsp_settings: BspSettings

var corridors: Array[Rect2i] = []
var alt_corridors: Array[Rect2i] = []
var show_alt: bool = false

func _ready() -> void:
	bsp_settings = BspSettings.new()
	ImGui.imgui_layout.connect(self._on_layout)
	var viewport_size = get_viewport().get_visible_rect().size
	build_tree(Vector2i(panel_width, 0), Vector2i(viewport_size.x - panel_width, viewport_size.y))
	pass

func _draw():
	if (show_alt):
		for corridor in alt_corridors:
			draw_rect(corridor, Color.RED, true)
	else:
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

func build_tree(pos: Vector2i, size: Vector2i):
	root_node = Branch.new(pos, size, 0, bsp_settings)
	root_node.split(split_depth)
	alt_corridors = []
	root_node.basic_build_corridors(alt_corridors)
	root_node.trim()
	corridors = root_node.build_corridors(bsp_settings.corridor_width, root_node.get_rooms())
	queue_redraw()

func _on_layout():
	var viewport_size = get_viewport().get_visible_rect().size
	
	ImGui.set_next_window_pos(0, 0, ImGui.COND_ALWAYS)
	ImGui.set_next_window_size(panel_width, viewport_size.y, ImGui.COND_ALWAYS)
	
	if (ImGui.begin_ex("Settings", ImGui.WINDOW_NO_MOVE | ImGui.WINDOW_NO_COLLAPSE | ImGui.WINDOW_NO_RESIZE)):
		
		ImGui.text("BSP Generation")
		ImGui.separator()
		ImGui.spacing()
		ImGui.text("Split Depth")
		split_depth = ImGui.input_int("##Split Depth", split_depth, 1, 10)
		
		ImGui.text("Split Range")
		var split_percents = Vector2(bsp_settings.split_min_percent,bsp_settings.split_max_percent)
		split_percents = ImGui.slider_float2("##Split Range", split_percents, 0, 1)
		split_percents[0] = min(split_percents[0], split_percents[1])
		split_percents[1] = max(split_percents[0], split_percents[1])
		bsp_settings.split_min_percent = split_percents[0]
		bsp_settings.split_max_percent = split_percents[1]
		
		bsp_settings.random_split = ImGui.checkbox("Random Split Direction", bsp_settings.random_split)
		
		ImGui.text("Dead End Chance")
		bsp_settings.force_dead_end_chance = ImGui.slider_float("##Dead End Chance", bsp_settings.force_dead_end_chance, 0, 1)
		
		ImGui.dummy(Vector2(0, 20))
		ImGui.text("Room Generation")
		ImGui.separator()
		ImGui.spacing()
		
		ImGui.text("Minimum Room Size")
		bsp_settings.min_size = ImGui.input_int("##Minimum Room Size", bsp_settings.min_size, 1, 10)
		
		ImGui.text("Trim Range")
		var trim_percents = Vector2(bsp_settings.trim_min_percent, bsp_settings.trim_max_percent)
		trim_percents = ImGui.slider_float2("##Trim Range", trim_percents, 0, 0.99)
		trim_percents[0] = min(trim_percents[0], trim_percents[1])
		trim_percents[1] = max(trim_percents[0], trim_percents[1])
		bsp_settings.trim_min_percent = trim_percents[0]
		bsp_settings.trim_max_percent = trim_percents[1]
		
		ImGui.dummy(Vector2(0, 20))
		ImGui.text("Corridor Generation")
		ImGui.separator()
		ImGui.spacing()
		ImGui.text("Corridor Width")
		bsp_settings.corridor_width = ImGui.input_int("##Corridor Width", bsp_settings.corridor_width, 1, 10)
		
		bsp_settings.connect_closest_rooms = ImGui.checkbox("Connect Closest Rooms", bsp_settings.connect_closest_rooms)
		
		ImGui.dummy(Vector2(0, 20))
		ImGui.separator()
		if (ImGui.button("Regenerate", 0, 0)):
			build_tree(Vector2i(panel_width, 0), Vector2i(viewport_size.x - panel_width, viewport_size.y))
		
		var prev = show_alt
		show_alt = ImGui.checkbox("Show Alternative Corridors", show_alt)
		if prev != show_alt:
			queue_redraw()
	ImGui.end()
