extends RefCounted
class_name BaiChuanInstaller
## 百川安装器，以动态实例形式运作

## 68598版本深海迷航exe(Subnautica.exe)的已知md5值
const SUBNAUTICA_EXE_MD5: PackedStringArray = [
	"0fc9d3196024f686cb9cfee074fbf409",
]

## 多线程线程实例
var thread: Thread = Thread.new()
## 多线程读写互斥锁
var mutex: Mutex = Mutex.new()
## 日志输出实例
var logger: BaiChuanInstaller_Logger = BaiChuanInstaller_Logger.new(mutex)
## 获取自上次读取log_string后的警报条目数量，注意：请自行在读取本属性之前锁定互斥锁，并在之后解锁
var log_warn_count: int:
	get:
		return logger.warn_count_after_last_read
## 获取自上次读取log_string后的错误条目数量，注意：请自行在读取本属性之前锁定互斥锁，并在之后解锁
var log_error_count: int:
	get:
		return logger.error_count_after_last_read
## 获取日志，读取本属性之后会复位警报与错误计数，注意：请自行在读取本属性之前锁定互斥锁，并在之后解锁
var log_string: String:
	get:
		logger.warn_count_after_last_read = 0
		logger.error_count_after_last_read = 0
		return logger.log_string
## 游戏寻找器实例
var game_searcher: BaiChuanInstaller_GameSearcher = BaiChuanInstaller_GameSearcher.new()
## 安装包访问实例
var pack_access: BaiChuanInstaller_PackAccess = BaiChuanInstaller_PackAccess.new()
## 脚本处理器
var script_handler: BaiChuanInstaller_ScriptHandler = BaiChuanInstaller_ScriptHandler.new()

## 搜寻游戏的高级封装，将返回一个md5匹配的绝对路径，如果寻找不到md5匹配的路径但至少找到了文件存在的路径，就返回一个该条件的路径
func search_game() -> String:
	logger.log_info("开始自动寻找游戏")
	## 00寻找
	var drivers_names: PackedStringArray = [] #声明局部字符串数组，用作盘符列表
	for driver_index in DirAccess.get_drive_count(): #按索引遍历所有驱动器分区
		drivers_names.append(DirAccess.get_drive_name(driver_index)) #将当前遍历到的驱动器分区名记录到盘符列表
	logger.log_darken("找到驱动器分区：" + str(drivers_names)) #日志输出
	var absolute_pathes: PackedStringArray = game_searcher.search_game_path_on_drives(drivers_names) #将盘符列表传递给游戏查找器，获得一个包含着文件存在的绝对路径列表
	## /00
	## 01输出
	if (absolute_pathes.is_empty()): #如果为空，意味着找不到游戏
		logger.log_warn("找不到游戏(无需重试，没用的)") #日志输出
		return "" #返回一个空文本
	for absolute_path in absolute_pathes: #遍历找到文件的路径列表
		if (verify_md5(absolute_path)): #如果找到md5验证正确的文件
			logger.log_info("找到了符合md5值的游戏文件") #日志输出
			return absolute_path #返回当前遍历的路径
	logger.log_warn("找到了游戏文件但md5校验失败")
	return absolute_pathes[0] #返回第一个找到的路径
	## /01

## 验证游戏的md5值是否匹配已知的任意一个md5值，传入一个绝对路径，应指向Subnautica.exe。本方法不能保证指向的文件绝对是正确无损的68598版Subnautica.exe
func verify_md5(absolute_path: String) -> bool:
	var current_md5: String = FileAccess.get_md5(absolute_path) #获取文件md5
	return SUBNAUTICA_EXE_MD5.has(current_md5) #检查已知md5值列表是否含有该文件的md5，并返回结果

