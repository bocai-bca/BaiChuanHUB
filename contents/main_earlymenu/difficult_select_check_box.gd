extends CheckBox
class_name EarlyMenu_DifficultSelectCheckBox
## 早期版主菜单-难度选择按钮

## ClassPackedScene
const CPS: PackedScene = preload("res://contents/main_earlymenu/difficult_select_check_box.tscn")

## 当前按钮所代表的难度的索引，对应BaiChuanInstaller_PackAccess.PackMeta.difficults_list的索引，通过本变量的值访问该数组可以取得该难度的path
var difficult_index: int
