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
@onready var n_state_refresh_button: Button = $TabContainer/Installer/MarginContainer/VBoxContainer/ConsolePanel/InstallInfo/Refresh as Button
@onready var n_state_game_not_found_text: Label = $TabContainer/Installer/MarginContainer/VBoxContainer/ConsolePanel/InstallInfo/GameNotFound as Label
@onready var n_line_edit_game_location: LineEdit = $TabContainer/Installer/MarginContainer/VBoxContainer/GameLocation/LineEditGameLocation as LineEdit
@onready var n_line_edit_pack_location: LineEdit = $TabContainer/Installer/MarginContainer/VBoxContainer/ModPackLocation/LineEditPackLocation as LineEdit
@onready var n_log_text: RichTextLabel = $TabContainer/Installer/MarginContainer/VBoxContainer/ConsolePanel/Log/LogText as RichTextLabel
@onready var n_operation_install_confirm_button: Button = $TabContainer/Installer/MarginContainer/VBoxContainer/ConsolePanel/OperationSelect/OperationTabs/Install/ConfirmInstall as Button


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
enum GameInfoState{
	SHOW, #显示状态详情
	NOT_FOUND, #未指定位置
	PATH_UNVALID, #指定的位置不可用
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

## 百川安装器
static var installer: BaiChuanInstaller = BaiChuanInstaller.new()

## 是否已同意EULA
var is_eula_agreed: bool = false:
	set(value):
		if (value and is_node_ready()):
			n_tab_container.set_tab_disabled(Tabs.INSTALLER, false) #解锁安装器

func _notification(what: int) -> void:
	match (what):
		NOTIFICATION_WM_CLOSE_REQUEST: #窗口关闭请求
			quit_program()

func _enter_tree() -> void:
	get_window().min_size = WINDOW_MIN_SIZE #设置窗口最小大小
	get_tree().auto_accept_quit = false #关闭自动应答退出行为

func _ready() -> void:
	n_tab_container.set_tab_disabled(Tabs.INSTALLER, true)
	for i in n_tabs.size(): #按索引遍历标签列表
		n_tab_container.set_tab_title(i, TabsNames[i]) #设置标签栏上标签的标题
	for i in n_installer_tabs.size(): #按索引遍历安装器标签列表
		n_installer_tab_container.set_tab_title(i, InstallerOperationTabsNames[i]) #设置安装器标签栏上标签的标题

## 程序关闭方法，此方法中要写临时目录的释放行为
func quit_program() -> void:
	get_tree().quit()

## 隐藏游戏状态信息，需指定目标状态
func hide_game_info(to_state: GameInfoState) -> void:
	n_state_game_not_found_text.visible = true
	n_state_info_text.visible = false
	n_state_refresh_button.visible = false
	match (to_state): #匹配目标状态
		GameInfoState.NOT_FOUND: #游戏未指定
			n_state_game_not_found_text.text = "未指定游戏位置"
		GameInfoState.PATH_UNVALID: #路径不可用
			n_state_game_not_found_text.text = "指定的位置不可用"

## 显示游戏状态信息
func show_game_info() -> void:
	n_state_game_not_found_text.visible = false
	n_state_info_text.visible = true
	n_state_refresh_button.visible = true
	refresh_game_info()

## 刷新游戏状态信息
func refresh_game_info() -> void:
	var game_state_report: BaiChuanInstaller.GameStateReport = installer.game_state_detect(n_line_edit_game_location.text)
	var text: String = "游戏版本验证\n[right]{0}[/right]\nBepInEx存在迹象\n[right]{1}[/right]\nQMods存在迹象\n[right]{2}[/right]\n百川安装状况\n[right]{3}[/right]"
	var text_version_verify: String
	match (game_state_report.game_version_verify): #匹配状态报告的游戏版本验证部分
		BaiChuanInstaller.GameStateReport.GameVersionVerify.ERROR: #如果验证结果为错误
			text_version_verify = "[color=red]发生错误[/color]"
		BaiChuanInstaller.GameStateReport.GameVersionVerify.NOT_FOUND: #如果验证结果为未找到
			text_version_verify = "[color=red]未找到游戏[/color]"
		BaiChuanInstaller.GameStateReport.GameVersionVerify.VERIFY_FAILED: #如果验证结果为失败
			text_version_verify = "[color=yellow]验证不通过[/color]"
		BaiChuanInstaller.GameStateReport.GameVersionVerify.VERIFY_SUCCESS: #如果验证结果为成功
			text_version_verify = "[color=green]验证通过[/color]"
	var text_bepinex_exist: String
	match (game_state_report.is_bepinex_exist): #匹配状态报告的BepInEx存在迹象
		true:
			text_bepinex_exist = "[color=green]是[/color]"
		false:
			text_bepinex_exist = "[color=red]否[/color]"
	var text_qmods_exist: String
	match (game_state_report.is_qmods_exist): #匹配状态报告的QMods存在迹象
		true:
			text_qmods_exist = "[color=green]是[/color]"
		false:
			text_qmods_exist = "[color=red]否[/color]"
	var text_baichuan_installed: String
	match (game_state_report.baichuan_installed): #匹配状态报告的百川安装状况
		BaiChuanInstaller.GameStateReport.BaiChuanInstalled.ERROR: #如果发生错误
			text_baichuan_installed = "[color=red]发生错误[/color]"
		BaiChuanInstaller.GameStateReport.BaiChuanInstalled.NO: #如果什么都不存在
			text_baichuan_installed = "[color=red]否[/color]"
		BaiChuanInstaller.GameStateReport.BaiChuanInstalled.HALF: #如果存在部分迹象
			text_baichuan_installed = "[color=yellow]部分[/color]"
		BaiChuanInstaller.GameStateReport.BaiChuanInstalled.FULL: #如果存在所有迹象
			text_baichuan_installed = "[color=green]是[/color]"
	n_state_info_text.text = text.format([text_version_verify, text_bepinex_exist, text_qmods_exist, text_baichuan_installed])

#region 界面元素触发函数
## 欢迎/继续
func welcome_continue() -> void:
	if (is_eula_agreed): #如果已同意EULA
		n_tab_container.current_tab = Tabs.INSTALLER #将主选项卡焦点切换到安装器
	else: #否则(未同意EULA)
		n_tab_container.current_tab = Tabs.EULA #将主选项卡焦点切换到EULA

## EULA/拒绝
func eula_reject() -> void:
	quit_program()

## EULA/同意
func eula_agree() -> void:
	is_eula_agreed = true #将EULA已同意设为true
	n_eula_agree_bar.visible = false #使EULA同意栏不可见

## 安装器/自动寻找游戏位置
func installer_auto_find_game() -> void:
	var path_got: String = installer.search_game() #调用安装器获取游戏路径
	if (not path_got.is_empty()): #如果获得的路径为空表示没有找到，反之则找到了
		n_line_edit_game_location.text = path_got #将路径填充到填写框里
	refresh_log() #刷新日志
	installer_gamepath_lose_focus()

## 安装器/解压并加载安装包
func installer_unpack_and_load_install_pack() -> void:
	pass

## 安装器/状态/刷新
func installer_state_refresh() -> void:
	installer_gamepath_lose_focus()
	refresh_game_info()
	refresh_log() #刷新日志

## 安装器/安装/确认安装
func installer_install_confirm() -> void:
	pass

## 安装器/卸载/确认卸载
func installer_uninstall_confirm() -> void:
	pass

## 安装器/验证/开始验证
func installer_verify_start() -> void:
	pass

## 安装器/游戏路径提交
func installer_gamepath_submit(new_text: String) -> void:
	if (new_text.is_empty()): #如果为空
		n_game_tip_text.text = "若要进行操作，必须指定游戏位置"
		n_game_tip_text.modulate = Color.RED
		hide_game_info(GameInfoState.NOT_FOUND)
		return
	if (not new_text.is_absolute_path() or new_text.get_file() != "Subnautica.exe"): #如果内容不是绝对路径或不是指向Subnautica.exe的路径
		n_game_tip_text.text = "需填写一个指向Subnautica.exe的绝对路径"
		n_game_tip_text.modulate = Color.RED
		hide_game_info(GameInfoState.PATH_UNVALID)
		return
	if (not FileAccess.file_exists(new_text)): #如果文件不存在
		n_game_tip_text.text = "路径指向的文件不存在或不可见"
		n_game_tip_text.modulate = Color.RED
		hide_game_info(GameInfoState.PATH_UNVALID)
		return
	if (not installer.verify_md5(new_text)): #如果指定的路径不通过md5验证
		n_game_tip_text.text = "未通过哈希校验，可能原因：游戏版本不是68598、游戏文件损坏"
		n_game_tip_text.modulate = Color.YELLOW
		show_game_info()
		return
	else: #否则(指定的路径通过了md5验证)
		n_game_tip_text.text = "就绪"
		n_game_tip_text.modulate = Color.GREEN
		show_game_info()
	refresh_log() #刷新日志

## 安装器/游戏路径失去焦点
func installer_gamepath_lose_focus() -> void:
	installer_gamepath_submit(n_line_edit_game_location.text)

## 安装器/安装包路径提交
func installer_packpath_submit(new_text: String) -> void:
	pass

## 安装器/安装包路径失去焦点
func installer_packpath_lose_focus() -> void:
	installer_packpath_submit(n_line_edit_pack_location.text)

## 刷新日志，在任何(可能)能够影响日志的菜单元素被触发以后均调用此方法，由其他连接了信号的方法调用
func refresh_log() -> void:
	n_log_text.text = installer.log #将安装器的日志内容传递到本实例
#endregion
