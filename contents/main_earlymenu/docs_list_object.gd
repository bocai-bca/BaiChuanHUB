extends PanelContainer
class_name EarlyMenu_DocsListObject
## 早期版主菜单-文档列表对象

## 标题
var title: String
## 文档内容
var content: String
## 标签列表
var tags_list: PackedStringArray

## 设置内容。需在该节点添加到场景树之前调用此方法
func set_contents(new_content: String) -> void:
	content = new_content
	title = new_content.split("\n", true, 1)[0]

## 检查是否含有标签并执行显示或隐藏
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

## 设置标签。需在该节点添加到场景树之前调用此方法
func set_tags(tags: PackedStringArray) -> void:
	for node in $VBoxContainer/Tags.get_children():
		node.queue_free()
	for tag in tags:
		var new_node: Label = Label.new()
		new_node.text = tag
		$VBoxContainer/Tags.add_child(new_node)
	tags_list = tags
