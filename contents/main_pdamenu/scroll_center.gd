extends Sprite2D
class_name PDAMenu_ScrollCenter
## 用于PDA主题的滚动栏中央贴图，本类的场景实例需要是VScrollBar的子节点

## ClassPackedScene
const CPS: PackedScene = preload("res://contents/main_pdamenu/scroll_center.tscn")

var scroll_bar: VScrollBar

func _ready() -> void:
	var parent: Control = get_parent() as Control
	if (parent is VScrollBar):
		scroll_bar = parent as VScrollBar
	#elif (parent is ScrollContainer):
		#scroll_bar = (parent as ScrollContainer).get_v_scroll_bar()
		#(parent as ScrollContainer).set_deferred(&"scroll_vertical", 1.0)
	#elif (parent is RichTextLabel):
		#scroll_bar = (parent as RichTextLabel).get_v_scroll_bar()
		#(parent as RichTextLabel).fit_content = true
		#(parent as RichTextLabel).fit_content = false
	else:
		push_error("PDAMenu_ScrollCenter: 实例化于不可用的父节点中，将自动删除")
		queue_free()
		return
	scroll_bar.value_changed.connect(on_value_changed)
	scale = Vector2.ZERO

func on_value_changed(value: float) -> void:
	var scroll_length: float = scroll_bar.size.y * scroll_bar.page / (scroll_bar.max_value - scroll_bar.min_value)
	var scroll_stylebox: StyleBox = scroll_bar.get_theme_stylebox(&"scroll")
	position = Vector2(
		scroll_bar.size.x / 2.0,
		scroll_bar.size.y * scroll_bar.ratio + scroll_length / 2.0
	)
	scale.x = (scroll_stylebox.content_margin_left + scroll_stylebox.content_margin_right) / texture.get_size().x
	scale.y = scale.x