## 检测游戏安装状态，传入一个指向Subnautica.exe的绝对路径
func game_state_detect(absolute_path: String) -> GameStateReport:
	#logger.log_info("开始检查游戏状态")
	var result: GameStateReport = GameStateReport.new() #新建结果实例
	var root_dir: DirAccess = DirAccess.open(absolute_path.get_base_dir()) #打开给定的绝对路径的所在目录为DirAccess
	if (root_dir == null): #如果DirAccess打开失败
		logger.log_error("BaiChuanInstaller: DirAccess打开失败")
		result.game_version_verify = GameStateReport.GameVersionVerify.ERROR
		result.bepinex_installed = GameStateReport.BepInExInstalled.ERROR
		result.is_qmods_exist = false
		result.baichuan_installed = GameStateReport.BaiChuanInstalled.ERROR
		return result
	if (absolute_path.get_file() != "Subnautica.exe"): #如果给定的路径不是指向Subnautica.exe的
		logger.log_error("BaiChuanInstaller: 指定的路径不指向Subnautica.exe")
		result.game_version_verify = GameStateReport.GameVersionVerify.NOT_FOUND
	if (verify_md5(absolute_path)): #验证md5，若通过
		#logger.log_info("md5验证通过")
		result.game_version_verify = GameStateReport.GameVersionVerify.VERIFY_SUCCESS
	else: #否则(若md5验证不通过)
		logger.log_warn("md5验证不通过")
		result.game_version_verify = GameStateReport.GameVersionVerify.VERIFY_FAILED
	var i: int = 0
	if (root_dir.dir_exists("BepInEx")):
		i += 1
	if (root_dir.dir_exists("BepInEx/core")):
		i += 1
	if (root_dir.dir_exists("BepInEx/plugins")):
		i += 1
	if (root_dir.file_exists("winhttp.dll")):
		i += 1
	if (root_dir.file_exists("doorstop_config.ini")):
		i += 1
	match (i):
		0:
			result.bepinex_installed = GameStateReport.BepInExInstalled.NO
		1, 2, 3, 4:
			result.bepinex_installed = GameStateReport.BepInExInstalled.HALF
		5:
			result.bepinex_installed = GameStateReport.BepInExInstalled.FULL
	result.is_qmods_exist = root_dir.dir_exists("QMods")
	## 00百川安装状态检测
	var files: PackedStringArray = root_dir.get_files()
	i = 0
	if (files.has(BaiChuanInstaller_PackAccess.INSTALLED_META)): #如果存在安装标识信息
		#logger.log_info("已找到百川安装标识文件")
		i += 1
	if (files.has(BaiChuanInstaller_PackAccess.UNINSTALL_SCRIPT_NAME)): #如果存在卸载脚本
		#logger.log_info("已找到百川卸载脚本文件")
		i += 1
	if (root_dir.file_exists("QMods/CustomCraft2SML/WorkingFiles/AllriversflowtotheseaRESET.txt")): #如果存在百川mod特征文件
		#logger.log_info("已找到百川mod特征文件")
		i += 1
	if (root_dir.file_exists(BaiChuanInstaller_PackAccess.INSTALLED_META)): #如果存在安装元数据
		i += 1
	match (i):
		0:
			result.baichuan_installed = GameStateReport.BaiChuanInstalled.NO
		1, 2, 3:
			result.baichuan_installed = GameStateReport.BaiChuanInstalled.HALF
		4:
			result.baichuan_installed = GameStateReport.BaiChuanInstalled.FULL
			var installed_meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(root_dir.get_current_dir().path_join(BaiChuanInstaller_PackAccess.INSTALLED_META))) as Dictionary
			if (installed_meta == null):
				result.baichuan_installed = GameStateReport.BaiChuanInstalled.ERROR
			else:
				result.baichuan_installed_version_name = installed_meta.get("version_name", "未知") as String
				result.baichuan_installed_difficult_name = installed_meta.get("difficult_name", "未知") as String
				result.baichuan_installed_addons_count = installed_meta.get("addons_count", 0) as int
	## /00
	return result

