extends TextureRect
class_name Main_PDAMenu
## PDA美化主菜单，其实就是给早期主菜单套一层壳，本类就是实现这层壳

@onready var n_grab_area: TextureButton = $GrabArea as TextureButton
@onready var n_earlymenu: Main_EarlyMenu = $Main_EarlyMenu as Main_EarlyMenu

@onready var n_audio_click_small: AudioStreamPlayer = $Audio_ClickSmall as AudioStreamPlayer
@onready var n_audio_click_medium: AudioStreamPlayer = $Audio_ClickMedium as AudioStreamPlayer
@onready var n_audio_click_large: AudioStreamPlayer = $Audio_ClickLarge as AudioStreamPlayer
@onready var n_audio_open: AudioStreamPlayer = $Audio_Open as AudioStreamPlayer
@onready var n_audio_close: AudioStreamPlayer = $Audio_Close as AudioStreamPlayer
@onready var n_audio_scan: AudioStreamPlayer = $Audio_Scan as AudioStreamPlayer
@onready var n_audio_warn: AudioStreamPlayer = $Audio_Warn as AudioStreamPlayer
@onready var n_audio_error: AudioStreamPlayer = $Audio_Error as AudioStreamPlayer
@onready var n_audio_success: AudioStreamPlayer = $Audio_Success as AudioStreamPlayer

## 子菜单坐标比率(用于position)，基于本场景根节点size属性
const SUBMENU_POS_RATE: Vector2 = Vector2(365.0 / 1280.0, 135.0 / 921.0)
## 子菜单尺寸比率(用于size)，基于本场景根节点size属性
const SUBMENU_SIZE_RATE: Vector2 = Vector2(1260.0 / 1280.0, 1020.0 / 921.0)
## 窗口占据主屏幕尺寸的比率
const WINDOW_SIZE_OF_SCREEN: float = 0.85

#const GRAB_AREA_POS_OF_VIEWPORT: Vector2 = Vector2(35.0 / 1280.0, 32.0 / 921.0)
#const GRAB_AREA_SIZE_OF_VIEWPORT: Vector2 = Vector2(225.0 / 1280.0, 857.0 / 921.0)
#const WINDOW_BUTTON_POS_OF_VIEWPORT: Vector2 = Vector2(1100.0 / 1280.0, 75.0 / 921.0)
#const WINDOW_BUTTON_SIZE_OF_VIEWPORT: Vector2 = Vector2(90.0 / 1280.0, 43.0 / 921.0)
#const EARLY_MENU_POS_OF_VIEWPORT: Vector2 = Vector2(365.0 / 1280.0, 135.0 / 921.0)
#const EARLY_MENU_SIZE_OF_VIEWPORT: Vector2 = Vector2(819.0 / 1280.0, 663.0 / 921.0)
#const WINDOW_BUTTON_FONT_SIZE_OF_VIEWPORT_X: float = 25.0 / 1280.0
#const EARLY_MENU_SCALE_DEFAULT: Vector2 = Vector2(0.65, 0.65)

var mouse_grabbing: bool = false
var mouse_pos_on_grab: Vector2i = Vector2i.ZERO
var window_pos_on_grab: Vector2i = Vector2i.ZERO

