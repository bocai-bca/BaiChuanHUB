extends PanelContainer
class_name Main_EarlyMenu
## 早期版主菜单

@onready var n_tab_container: TabContainer = $TabContainer as TabContainer
@onready var n_tabs: Dictionary[Tabs, Control] = {
	Tabs.WELCOME: $TabContainer/Welcome as Control,
	Tabs.EULA: $TabContainer/EULA as Control,
	Tabs.INSTALLER: $TabContainer/Installer as Control,
}
@onready var n_installer_tab_container: TabContainer = $TabContainer/Installer/MarginContainer/VBoxContainer/ConsolePanel/OperationSelect/OperationTabs as TabContainer
@onready var n_installer_tabs: Dictionary[InstallerTabs, Control] = {
	InstallerTabs.INSTALL: $TabContainer/Installer/MarginContainer/VBoxContainer/ConsolePanel/OperationSelect/OperationTabs/Install as Control,
	InstallerTabs.UNINSTALL: $TabContainer/Installer/MarginContainer/VBoxContainer/ConsolePanel/OperationSelect/OperationTabs/Uninstall as Control,
	InstallerTabs.FILE_VERIFY: $TabContainer/Installer/MarginContainer/VBoxContainer/ConsolePanel/OperationSelect/OperationTabs/FileVerify as Control,
}
@onready var n_eula_agree_bar: HBoxContainer = $TabContainer/EULA/AgreeButtonBar as HBoxContainer
@onready var n_eula_agree_button: Button = $TabContainer/EULA/AgreeButtonBar/AgreeButton as Button
@onready var n_game_tip_text: Label = $TabContainer/Installer/MarginContainer/VBoxContainer/GameTipText as Label
@onready var n_mod_pack_tip_text: Label = $TabContainer/Installer/MarginContainer/VBoxContainer/ModPackTipText as Label
@onready var n_state_info_text: RichTextLabel = $TabContainer/Installer/MarginContainer/VBoxContainer/ConsolePanel/InstallInfo/Info as RichTextLabel
@onready var n_state_game_not_found: Label = $TabContainer/Installer/MarginContainer/VBoxContainer/ConsolePanel/InstallInfo/GameNotFound as Label


## 最小窗口大小
const WINDOW_MIN_SIZE: Vector2i = Vector2i(1280, 720)
enum Tabs{
	WELCOME = 0, #欢迎
	EULA = 1, #最终用户许可协议
	INSTALLER = 2, #安装器
}
enum InstallerTabs{
	INSTALL = 0, #安装
	UNINSTALL = 1, #卸载
	FILE_VERIFY = 2, #文件校验
}
const TabsNames: PackedStringArray = [
	"欢迎",
	"最终用户许可协议",
	"百川归海安装器",
]
const InstallerOperationTabsNames: PackedStringArray = [
	"安装",
	"卸载",
	"文件校验",
]

## 是否已同意EULA
var is_eula_agreed: bool = false:
	set(value):
		if (value and is_node_ready()):
			n_tab_container.set_tab_disabled(Tabs.INSTALLER, false) #解锁安装器

func _enter_tree() -> void:
	get_window().min_size = WINDOW_MIN_SIZE #设置窗口最小大小

func _ready() -> void:
	n_eula_agree_button.pressed.connect(
		func() -> void:
			is_eula_agreed = true #将EULA已同意设为true
			n_eula_agree_bar.visible = false #使EULA同意栏不可见
	)
	n_tab_container.set_tab_disabled(Tabs.INSTALLER, true)
	for i in n_tabs.size(): #按索引遍历标签列表
		n_tab_container.set_tab_title(i, TabsNames[i]) #设置标签栏上标签的标题
	for i in n_installer_tabs.size(): #按索引遍历安装器标签列表
		n_installer_tab_container.set_tab_title(i, InstallerOperationTabsNames[i]) #设置安装器标签栏上标签的标题