## 加载新安装包，失败时返回null
func load_new_pack(pack_path: String, need_unzip: bool) -> PackMetaReport:
	logger.log_info("开始尝试加载安装包: " + pack_path)
	#pack_path = pack_path.trim_prefix("\"").trim_suffix("\"") #去除路径的首尾引号
	if (need_unzip):
		if (not pack_access.open_new(pack_path, logger)): #打开安装包并检查是否成功
			logger.log_error("BaiChuanInstaller: 因发生错误而中止安装包加载")
			return null
	else:
		if (not pack_access.open_new_without_unzip(pack_path, logger)):
			logger.log_error("BaiChuanInstaller: 因发生错误而中止安装包加载")
			return null
	logger.log_darken("已打开压缩包")
	if (not pack_access.parse_meta(logger)): #解析元数据并检查是否成功
		logger.log_error("BaiChuanInstaller: 因发生错误而中止安装包加载")
		return null
	logger.log_darken("安装包元数据解析完成")
	if (not pack_access.parse_contents(logger)): #解析包内容和验证脚本并检查是否成功
		logger.log_error("BaiChuanInstaller: 因发生错误而中止安装包加载")
		return null
	logger.log_darken("安装包内容解析已完成")
	var result: PackMetaReport = PackMetaReport.new()
	result.version = pack_access.pack_meta.version
	result.version_name = pack_access.pack_meta.version_name
	result.fork_version = pack_access.pack_meta.fork_version
	result.mods_count = pack_access.pack_meta.mods_list.size()
	result.difficults_names = []
	result.difficults_pathes = []
	for difficult in pack_access.pack_meta.difficults_list: #遍历难度列表
		result.difficults_names.append(difficult.name)
		result.difficults_pathes.append(difficult.path)
	result.addons = []
	for addon in pack_access.pack_meta.addons_list: #遍历附属包列表
		var addon_meta:PackMetaReport_AddonsMeta = PackMetaReport_AddonsMeta.new(addon.name)
		for addon_support_difficult in addon.support_difficults: #遍历该附属包支持的所有难度
			var find_index: int = result.difficults_pathes.find(addon_support_difficult)
			if (find_index == -1 and addon_support_difficult == "_"): #如果未找到，并且该难度为_，说明是通配难度
				addon_meta.support_difficults = [255] #只需要添加一个255代表啥都有即可
				break #既然有通配难度的话那么只要记录它就行了，直接break
			if (find_index != -1 and not addon_meta.support_difficults.has(find_index)): #如果支持的难度列表中不存在当前获得的索引，此判断是用来防止重复添加元素
				addon_meta.support_difficults.append(find_index) #将当前获得的索引添加到元数据
		result.addons.append(addon_meta)
	logger.log_info("安装包已载入")
	return result

## 开启多线程安装，传入安装位置(Subnautica.exe所在的目录)、指定的难度、附属包、是否重新安装，不能返回成功与否
func multiple_threads_install(absolute_path: String, install_difficult: int, install_addons: PackedInt32Array, reinstall: bool) -> void:
	if (thread.is_alive()):
		logger.log_error("BaiChuanInstaller: 安装器繁忙，将拒绝新的安装任务")
		return
	if (thread.is_started()):
		thread.wait_to_finish()
	thread.start(install.bind(absolute_path, install_difficult, install_addons, reinstall), Thread.PRIORITY_HIGH)