func _ready() -> void:
	var window: Window = get_window()
	var x_multi: float = float(window.size.x) / float(DisplayServer.screen_get_size(DisplayServer.get_primary_screen()).x)
	var y_multi: float = float(window.size.y) / float(DisplayServer.screen_get_size(DisplayServer.get_primary_screen()).y)
	var use_multi: float = 1.0 / maxf(x_multi, y_multi)
	window.size = Vector2i(window.size * use_multi * WINDOW_SIZE_OF_SCREEN)
	window.position /= 2.0
	#n_grab_area.size = GRAB_AREA_SIZE_OF_VIEWPORT * Vector2(window.size)
	#n_grab_area.position = GRAB_AREA_POS_OF_VIEWPORT * Vector2(window.size)
	#($WindowButton as HBoxContainer).size = WINDOW_BUTTON_SIZE_OF_VIEWPORT * Vector2(window.size)
	#($WindowButton as HBoxContainer).position = WINDOW_BUTTON_POS_OF_VIEWPORT * Vector2(window.size)
	#($WindowButton/Close as Button).add_theme_font_size_override(&"font_size", int(WINDOW_BUTTON_FONT_SIZE_OF_VIEWPORT_X * window.size.x))
	#($WindowButton/Minimize as Button).add_theme_font_size_override(&"font_size", int(WINDOW_BUTTON_FONT_SIZE_OF_VIEWPORT_X * window.size.x))
	#n_earlymenu.size = Vector2(window.size) / EARLY_MENU_SIZE_OF_VIEWPORT
	#n_earlymenu.scale = EARLY_MENU_SCALE_DEFAULT / use_multi * WINDOW_SIZE_OF_SCREEN
	#n_earlymenu.position = EARLY_MENU_POS_OF_VIEWPORT * Vector2(window.size)
	## 00主题修补
	($Main_EarlyMenu/TabContainer/Welcome/PanelContainer/TextureRect as TextureRect).texture = preload("res://contents/main_pdamenu/welcome_picture_0_blur.png")
	($Main_EarlyMenu/TabContainer/EULA/MarginContainer/RichTextLabel as RichTextLabel).get_v_scroll_bar().add_child(PDAMenu_ScrollCenter.CPS.instantiate())
	($Main_EarlyMenu/TabContainer/Installer/MarginContainer/VBoxContainer/ConsolePanel/OperationSelect/OperationTabs/Install/HBoxContainer/DifficultContainer/ScrollContainer as ScrollContainer).get_v_scroll_bar().add_child(PDAMenu_ScrollCenter.CPS.instantiate())
	($Main_EarlyMenu/TabContainer/Installer/MarginContainer/VBoxContainer/ConsolePanel/OperationSelect/OperationTabs/Install/HBoxContainer/AddonsContainer/ScrollContainer as ScrollContainer).get_v_scroll_bar().add_child(PDAMenu_ScrollCenter.CPS.instantiate())
	($Main_EarlyMenu/TabContainer/Installer/MarginContainer/VBoxContainer/ConsolePanel/Log/LogText as RichTextLabel).get_v_scroll_bar().add_child(PDAMenu_ScrollCenter.CPS.instantiate())
	($Main_EarlyMenu/TabContainer/Launcher/VBC/HBC/VBC_LogAndConfirm/Log as RichTextLabel).get_v_scroll_bar().add_child(PDAMenu_ScrollCenter.CPS.instantiate())
	($Main_EarlyMenu/TabContainer/Installer/MarginContainer/VBoxContainer/ConsolePanel/OperationSelect/OperationTabs/FileVerify/StartVerify as Button).add_theme_stylebox_override(&"normal", preload("res://contents/main_pdamenu/stylebox_for_installer_select_checks.tres"))
	($Main_EarlyMenu/TabContainer/Installer/MarginContainer/VBoxContainer/ConsolePanel/OperationSelect/OperationTabs/FileVerify/StartVerify as Button).add_theme_stylebox_override(&"hover", preload("res://contents/main_pdamenu/stylebox_hover_for_installer_select_checks.tres"))
	($Main_EarlyMenu/TabContainer/Installer/MarginContainer/VBoxContainer/ConsolePanel/OperationSelect/OperationTabs/FileVerify/StartVerify as Button).add_theme_stylebox_override(&"pressed", preload("res://contents/main_pdamenu/stylebox_pressed_for_installer_select_checks.tres"))
	($Main_EarlyMenu/TabContainer/Installer/MarginContainer/VBoxContainer/ConsolePanel/OperationSelect/OperationTabs/FileVerify/StartVerify as Button).add_theme_stylebox_override(&"focus", preload("res://contents/main_pdamenu/stylebox_focus_for_installer_select_checks.tres"))
	($Main_EarlyMenu/TabContainer/Installer/MarginContainer/VBoxContainer/ConsolePanel/OperationSelect/OperationTabs/FileVerify/StartVerify as Button).add_theme_stylebox_override(&"disabled", preload("res://contents/main_pdamenu/stylebox_disabled_for_installer_select_checks.tres"))
	## /00
	## 01声音订阅信号
	($Main_EarlyMenu/TabContainer as TabContainer).tab_changed.connect(
		func(_i: int) -> void:
			n_audio_click_large.play()
	)
	#($Main_EarlyMenu/TabContainer/Welcome/ContinueButton as Button).pressed.connect(n_audio_click_medium.play)
	($Main_EarlyMenu/TabContainer/EULA/AgreeButtonBar/RejectButton as Button).pressed.connect(n_audio_click_medium.play)
	($Main_EarlyMenu/TabContainer/EULA/AgreeButtonBar/AgreeButton as Button).pressed.connect(n_audio_click_medium.play)
	n_earlymenu.game_location_autofind.connect(
		func(success: bool) -> void:
			if (success):
				n_audio_scan.play()
				return
			n_audio_error.play()
	)
	var click_medium_audio_play: Callable = func(_i: int) -> void:
		n_audio_click_medium.play()
	($Main_EarlyMenu/TabContainer/Installer/MarginContainer/VBoxContainer/ConsolePanel/OperationSelect/OperationTabs as TabContainer).tab_changed.connect(click_medium_audio_play)
	($Main_EarlyMenu/TabContainer/Launcher/VBC/HBC/VBC_LogAndConfirm/TabBar as TabBar).tab_changed.connect(click_medium_audio_play)
	($Main_EarlyMenu/TabContainer/Installer/MarginContainer/VBoxContainer/ConsolePanel/InstallInfo/Refresh as Button).pressed.connect(n_audio_click_medium.play)
	($Main_EarlyMenu/TabContainer/Installer/MarginContainer/VBoxContainer/ConsolePanel/OperationSelect/OperationTabs/Install/ReinstallCheck as CheckBox).pressed.connect(n_audio_click_small.play)
	var click_small_audio_play: Callable = func(_index: int) -> void:
		n_audio_click_small.play()
	n_earlymenu.install_option_difficult_clicked.connect(click_small_audio_play)
	n_earlymenu.install_option_addon_clicked.connect(click_small_audio_play)
	n_earlymenu.launch_option_difficult_clicked.connect(click_small_audio_play)
	n_earlymenu.launch_option_addon_clicked.connect(click_small_audio_play)
	($Main_EarlyMenu/TabContainer/Installer/MarginContainer/VBoxContainer/ConsolePanel/OperationSelect/OperationTabs/Install/ConfirmInstall as Button).pressed.connect(n_audio_click_medium.play)
	($Main_EarlyMenu/TabContainer/Installer/MarginContainer/VBoxContainer/ConsolePanel/OperationSelect/OperationTabs/Uninstall/CheckBox as CheckBox).pressed.connect(n_audio_click_small.play)
	($Main_EarlyMenu/TabContainer/Installer/MarginContainer/VBoxContainer/ConsolePanel/OperationSelect/OperationTabs/Uninstall/ConfirmUninstall as Button).pressed.connect(n_audio_click_medium.play)
	($Main_EarlyMenu/TabContainer/Installer/MarginContainer/VBoxContainer/ConsolePanel/OperationSelect/OperationTabs/FileVerify/StartVerify as Button).pressed.connect(n_audio_click_medium.play)
	n_earlymenu.new_warn.connect(n_audio_warn.play)
	n_earlymenu.new_error.connect(n_audio_error.play)
	n_earlymenu.operation_finished.connect(
		func(success: bool) -> void:
			if (success):
				n_audio_success.play()
	)
	## /01
	n_audio_open.play()

func _process(_delta: float) -> void:
	if (mouse_grabbing):
		var window: Window = get_window()
		window.position = (DisplayServer.mouse_get_position() - mouse_pos_on_grab) + window_pos_on_grab

func _physics_process(_delta: float) -> void:
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
	n_audio_close.play()
	get_window().focus_entered.connect(on_window_cancel_minimized, CONNECT_ONE_SHOT)

## 叉叉被点击
func on_close_button_click() -> void:
	n_audio_close.play()
	get_window().mode = Window.MODE_MINIMIZED
	n_audio_close.finished.connect(quit_program_after_sound_played, CONNECT_ONE_SHOT)

## 用于在退出音效播放完毕后退出程序的方法
func quit_program_after_sound_played() -> void:
	n_earlymenu.quit_program()

## 窗口离开最小化
func on_window_cancel_minimized() -> void:
	n_audio_open.play()
#endregion
