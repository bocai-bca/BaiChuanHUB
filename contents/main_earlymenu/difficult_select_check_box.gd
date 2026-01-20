extends CheckBox
class_name EarlyMenu_DifficultSelectCheckBox
## 早期版主菜单-难度选择按钮

## ClassPackedScene
const CPS: PackedScene = preload("res://contents/main_earlymenu/difficult_select_check_box.tscn")

## 当前按钮所代表的难度的索引，对应BaiChuanInstaller_PackAccess.PackMeta.difficults_list的索引，通过本变量的值访问该数组可以取得该难度的path
var difficult_index: int

## 设置颜色，通常只在按钮刚实例化后使用
func set_color(text_color: Color, text_outline_color: Color, fill_color: Color) -> void:
	var stylebox: StyleBoxFlat = (get_theme_stylebox(&"normal", &"CheckBox") as StyleBoxFlat).duplicate()
	stylebox.bg_color = Color(fill_color, 0.121)
	add_theme_stylebox_override(&"normal", stylebox)
	add_theme_stylebox_override(&"pressed", stylebox)
	stylebox = (get_theme_stylebox(&"hover", &"CheckBox") as StyleBoxFlat).duplicate()
	stylebox.bg_color = Color(fill_color, 0.372)
	add_theme_stylebox_override(&"hover", stylebox)
	add_theme_stylebox_override(&"hover_pressed", stylebox)
	stylebox = (get_theme_stylebox(&"disabled", &"CheckBox") as StyleBoxFlat).duplicate()
	stylebox.bg_color = Color(fill_color, 0.121)
	add_theme_stylebox_override(&"disabled", stylebox)
	add_theme_color_override(&"font_color", text_color)
	add_theme_color_override(&"font_focus_color", text_color)
	add_theme_color_override(&"font_hover_color", text_color)
	add_theme_color_override(&"font_disabled_color", text_color * 0.6)
	add_theme_color_override(&"font_outline_color", text_outline_color)