## 安装，传入安装位置(Subnautica.exe所在的目录)、指定的难度、附属包、是否重新安装，并返回成功与否
func install(absolute_path: String, install_difficult: int, install_addons: PackedInt32Array, reinstall: bool) -> bool:
	logger.log_info("开始安装")
	script_handler.install_path = absolute_path
	var dir_access: DirAccess = DirAccess.open(absolute_path) #打开安装目录为DirAccess
	if (dir_access == null): #如果为null，说明出错
		logger.log_error("BaiChuanInstaller: 打开目录失败：" + absolute_path)
		logger.log_error("BaiChuanInstaller: 安装过程出现问题而中止")
		return false
	var need_uninstall: bool = false
	var game_state: GameStateReport = game_state_detect(absolute_path.path_join("Subnautica.exe"))
	match (game_state.bepinex_installed):
		GameStateReport.BepInExInstalled.ERROR:
			logger.log_error("BaiChuanInstaller: 检测BepInEx状态时发生错误")
			return false
		GameStateReport.BepInExInstalled.NO:
			pass
		_:
			if (reinstall):
				logger.log_darken("发现存在BepInEx，将进行覆盖")
				need_uninstall = true
			else:
				logger.log_warn("发现存在BepInEx，请在安装前还原到纯净原版游戏状态。若执意继续安装，请勾选\"覆盖现有安装\"，安装器将保留当前游戏目录下的其他mod文件，并会尝试一次卸载百川。勾选后安装器会跳过安全检查，安装器无法保证游戏在装有百川归海以外模组的非纯净状态下继续安装的安全性！")
				return false
	match (game_state.is_qmods_exist):
		true:
			if (reinstall):
				logger.log_darken("发现存在QMods")
				need_uninstall = true
			else:
				logger.log_warn("发现存在QMods，请在安装前还原到纯净原版游戏状态。若执意继续安装，请勾选\"覆盖现有安装\"，安装器将保留当前游戏目录下的其他mod文件，并会尝试一次卸载百川。勾选后安装器会跳过安全检查，安装器无法保证游戏在装有百川归海以外模组的非纯净状态下继续安装的安全性！")
				return false
	match (game_state.baichuan_installed):
		GameStateReport.BaiChuanInstalled.ERROR:
			logger.log_error("BaiChuanInstaller: 检测百川安装状态时发生错误")
			return false
		GameStateReport.BaiChuanInstalled.NO:
			pass
		_:
			if (reinstall):
				logger.log_darken("发现百川安装迹象，将进行重新安装")
				need_uninstall = true
			else:
				logger.log_error("BaiChuanInstaller: 发现存在百川安装迹象，若希望更新百川或更换难度，请勾选\"覆盖现有安装\"。")
				return false
	if (need_uninstall):
		## 重新安装
		uninstall(absolute_path, false)
	## 00数据检查
	if (not (0 <= install_difficult and install_difficult < pack_access.pack_meta.difficults_list.size())): #如果给定的安装难度索引不在有效范围内
		logger.log_error("BaiChuanInstaller: 不存在指定的安装难度索引：" + str(install_difficult))
		logger.log_error("BaiChuanInstaller: 安装过程出现问题而中止")
		return false
	for install_addon in install_addons: #遍历所有附属包索引
		if (0 <= install_addon and install_addon < pack_access.pack_meta.addons_list.size()): #如果存在给定索引
			continue
		logger.log_error("BaiChuanInstaller: 不存在指定的安装附属包索引：" + str(install_addon))
		logger.log_error("BaiChuanInstaller: 安装过程出现问题而中止")
		return false
	## /00 从此处起可确保传入的安装路径可访问、难度索引可用、附属包索引可用
	var pack_dir: String = pack_access.dir_access.get_current_dir()
	logger.log_darken("正在放置前置")
	BaiChuanInstaller_DirRecurs.copy_recursive(pack_dir.path_join(pack_access.FRAMEWORKS_DIR), absolute_path, logger)
	logger.log_darken("正在放置数据")
	if (DirAccess.dir_exists_absolute(pack_dir.path_join(BaiChuanInstaller_PackAccess.DATA_DIR).path_join("_"))): #如果存在通配难度数据
		print("存在通配难度数据")
		BaiChuanInstaller_DirRecurs.copy_recursive(pack_dir.path_join(BaiChuanInstaller_PackAccess.DATA_DIR).path_join("_"), absolute_path, logger)
	if (DirAccess.dir_exists_absolute(pack_dir.path_join(BaiChuanInstaller_PackAccess.DATA_DIR).path_join(pack_access.pack_meta.difficults_list[install_difficult].path))): #如果存在对应的难度数据
		print("存在匹配难度数据")
		BaiChuanInstaller_DirRecurs.copy_recursive(pack_dir.path_join(BaiChuanInstaller_PackAccess.DATA_DIR).path_join(pack_access.pack_meta.difficults_list[install_difficult].path), absolute_path, logger)
	for install_addon in install_addons: #遍历所有附属包索引
		var addon_dir: String = pack_dir.path_join(BaiChuanInstaller_PackAccess.ADDONS_DIR).path_join(pack_access.pack_meta.addons_list[install_addon].path)
		print("addon_dir=", addon_dir)
		if (DirAccess.dir_exists_absolute(addon_dir.path_join(BaiChuanInstaller_PackAccess.DATA_DIR).path_join("_"))): #如果存在通配难度数据
			print("附属包", install_addon,"存在通配难度数据")
			BaiChuanInstaller_DirRecurs.copy_recursive(addon_dir.path_join(BaiChuanInstaller_PackAccess.DATA_DIR).path_join("_"), absolute_path, logger)
		if (DirAccess.dir_exists_absolute(addon_dir.path_join(BaiChuanInstaller_PackAccess.DATA_DIR).path_join(pack_access.pack_meta.difficults_list[install_difficult].path))): #如果存在对应的难度数据
			print("附属包", install_addon,"存在匹配难度数据")
			BaiChuanInstaller_DirRecurs.copy_recursive(addon_dir.path_join(BaiChuanInstaller_PackAccess.DATA_DIR).path_join(pack_access.pack_meta.difficults_list[install_difficult].path), absolute_path, logger)
	## 01按顺序解析安装脚本
	var difficult_script: BaiChuanInstaller_ScriptHandler.ScriptParsed = script_handler.parse_script(pack_access.get_install_script_absolute_path(install_difficult), pack_access, logger, false)
	if (difficult_script == null):
		logger.log_warn("安装流程因难度安装脚本解析出错中止")
		return false
	var addons_scripts: Array[BaiChuanInstaller_ScriptHandler.ScriptParsed] = []
	for install_addon in install_addons: #遍历所有附属包索引
		var wildmatch_path: String = pack_access.get_addon_install_script_absolute_path(install_addon, -1)
		if (pack_access.pack_meta.addons_list[install_addon].support_difficults.has("_")): #如果存在通配
			var wildmatch_script: BaiChuanInstaller_ScriptHandler.ScriptParsed = script_handler.parse_script(wildmatch_path, pack_access, logger, false)
			if (wildmatch_script == null):
				logger.log_warn("安装流程因附属包通配安装脚本解析出错中止")
				return false
			addons_scripts.append(wildmatch_script)
		var match_path: String = pack_access.get_addon_install_script_absolute_path(install_addon, install_difficult)
		if (pack_access.pack_meta.addons_list[install_addon].support_difficults.has(pack_access.pack_meta.difficults_list[install_difficult].path)): #如果存在匹配
			var match_script: BaiChuanInstaller_ScriptHandler.ScriptParsed = script_handler.parse_script(match_path, pack_access, logger, false)
			if (match_script == null):
				logger.log_warn("安装流程因附属包匹配安装脚本解析出错中止")
				return false
			addons_scripts.append(match_script)
	##  02执行难度安装脚本
	logger.log_darken("正在执行难度安装脚本")
	for command_index in difficult_script.commands_splitted.size(): #遍历难度安装脚本的命令
		if (not script_handler.run_command(difficult_script.commands_splitted[command_index], -1, pack_access, logger)): #执行命令并检查是否成功
			logger.log_error("BaiChuanInstaller: 难度安装脚本执行过程出现问题，发生于：" + str(command_index))
			logger.log_warn("安装流程中止")
			return false
	##  /02
	##  03执行附属包安装脚本
	for addon_index in addons_scripts.size(): #遍历所有附属包脚本
		logger.log_darken("正在执行附属包安装脚本：" + str(addon_index))
		for command_index in addons_scripts[addon_index].commands_splitted.size(): #遍历当前附属包安装脚本的命令
			if (not script_handler.run_command(addons_scripts[addon_index].commands_splitted[command_index], addon_index, pack_access,logger)): #执行命令并检查是否成功
				logger.log_error("BaiChuanInstaller: 附属包安装脚本执行过程出现问题，发生于：" + str(command_index))
				logger.log_warn("安装流程中止")
				return false
	##  /03
	## 04制作卸载脚本
	logger.log_darken("正在制作卸载脚本")
	var uninstall_script_content: String = ""
	for addon_index in install_addons.size(): #按索引遍历所有待安装附属包
		var i: int = install_addons.size() - 1 - addon_index #反转索引
		if (pack_access.pack_meta.addons_list[install_addons[i]].support_difficults.has("_")):
			uninstall_script_content += FileAccess.get_file_as_string(pack_access.get_addon_uninstall_script_absolute_path(install_addons[i], -1))
		uninstall_script_content += FileAccess.get_file_as_string(pack_access.get_addon_uninstall_script_absolute_path(install_addons[i], install_difficult))
	uninstall_script_content += FileAccess.get_file_as_string(pack_access.get_uninstall_script_absolute_path(install_difficult))
	var uninstall_script_file: FileAccess = FileAccess.open(absolute_path.path_join(BaiChuanInstaller_PackAccess.UNINSTALL_SCRIPT_NAME), FileAccess.WRITE)
	if (uninstall_script_file == null):
		logger.log_error("BaiChuanInstaller: 打开卸载脚本失败")
		logger.log_warn("安装流程中止")
		return false
	uninstall_script_file.store_string(uninstall_script_content)
	## /04
	## 05放置安装元数据
	var install_meta_file: FileAccess = FileAccess.open(absolute_path.path_join(BaiChuanInstaller_PackAccess.INSTALLED_META), FileAccess.WRITE)
	if (install_meta_file == null):
		logger.log_error("BaiChuanInstaller: 打开安装元数据失败")
		logger.log_warn("安装流程中止")
		return false
	var install_meta_data: Dictionary[String, Variant] = {
		"version_name": pack_access.pack_meta.version_name,
		"difficult_name": pack_access.pack_meta.difficults_list[install_difficult].name,
		"addons_count": install_addons.size()
	}
	install_meta_file.store_string(JSON.stringify(install_meta_data, "\t", false, false))
	## /05
	## /01
	logger.log_info("安装流程结束")
	return true

