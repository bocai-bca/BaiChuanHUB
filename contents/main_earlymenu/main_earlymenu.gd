extends PanelContainer
class_name Main_EarlyMenu
## 早期版主菜单

## 信号-执行游戏位置自动寻找后发出，附带成功与否
signal game_location_autofind(success: bool)
## 信号-安装选项任意一个难度按钮被点击时发出，附带被点击的按钮的索引
signal install_option_difficult_clicked(index: int)
## 信号-安装选项任意一个附属包按钮被点击时发出，附带被点击的按钮的索引
signal install_option_addon_clicked(index: int)
## 信号-日志中出现新警告时发出
signal new_warn()
## 信号-日志中出现新错误时发出
signal new_error()
## 信号-执行操作完成后发出，附带成功与否
signal operation_finished(success: bool)

@onready var n_tab_container: TabContainer = $TabContainer as TabContainer
@onready var n_tabs: Dictionary[Tabs, Control] = {
	Tabs.WELCOME: $TabContainer/Welcome as Control,
	Tabs.EULA: $TabContainer/EULA as Control,
	Tabs.INSTALLER: $TabContainer/Installer as Control,
	Tabs.DOCS: $TabContainer/Docs as Control,
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
@onready var n_open_zip_button: Button = $TabContainer/Installer/MarginContainer/VBoxContainer/ModPackLocation/OpenZIPButton as Button
@onready var n_operation_install_reinstall_checkbox: CheckBox = $TabContainer/Installer/MarginContainer/VBoxContainer/ConsolePanel/OperationSelect/OperationTabs/Install/ReinstallCheck as CheckBox
@onready var n_operation_install_confirm_button: Button = $TabContainer/Installer/MarginContainer/VBoxContainer/ConsolePanel/OperationSelect/OperationTabs/Install/ConfirmInstall as Button
@onready var n_operation_install_option_difficults_container: VBoxContainer = $TabContainer/Installer/MarginContainer/VBoxContainer/ConsolePanel/OperationSelect/OperationTabs/Install/HBoxContainer/DifficultContainer/ScrollContainer/DifficultsNodesContainer as VBoxContainer
@onready var n_operation_install_option_addons_container: VBoxContainer = $TabContainer/Installer/MarginContainer/VBoxContainer/ConsolePanel/OperationSelect/OperationTabs/Install/HBoxContainer/AddonsContainer/ScrollContainer/AddonsNodesContainer as VBoxContainer
@onready var n_operation_uninstall_keep_framework_checkbox: CheckBox = $TabContainer/Installer/MarginContainer/VBoxContainer/ConsolePanel/OperationSelect/OperationTabs/Uninstall/CheckBox as CheckBox
@onready var n_operation_uninstall_confirm_button: Button = $TabContainer/Installer/MarginContainer/VBoxContainer/ConsolePanel/OperationSelect/OperationTabs/Uninstall/ConfirmUninstall as Button
@onready var n_docs_pack_not_loaded_label: Label = $TabContainer/Docs/PackNotLoaded as Label
@onready var n_docs_notice_label: Label = $TabContainer/Docs/Notice as Label
@onready var n_docs_search_bar: HBoxContainer = $TabContainer/Docs/SearchBar as HBoxContainer
@onready var n_docs_object_list: VBoxContainer = $TabContainer/Docs/ObjectList as VBoxContainer
@onready var n_docs_more_content_tip_label: Label = $TabContainer/Docs/Label as Label

## 最小窗口大小
const WINDOW_MIN_SIZE: Vector2i = Vector2i(1280, 921)
enum Tabs{
	WELCOME = 0, #欢迎
	EULA = 1, #最终用户许可协议
	INSTALLER = 2, #安装器
	DOCS = 3, #文档
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
	"使用协议",
	"安装器",
	"文档"
]
const InstallerOperationTabsNames: PackedStringArray = [
	"安装",
	"卸载",
	"文件校验",
]
## 安装选项的难度按钮组
const DIFFICULT_BUTTON_GROUP: ButtonGroup = preload("res://contents/main_earlymenu/difficult_button_group.tres")

## 百川安装器
static var installer: BaiChuanInstaller = BaiChuanInstaller.new()

## 使用捆绑式安装包
static var use_builtin_pack: bool = true

## 是否已同意EULA
var is_eula_agreed: bool = false:
	set(value):
		if (value and is_node_ready()):
			n_tab_container.set_tab_disabled(Tabs.INSTALLER, false) #解锁安装器
			n_tab_container.set_tab_disabled(Tabs.DOCS, false) #解锁文档
		is_eula_agreed = value
## 游戏路径指定是否已就绪
var is_game_path_ready: bool = false
## 安装包是否已加载成功
var is_pack_load_success: bool = false:
	set(value):
		if (value):
			n_docs_pack_not_loaded_label.visible = false
			n_docs_notice_label.visible = true
			n_docs_object_list.visible = true
			n_docs_search_bar.visible = true
			n_docs_more_content_tip_label.visible = true
		else:
			n_docs_pack_not_loaded_label.visible = true
			n_docs_notice_label.visible = false
			n_docs_object_list.visible = false
			n_docs_search_bar.visible = false
			n_docs_more_content_tip_label.visible = false
		is_pack_load_success = value
## 包元数据缓存
var meta_report: BaiChuanInstaller.PackMetaReport
## 安装选项难度节点列表
var install_option_difficults_nodes: Array[EarlyMenu_DifficultSelectCheckBox] = []
## 安装选项附属包节点列表
var install_option_addons_nodes: Array[EarlyMenu_AddonSelectCheckBox] = []
## 当前指定的安装难度索引号，-1代表无效
var install_option_difficult_current: int = -1
## 当前勾选的所有待安装附属包索引号
var install_option_addons_current: PackedInt32Array = []
## 安装选项重新安装
var install_option_reinstall: bool = false
## 安装器是否正在执行某个操作(如安装、卸载)
var is_operating: bool = false

func _notification(what: int) -> void:
	match (what):
		NOTIFICATION_WM_CLOSE_REQUEST: #窗口关闭请求
			quit_program()

func _enter_tree() -> void:
	get_window().min_size = WINDOW_MIN_SIZE #设置窗口最小大小
	get_tree().auto_accept_quit = false #关闭自动应答退出行为

func _ready() -> void:
	n_tab_container.set_tab_disabled(Tabs.INSTALLER, true)
	n_tab_container.set_tab_disabled(Tabs.DOCS, true)
	n_tab_container.get_tab_bar().mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for i in n_tabs.size(): #按索引遍历标签列表
		n_tab_container.set_tab_title(i, TabsNames[i]) #设置标签栏上标签的标题
	for i in n_installer_tabs.size(): #按索引遍历安装器标签列表
		n_installer_tab_container.set_tab_title(i, InstallerOperationTabsNames[i]) #设置安装器标签栏上标签的标题
	if (use_builtin_pack):
		n_line_edit_pack_location.editable = false
		n_line_edit_pack_location.placeholder_text = "手动指定已禁用，将自动使用捆绑式安装包"
		n_open_zip_button.disabled = true
		var load_path: String = OS.get_executable_path().get_base_dir().path_join("pack")
		print("加载捆绑式安装包：", load_path)
		load_install_pack(load_path)
		place_install_option_nodes()
		update_install_confirm_button()

func _physics_process(_delta: float) -> void:
	if (is_operating):
		refresh_log()
		if (not installer.thread.is_alive()):
			is_operating = false
			n_operation_install_confirm_button.disabled = false
			n_operation_uninstall_confirm_button.disabled = false
			refresh_game_info()
			emit_signal(&"operation_finished", installer.thread.wait_to_finish())

## 程序关闭方法，此方法中要写临时目录的释放行为
func quit_program() -> void:
	if (installer.thread.is_started()):
		installer.thread.wait_to_finish()
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
	match (game_state_report.bepinex_installed): #匹配状态报告的BepInEx存在迹象
		BaiChuanInstaller.GameStateReport.BepInExInstalled.ERROR: #如果发生错误
			text_bepinex_exist = "[color=red]发生错误[/color]"
		BaiChuanInstaller.GameStateReport.BepInExInstalled.NO: #如果什么都不存在
			text_bepinex_exist = "[color=red]否[/color]"
		BaiChuanInstaller.GameStateReport.BepInExInstalled.HALF: #如果存在部分迹象
			text_bepinex_exist = "[color=yellow]部分[/color]"
		BaiChuanInstaller.GameStateReport.BepInExInstalled.FULL: #如果存在所有迹象
			text_bepinex_exist = "[color=green]是[/color]"
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
			n_operation_uninstall_confirm_button.text = "卸载\n不可用"
			n_operation_uninstall_confirm_button.disabled = true
			n_operation_uninstall_confirm_button.mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN
		BaiChuanInstaller.GameStateReport.BaiChuanInstalled.NO: #如果什么都不存在
			text_baichuan_installed = "[color=red]否[/color]"
			n_operation_uninstall_confirm_button.text = "卸载\n不可用"
			n_operation_uninstall_confirm_button.disabled = true
			n_operation_uninstall_confirm_button.mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN
		BaiChuanInstaller.GameStateReport.BaiChuanInstalled.HALF: #如果存在部分迹象
			text_baichuan_installed = "[color=yellow]部分[/color]"
			n_operation_uninstall_confirm_button.text = "卸载\n不可用"
			n_operation_uninstall_confirm_button.disabled = true
			n_operation_uninstall_confirm_button.mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN
		BaiChuanInstaller.GameStateReport.BaiChuanInstalled.FULL: #如果存在所有迹象
			text_baichuan_installed = "[color=green]{0} {1} {2}附属[/color]".format([game_state_report.baichuan_installed_version_name, game_state_report.baichuan_installed_difficult_name, str(game_state_report.baichuan_installed_addons_count)])
			n_operation_uninstall_confirm_button.text = "卸载\n{0}、{1}、{2}个附属包".format([game_state_report.baichuan_installed_version_name, game_state_report.baichuan_installed_difficult_name, str(game_state_report.baichuan_installed_addons_count)])
			n_operation_uninstall_confirm_button.disabled = false
			n_operation_uninstall_confirm_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	n_state_info_text.text = text.format([text_version_verify, text_bepinex_exist, text_qmods_exist, text_baichuan_installed])

## 加载安装包
func load_install_pack(pack_path: String) -> void:
	is_pack_load_success = false
	pack_path = pack_path.trim_prefix("\"").trim_suffix("\"") #去除引号
	if (not use_builtin_pack):
		n_line_edit_pack_location.text = pack_path
	if (not pack_path.is_absolute_path()): #如果输入不是可用的绝对路径
		n_mod_pack_tip_text.text = "需填写一个指向安装包的绝对路径"
		n_mod_pack_tip_text.modulate = Color.RED
		refresh_log() #刷新日志
		return
	match (use_builtin_pack):
		true:
			if (not DirAccess.dir_exists_absolute(pack_path)): #如果文件夹不存在
				n_mod_pack_tip_text.text = "捆绑式安装包丢失"
				if (OS.get_executable_path().contains("/AppData/Local/Temp/")): #如果发现在临时目录中执行
					n_mod_pack_tip_text.text = "捆绑式安装包丢失。请将压缩包所有内容一起解压至妥善位置后再打开本exe，不要在解压软件界面中直接打开"
				n_mod_pack_tip_text.modulate = Color.RED
				refresh_log() #刷新日志
				return
			meta_report = installer.load_new_pack(pack_path, false)
			if (meta_report == null): #如果加载失败
				n_mod_pack_tip_text.text = "捆绑式安装包加载失败"
				if (use_builtin_pack):
					n_mod_pack_tip_text.text = "捆绑式安装包加载失败"
				n_mod_pack_tip_text.modulate = Color.RED
				refresh_log() #刷新日志
				return
			is_pack_load_success = true
			n_mod_pack_tip_text.text = "捆绑式安装包就绪：版本" + meta_report.version_name + "(v" + str(meta_report.version) + "." + str(meta_report.fork_version) + ")，包含" + str(meta_report.difficults_names.size()) + "个难度、" + str(meta_report.mods_count) + "个模组、" + str(meta_report.addons.size()) + "个附属包"
			n_mod_pack_tip_text.modulate = Color.GREEN
		false:
			if (not FileAccess.file_exists(pack_path)): #如果文件不存在
				n_mod_pack_tip_text.text = "路径指向的文件不存在或不可见"
				n_mod_pack_tip_text.modulate = Color.RED
				refresh_log() #刷新日志
				return
			meta_report = installer.load_new_pack(pack_path, true)
			if (meta_report == null): #如果加载失败
				n_mod_pack_tip_text.text = "安装包加载失败"
				n_mod_pack_tip_text.modulate = Color.RED
				refresh_log() #刷新日志
				return
			is_pack_load_success = true
			n_mod_pack_tip_text.text = "安装包就绪: 版本" + meta_report.version_name + "(v" + str(meta_report.version) + "." + str(meta_report.fork_version) + ")，包含" + str(meta_report.difficults_names.size()) + "个难度、" + str(meta_report.mods_count) + "个模组、" + str(meta_report.addons.size()) + "个附属包"
			n_mod_pack_tip_text.modulate = Color.GREEN
	refresh_log() #刷新日志

## 放置安装选项节点
func place_install_option_nodes() -> void:
	## 00清除旧节点
	for node in install_option_difficults_nodes + install_option_addons_nodes: #遍历所有选项
		node.queue_free()
	install_option_difficults_nodes = []
	install_option_addons_nodes = []
	## /00
	## 01放置新节点
	if (meta_report == null): #如果元数据报告为null
		return
	for i in meta_report.difficults_names.size(): #按索引遍历所有难度名称
		var new_check_box: EarlyMenu_DifficultSelectCheckBox = EarlyMenu_DifficultSelectCheckBox.CPS.instantiate() as EarlyMenu_DifficultSelectCheckBox
		new_check_box.text = meta_report.difficults_names[i]
		new_check_box.difficult_index = i
		new_check_box.pressed.connect(
			func() -> void:
				install_option_difficult_current = new_check_box.difficult_index
				update_install_addons_checkboxes_disable()
				update_install_confirm_button()
				emit_signal(&"install_option_difficult_clicked", i)
		)
		install_option_difficults_nodes.append(new_check_box)
		n_operation_install_option_difficults_container.add_child(new_check_box)
	for i in meta_report.addons.size(): #按索引遍历所有附属包名称
		var new_check_box: EarlyMenu_AddonSelectCheckBox = EarlyMenu_AddonSelectCheckBox.CPS.instantiate() as EarlyMenu_AddonSelectCheckBox
		new_check_box.text = meta_report.addons[i].name
		new_check_box.addon_index = i
		new_check_box.support_difficults = meta_report.addons[i].support_difficults
		new_check_box.pressed.connect(
			func() -> void:
				if (new_check_box.button_pressed): #如果按钮处于按下状态(正被勾选)
					if (not install_option_addons_current.has(new_check_box.addon_index)): #如果附属包待安装列表里没记录本按钮的索引
						install_option_addons_current.append(new_check_box.addon_index) #将本按钮的索引添加到附属包待安装列表
				else: #否则(按钮不处于按下状态(未被勾选))
					while (install_option_addons_current.has(new_check_box.addon_index)): #循环直到附属包待安装列表里不再有记录本按钮的索引
						var find_result: int = install_option_addons_current.find(new_check_box.addon_index)
						if (find_result == -1):
							break
						install_option_addons_current.remove_at(find_result)
				update_install_confirm_button()
				emit_signal(&"install_option_addon_clicked", i)
		)
		install_option_addons_nodes.append(new_check_box)
		n_operation_install_option_addons_container.add_child(new_check_box)
	## /01

## 更新附属包禁用(基于当前所选的难度，如果当前没有所选难度，将启用所有支持通配难度的附属包)
func update_install_addons_checkboxes_disable() -> void:
	for checkbox in install_option_addons_nodes: #遍历所有附属包节点
		if (checkbox.if_difficult_disable(install_option_difficult_current)): #调用按钮的自禁用检查方法，并获取执行之后按钮的开关状态
			## 正被勾选
			if (not install_option_addons_current.has(checkbox.addon_index)): #如果附属包待安装列表里没记录本按钮的索引
				install_option_addons_current.append(checkbox.addon_index) #将本按钮的索引添加到附属包待安装列表
		else:
			## 未被勾选或因被禁用而关闭
			while (install_option_addons_current.has(checkbox.addon_index)): #循环直到附属包待安装列表里不再有记录本按钮的索引
				var find_result: int = install_option_addons_current.find(checkbox.addon_index)
				if (find_result == -1):
					break
				install_option_addons_current.remove_at(find_result)

## 更新安装确认按钮
func update_install_confirm_button() -> void:
	if (is_operating):
		return
	if (not is_game_path_ready): #如果游戏路径尚未就绪
		n_operation_install_confirm_button.disabled = true
		n_operation_install_confirm_button.text = "请先设置游戏位置以确定安装位置"
		n_operation_install_confirm_button.mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN
	elif (not is_pack_load_success): #如果安装包没有加载完成
		n_operation_install_confirm_button.disabled = true
		n_operation_install_confirm_button.text = "安装包未加载"
		n_operation_install_confirm_button.mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN
	elif (install_option_difficult_current != -1):
		n_operation_install_confirm_button.disabled = false
		n_operation_install_confirm_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var install_text_prefix: String
		install_text_prefix = "覆盖安装：" if install_option_reinstall else "开始安装："
		n_operation_install_confirm_button.text = install_text_prefix + meta_report.version_name + "、" + meta_report.difficults_names[install_option_difficult_current] + "、" + str(install_option_addons_current.size()) + "个附属包"
	else:
		n_operation_install_confirm_button.disabled = true
		n_operation_install_confirm_button.text = "请选择难度"
		n_operation_install_confirm_button.mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN

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
	#n_tab_container.current_tab = Tabs.INSTALLER #将主选项卡焦点切换到安装器

## 安装器/自动寻找游戏位置
func installer_auto_find_game() -> void:
	var path_got: String = installer.search_game() #调用安装器获取游戏路径
	if (path_got.is_empty()): #如果获得的路径为空表示没有找到，反之则找到了
		emit_signal(&"game_location_autofind", false)
	else: #否则(找到了游戏)
		n_line_edit_game_location.text = path_got #将路径填充到填写框里
		emit_signal(&"game_location_autofind", true)
	refresh_log() #刷新日志
	installer_gamepath_lose_focus()

## 安装器/解压并加载安装包
func installer_unpack_and_load_install_pack() -> void:
	load_install_pack(n_line_edit_pack_location.text)
	place_install_option_nodes()
	update_install_confirm_button()

## 安装器/状态/刷新
func installer_state_refresh() -> void:
	installer_gamepath_lose_focus()
	refresh_game_info()
	refresh_log() #刷新日志

## 安装器/安装/重新安装复选框
func installer_install_reinstall_checkbox() -> void:
	install_option_reinstall = n_operation_install_reinstall_checkbox.button_pressed
	update_install_confirm_button()

## 安装器/安装/确认安装
func installer_install_confirm() -> void:
	is_operating = true
	n_operation_install_confirm_button.disabled = true
	if (install_option_difficult_current != -1):
		installer.multiple_threads_install(n_line_edit_game_location.text.get_base_dir(), install_option_difficult_current, install_option_addons_current, install_option_reinstall)
	#refresh_game_info()
	#refresh_log() #刷新日志

## 安装器/卸载/确认卸载
func installer_uninstall_confirm() -> void:
	is_operating = true
	n_operation_uninstall_confirm_button.disabled = true
	installer.multiple_threads_uninstall(n_line_edit_game_location.text.get_base_dir(), n_operation_uninstall_keep_framework_checkbox.button_pressed)
	#refresh_game_info()
	#refresh_log() #刷新日志

## 安装器/验证/开始验证
func installer_verify_start() -> void:
	pass

## 安装器/游戏路径提交
func installer_gamepath_submit(new_text: String) -> void:
	if (new_text.is_empty()): #如果为空
		is_game_path_ready = false
		n_game_tip_text.text = "若要进行操作，必须指定游戏位置"
		n_game_tip_text.modulate = Color.RED
		hide_game_info(GameInfoState.NOT_FOUND)
		update_install_confirm_button()
		refresh_log() #刷新日志
		return
	new_text = new_text.trim_prefix("\"").trim_suffix("\"") #去除引号
	n_line_edit_game_location.text = new_text
	if (not new_text.is_absolute_path() or new_text.get_file() != "Subnautica.exe"): #如果内容不是绝对路径或不是指向Subnautica.exe的路径
		is_game_path_ready = false
		n_game_tip_text.text = "需填写一个指向Subnautica.exe的绝对路径"
		n_game_tip_text.modulate = Color.RED
		hide_game_info(GameInfoState.PATH_UNVALID)
		update_install_confirm_button()
		refresh_log() #刷新日志
		return
	if (not FileAccess.file_exists(new_text)): #如果文件不存在
		is_game_path_ready = false
		n_game_tip_text.text = "路径指向的文件不存在或不可见"
		n_game_tip_text.modulate = Color.RED
		hide_game_info(GameInfoState.PATH_UNVALID)
		update_install_confirm_button()
		refresh_log() #刷新日志
		return
	if (not installer.verify_md5(new_text)): #如果指定的路径不通过md5验证
		is_game_path_ready = true
		n_game_tip_text.text = "未通过哈希校验，可能原因：游戏版本不是68598、游戏文件损坏"
		n_game_tip_text.modulate = Color.YELLOW
		show_game_info()
		update_install_confirm_button()
		refresh_log() #刷新日志
		return
	else: #否则(指定的路径通过了md5验证)
		is_game_path_ready = true
		n_game_tip_text.text = "就绪"
		n_game_tip_text.modulate = Color.GREEN
		show_game_info()
	update_install_confirm_button()
	refresh_log() #刷新日志

## 安装器/游戏路径失去焦点
func installer_gamepath_lose_focus() -> void:
	installer_gamepath_submit(n_line_edit_game_location.text)

## 安装器/安装包路径提交
func installer_packpath_submit(_new_text: String) -> void:
	#load_install_pack()
	pass

## 安装器/安装包路径失去焦点
func installer_packpath_lose_focus() -> void:
	#installer_packpath_submit("")
	pass

## 刷新日志，在任何(可能)能够影响日志的菜单元素被触发以后均调用此方法，由其他连接了信号的方法调用
func refresh_log() -> void:
	installer.mutex.lock()
	if (installer.log_warn_count > 0):
		emit_signal(&"new_warn")
	if (installer.log_error_count > 0):
		emit_signal(&"new_error")
	n_log_text.text = installer.log_string #将安装器的日志内容传递到本实例
	installer.mutex.unlock()
#endregion
