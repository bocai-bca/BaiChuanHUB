extends RefCounted
class_name BaiChuanInstaller
## 百川安装器，以动态实例形式运作

## 68598版本深海迷航exe(Subnautica.exe)的已知md5值
const SUBNAUTICA_EXE_MD5: PackedStringArray = [
	"0fc9d3196024f686cb9cfee074fbf409",
]

## 日志输出实例
var logger: BaiChuanInstaller_Logger = BaiChuanInstaller_Logger.new()
## 日志
var log_string: String:
	get:
		return logger.log_string
## 游戏寻找器实例
var game_searcher: BaiChuanInstaller_GameSearcher = BaiChuanInstaller_GameSearcher.new()
## 安装包访问实例
var pack_access: BaiChuanInstaller_PackAccess = BaiChuanInstaller_PackAccess.new()

## 搜寻游戏的高级封装，将返回一个md5匹配的绝对路径，如果寻找不到md5匹配的路径但至少找到了文件存在的路径，就返回一个该条件的路径
func search_game() -> String:
	logger.log_info("开始自动寻找游戏")
	## 00寻找
	var drivers_names: PackedStringArray = [] #声明局部字符串数组，用作盘符列表
	for driver_index in DirAccess.get_drive_count(): #按索引遍历所有驱动器分区
		drivers_names.append(DirAccess.get_drive_name(driver_index)) #将当前遍历到的驱动器分区名记录到盘符列表
	logger.log_info("找到驱动器分区：" + str(drivers_names)) #日志输出
	var absolute_pathes: PackedStringArray = game_searcher.search_game_path_on_drives(drivers_names) #将盘符列表传递给游戏查找器，获得一个包含着文件存在的绝对路径列表
	## /00
	## 01输出
	if (absolute_pathes.is_empty()): #如果为空，意味着找不到游戏
		logger.log_warn("找不到游戏") #日志输出
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
		logger.log_error("DirAccess打开失败")
		result.game_version_verify = GameStateReport.GameVersionVerify.ERROR
		result.is_bepinex_exist = false
		result.is_qmods_exist = false
		result.baichuan_installed = GameStateReport.BaiChuanInstalled.ERROR
		return result
	if (absolute_path.get_file() != "Subnautica.exe"): #如果给定的路径不是指向Subnautica.exe的
		logger.log_error("指定的路径不指向Subnautica.exe")
		result.game_version_verify = GameStateReport.GameVersionVerify.NOT_FOUND
	if (verify_md5(absolute_path)): #验证md5，若通过
		#logger.log_info("md5验证通过")
		result.game_version_verify = GameStateReport.GameVersionVerify.VERIFY_SUCCESS
	else: #否则(若md5验证不通过)
		logger.log_warn("md5验证不通过")
		result.game_version_verify = GameStateReport.GameVersionVerify.VERIFY_FAILED
	result.is_bepinex_exist = root_dir.dir_exists("BepInEx/core")
	result.is_qmods_exist = root_dir.dir_exists("QMods")
	## 00百川安装状态检测
	var files: PackedStringArray = root_dir.get_files()
	var i: int = 0
	if (files.has("baichuan_install_data.json")): #如果存在安装标识信息
		#logger.log_info("已找到百川安装标识文件")
		i += 1
	if (files.has("uninstall.bcis")): #如果存在卸载脚本
		#logger.log_info("已找到百川卸载脚本文件")
		i += 1
	if (root_dir.file_exists("QMods/CustomCraft2SML/WorkingFiles/AllriversflowtotheseaRESET.txt")): #如果存在百川mod特征文件
		#logger.log_info("已找到百川mod特征文件")
		i += 1
	match (i):
		0:
			result.baichuan_installed = GameStateReport.BaiChuanInstalled.NO
		1, 2:
			result.baichuan_installed = GameStateReport.BaiChuanInstalled.HALF
		3:
			result.baichuan_installed = GameStateReport.BaiChuanInstalled.FULL
	## /00
	return result

## 加载新安装包，失败时返回null
func load_new_pack(pack_path: String) -> PackMetaReport:
	logger.log_info("开始尝试加载安装包: " + pack_path)
	#pack_path = pack_path.trim_prefix("\"").trim_suffix("\"") #去除路径的首尾引号
	if (not pack_access.open_new(pack_path, logger)): #打开安装包并检查是否成功
		logger.log_error("因发生错误而中止安装包加载")
		return null
	logger.log_info("已打开压缩包")
	if (not pack_access.parse_meta(logger)): #解析元数据并检查是否成功
		logger.log_error("因发生错误而中止安装包加载")
		return null
	logger.log_info("安装包元数据解析完成")
	if (not pack_access.parse_contents(logger)): #解析包内容和验证脚本并检查是否成功
		logger.log_error("因发生错误而中止安装包加载")
		return null
	logger.log_info("安装包内容解析已完成")
	var result: PackMetaReport = PackMetaReport.new()
	result.version = pack_access.pack_meta.version
	result.version_name = pack_access.pack_meta.version_name
	result.fork_version = pack_access.pack_meta.fork_version
	result.mods_count = pack_access.pack_meta.mods_list.size()
	result.difficults_names = []
	for difficult in pack_access.pack_meta.difficults_list: #遍历难度列表
		result.difficults_names.append(difficult.name)
	result.addons_names = []
	for addon in pack_access.pack_meta.addons_list: #遍历附属包列表
		result.addons_names.append(addon.name)
	return result

## 游戏状态报告
class GameStateReport extends RefCounted:
	enum GameVersionVerify{
		ERROR, #因各种原因错误，也充当一个占位符
		NOT_FOUND, #未找到Subnautica.exe
		VERIFY_FAILED, #验证不通过
		VERIFY_SUCCESS, #验证通过
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
	var is_bepinex_exist: bool
	## QMods存在迹象
	var is_qmods_exist: bool
	## 百川安装状况
	var baichuan_installed: BaiChuanInstalled

## 安装包元数据报告
class PackMetaReport extends RefCounted:
	## 难度名称表，其索引与pack_access.pack_meta.difficults_list一一对应
	var difficults_names: PackedStringArray
	## 模组数量(pack.json中注册的数量，而非模组目录中的数量)
	var mods_count: int
	## 附属包名称表，其索引与pack_access.pack_meta.addons_list一一对应
	var addons_names: PackedStringArray
	## 版本号
	var version: int
	## 版本名称
	var version_name: String
	## 分支版本号
	var fork_version: int