## 开启多线程卸载，传入安装位置(Subnautica.exe所在的目录)、是否保留前置，不能返回成功与否
func multiple_threads_uninstall(absolute_path: String, keep_framework: bool) -> void:
	if (thread.is_alive()):
		logger.log_error("BaiChuanInstaller: 安装器繁忙，将拒绝新的卸载任务")
		return
	if (thread.is_started()):
		thread.wait_to_finish()
	thread.start(uninstall.bind(absolute_path, keep_framework), Thread.PRIORITY_HIGH)

## 卸载，传入安装位置(Subnautica.exe所在的目录)、是否保留前置，并返回成功与否
func uninstall(absolute_path: String, keep_framework: bool) -> bool:
	logger.log_info("开始卸载")
	script_handler.install_path = absolute_path
	if (FileAccess.file_exists(absolute_path.path_join(BaiChuanInstaller_PackAccess.UNINSTALL_SCRIPT_NAME))): #如果存在卸载脚本
		## 00执行卸载脚本
		var uninstall_script: BaiChuanInstaller_ScriptHandler.ScriptParsed = script_handler.parse_script(absolute_path.path_join(BaiChuanInstaller_PackAccess.UNINSTALL_SCRIPT_NAME), pack_access, logger, true)
		if (uninstall_script == null):
			logger.log_warn("卸载流程因卸载脚本解析出错中止")
			return false
		for command_index in uninstall_script.commands_splitted.size(): #遍历难度安装脚本的命令
			if (not script_handler.run_command(uninstall_script.commands_splitted[command_index], -1, null, logger)): #执行命令并检查是否成功
				logger.log_error("BaiChuanInstaller: 卸载脚本执行过程出现问题，发生于：" + str(command_index))
				logger.log_warn("卸载流程中止")
				return false
		## /00
		## 01移除卸载脚本及安装元数据
		if (DirAccess.remove_absolute(absolute_path.path_join(BaiChuanInstaller_PackAccess.UNINSTALL_SCRIPT_NAME)) != OK):
			logger.log_error("BaiChuanInstaller: 删除卸载脚本时发生问题")
			logger.log_warn("卸载流程中止")
			return false
		if (FileAccess.file_exists(absolute_path.path_join(BaiChuanInstaller_PackAccess.INSTALLED_META))):
			if (DirAccess.remove_absolute(absolute_path.path_join(BaiChuanInstaller_PackAccess.INSTALLED_META))):
				logger.log_error("BaiChuanInstaller: 删除安装元数据时发生问题")
				logger.log_warn("卸载流程中止")
				return false
		else:
			logger.log_warn("未找到安装元数据")
		## /01
		if (not keep_framework): #如果不要求保留前置，即需要删除前置
			## 02删除前置
			var success: bool = true
			logger.log_darken("正在删除前置")
			var dirs_need_delete: PackedStringArray = [
				"BepInEx", "BepInEx_Shim_Backup", "QMods"
			]
			for dir_need_delete in dirs_need_delete:
				var path: String = absolute_path.path_join(dir_need_delete)
				if (DirAccess.dir_exists_absolute(path)):
					print("正在删除：", path)
					if (not BaiChuanInstaller_DirRecurs.delete_recursive(path, logger)):
						logger.log_error("BaiChuanInstaller: 删除目录时出错：" + dir_need_delete)
						success = false
			var misc_files: PackedStringArray = [
				"doorstop_config.ini",
				"HarmonyLog.txt",
				"qmodmanager_log-Subnautica.txt",
				"qmodmanager-config.json",
				"winhttp.dll",
			]
			for misc_file in misc_files:
				var path: String = absolute_path.path_join(misc_file)
				if (FileAccess.file_exists(path)):
					var err: Error = DirAccess.remove_absolute(path)
					if (err != OK):
						logger.log_error("BaiChuanInstaller: 删除文件时出错：" + misc_file + "，错误代码：" + str(err))
						success = false
			## /02
			if (success):
				logger.log_info("卸载流程结束")
				return true
			else:
				logger.log_warn("卸载流程结束，过程中发生错误")
				return false
		logger.log_info("卸载流程结束")
		return true
	#else: #否则(不存在卸载脚本)
	logger.log_warn("未找到卸载脚本，如需卸载请手动删除相关文件")
	return false

