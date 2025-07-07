extends CheckBox
class_name EarlyMenu_AddonSelectCheckBox
## 早期版主菜单-附属包选择按钮

## ClassPackedScene
const CPS: PackedScene = preload("res://contents/main_earlymenu/addon_select_check_box.tscn")

## 当前按钮所代表的附属包的索引
var addon_index: int
## 当前按钮所代表的附属包支持的难度的索引数组
var support_difficults: PackedByteArray

## 根据给定的难度索引，结合自身存储的支持难度判断自身是否需要禁用，并执行操作后返回操作后自身的开关状态
func if_difficult_disable(current_difficult: int) -> bool:
	if (support_difficults.has(current_difficult)): #如果自身支持列表包含给定的难度
		## 该按钮直接支持给定难度(与通配无关)
		disabled = false #启用
		return button_pressed
	else: #否则(自身支持列表不含给定的难度)
		if (support_difficults.has(255)): #如果自身支持通配难度
			## 不支持给定难度但支持通配
			disabled = false #启用
			return button_pressed
		## 不支持给定难度也不支持通配，则该按钮不兼容给定难度
		disabled = true #禁用
		button_pressed = false
		return false
