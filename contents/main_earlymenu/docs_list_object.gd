extends PanelContainer
class_name EarlyMenu_DocsListObject
## 早期版主菜单-文档列表对象

## 标题
var title: String
## 文档内容
var content: String
## 标签列表
var tags_list: PackedStringArray

func check_has_tag(tags: Array[String]) -> bool:
	if (tags.is_empty()):
		visible = true
		return true
	for tag in tags:
		if (tags_list.has(tag)):
			continue
		visible = false
		return false
	visible = true
	return true

func set_tags(tags: PackedStringArray) -> void:
	for node in $VBoxContainer/Tags.get_children():
		node.queue_free()
	for tag in tags:
		var new_node: Label = Label.new()
		new_node.text = tag
		$VBoxContainer/Tags.add_child(new_node)
	tags_list = tags