## 游戏状态报告
class GameStateReport extends RefCounted:
	enum GameVersionVerify{
		ERROR, #因各种原因错误，也充当一个占位符
		NOT_FOUND, #未找到Subnautica.exe
		VERIFY_FAILED, #验证不通过
		VERIFY_SUCCESS, #验证通过
	}
	enum BepInExInstalled{
		ERROR, #因各种原因错误，也充当一个占位符
		NO, #没有找到BepInEx的迹象
		HALF, #找到了部分迹象
		FULL, #找到了所有迹象
	}
	enum BaiChuanInstalled{
		ERROR, #因各种原因错误，也充当一个占位符
		NO, #没有找到百川的安装标识符或卸载脚本
		HALF, #存在百川的安装标识符或卸载脚本
		FULL, #存在百川的安装标识符和卸载脚本
	}
	## 游戏版本验证
	var game_version_verify: GameVersionVerify
	## BepInEx存在迹象
	var bepinex_installed: BepInExInstalled
	## QMods存在迹象
	var is_qmods_exist: bool
	## 百川安装状况
	var baichuan_installed: BaiChuanInstalled
	## 百川安装版本名称(从安装元数据读取)
	var baichuan_installed_version_name: String
	## 百川安装难度名称(从安装元数据读取)
	var baichuan_installed_difficult_name: String
	## 百川安装附属包数量(从安装元数据读取)
	var baichuan_installed_addons_count: int

## 安装包元数据报告
class PackMetaReport extends RefCounted:
	## 难度名称表，其索引与pack_access.pack_meta.difficults_list一一对应
	var difficults_names: PackedStringArray
	## 难度路径表，其索引与pack_access.pack_meta.difficults_list一一对应
	var difficults_pathes: PackedStringArray
	## 模组数量(pack.json中注册的数量，而非模组目录中的数量)
	var mods_count: int
	## 附属包表，其索引与pack_access.pack_meta.addons_list一一对应
	var addons: Array[BaiChuanInstaller.PackMetaReport_AddonsMeta]
	## 版本号
	var version: int
	## 版本名称
	var version_name: String
	## 分支版本号
	var fork_version: int

## 安装包元数据报告-附属包元数据
class PackMetaReport_AddonsMeta extends RefCounted:
	## 附属包显示名称
	var name: String
	## 支持的难度列表，存储对应于PackMetaReport.difficults_names的索引，-1代表任意难度
	var support_difficults: PackedByteArray
	func _init(new_name: String, new_support_difficults: PackedByteArray = []) -> void:
		name = new_name
		support_difficults = new_support_difficults
