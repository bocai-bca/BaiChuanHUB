extends TextureRect
class_name Main_PDAMenu
## PDA美化主菜单，其实就是给早期主菜单套一层壳，本类就是实现这层壳

@onready var n_grab_area: TextureButton = $GrabArea as TextureButton
@onready var n_earlymenu: Main_EarlyMenu = $Main_EarlyMenu as Main_EarlyMenu

## 子菜单坐标比率(用于position)，基于本场景根节点size属性
const SUBMENU_POS_RATE: Vector2 = Vector2(365.0 / 1280.0, 135.0 / 921.0)
## 子菜单尺寸比率(用于size)，基于本场景根节点size属性
const SUBMENU_SIZE_RATE: Vector2 = Vector2(1260.0 / 1280.0, 1020.0 / 921.0)

var mouse_grabbing: bool = false
var mouse_pos_on_grab: Vector2i = Vector2i.ZERO
var window_pos_on_grab: Vector2i = Vector2i.ZERO

func _ready() -> void:
	($Main_EarlyMenu/TabContainer/Welcome/TextureRect as TextureRect).texture = preload("res://contents/main_pdamenu/welcome_picture_0_blur.png")
	($Main_EarlyMenu/TabContainer/EULA/MarginContainer/RichTextLabel as RichTextLabel).get_v_scroll_bar().add_child(PDAMenu_ScrollCenter.CPS.instantiate())
	($Main_EarlyMenu/TabContainer/Installer/MarginContainer/VBoxContainer/ConsolePanel/OperationSelect/OperationTabs/Install/HBoxContainer/DifficultContainer/ScrollContainer as ScrollContainer).get_v_scroll_bar().add_child(PDAMenu_ScrollCenter.CPS.instantiate())
	($Main_EarlyMenu/TabContainer/Installer/MarginContainer/VBoxContainer/ConsolePanel/OperationSelect/OperationTabs/Install/HBoxContainer/AddonsContainer/ScrollContainer as ScrollContainer).get_v_scroll_bar().add_child(PDAMenu_ScrollCenter.CPS.instantiate())
	($Main_EarlyMenu/TabContainer/Installer/MarginContainer/VBoxContainer/ConsolePanel/Log/LogText as RichTextLabel).get_v_scroll_bar().add_child(PDAMenu_ScrollCenter.CPS.instantiate())
	($Main_EarlyMenu/TabContainer/Installer/MarginContainer/VBoxContainer/ConsolePanel/OperationSelect/OperationTabs/FileVerify/StartVerify as Button).add_theme_stylebox_override(&"normal", preload("res://contents/main_pdamenu/stylebox_for_installer_select_checks.tres"))
	($Main_EarlyMenu/TabContainer/Installer/MarginContainer/VBoxContainer/ConsolePanel/OperationSelect/OperationTabs/FileVerify/StartVerify as Button).add_theme_stylebox_override(&"hover", preload("res://contents/main_pdamenu/stylebox_hover_for_installer_select_checks.tres"))
	($Main_EarlyMenu/TabContainer/Installer/MarginContainer/VBoxContainer/ConsolePanel/OperationSelect/OperationTabs/FileVerify/StartVerify as Button).add_theme_stylebox_override(&"pressed", preload("res://contents/main_pdamenu/stylebox_pressed_for_installer_select_checks.tres"))
	($Main_EarlyMenu/TabContainer/Installer/MarginContainer/VBoxContainer/ConsolePanel/OperationSelect/OperationTabs/FileVerify/StartVerify as Button).add_theme_stylebox_override(&"focus", preload("res://contents/main_pdamenu/stylebox_focus_for_installer_select_checks.tres"))
	($Main_EarlyMenu/TabContainer/Installer/MarginContainer/VBoxContainer/ConsolePanel/OperationSelect/OperationTabs/FileVerify/StartVerify as Button).add_theme_stylebox_override(&"disabled", preload("res://contents/main_pdamenu/stylebox_disabled_for_installer_select_checks.tres"))

func _process(delta: float) -> void:
	if (mouse_grabbing):
		var window: Window = get_window()
		window.position = (DisplayServer.mouse_get_position() - mouse_pos_on_grab) + window_pos_on_grab

func _physics_process(delta: float) -> void:
	n_earlymenu.position = size * SUBMENU_POS_RATE
	n_earlymenu.size = size * SUBMENU_SIZE_RATE

#region 信号方法
## 抓取区域被按下时触发
func on_grab_area_down() -> void:
	mouse_grabbing = true
	mouse_pos_on_grab = DisplayServer.mouse_get_position()
	window_pos_on_grab = get_window().position

## 抓取区域被抬起时触发
func on_grab_area_up() -> void:
	mouse_grabbing = false

## 最小化被点击
func on_minimize_button_click() -> void:
	get_window().mode = Window.MODE_MINIMIZED

## 叉叉被点击
func on_close_button_click() -> void:
	n_earlymenu.quit_program()
#endregion
