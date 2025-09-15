extends RefCounted
class_name DocsPackAccess
## 文档包访问，以动态实例运作

## 元数据文件名
const META_NAME: String = "meta.json"

## 多线程线程实例
var thread: Thread = Thread.new()
## 多线程读写互斥锁
var mutex: Mutex = Mutex.new()
## 包DirAccess
var dir_access: DirAccess
## 已读取的文档对象，配备读写安全
var doc_objects: Array[DocObject]:
	get:
		mutex.lock()
		var result = doc_objects.duplicate()
		mutex.unlock()
		return result
	set(value):
		mutex.lock()
		doc_objects = value
		mutex.unlock()

## 打开包，传入指向包文件夹的绝对路径
func open_pack(absolute_path: String) -> bool:
	dir_access = DirAccess.open(absolute_path)
	if (dir_access == null):
		print("DocsPackAccess: 打开文档包失败，")

## 文档对象，除内容外所有变量都由元数据指定
class DocObject extends RefCounted:
	## 标题
	var title: String
	## 内容，文档内容的显示器使用RichTextLabel，因此可使用BBCode呈现富样式文本
	var content: String
	## 标签，即该文档的标签，用于搜索文档条目
	var tags: PackedStringArray
	## 树路径，每个对象代表一层路径
	var tree_path: PackedStringArray
	func _init(new_title: String, new_tags: PackedStringArray, new_tree: PackedStringArray, new_content: String) -> void:
		title = new_title
		content = new_content
		tags = new_tags
		tree_path = new_tree
		
