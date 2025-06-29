extends RefCounted
class_name BaiChuanInstaller
## 百川安装器，以动态实例形式运作

## 68598版本深海迷航exe(Subnautica.exe)的已知md5值
const SUBNAUTICA_EXE_MD5: PackedStringArray = [
	"0fc9d3196024f686cb9cfee074fbf409",
]

## 日志
var log: String = ""
## 游戏寻找器实例
var game_searcher: BaiChuanInstaller_GameSearcher = BaiChuanInstaller_GameSearcher.new()

#region 日志
## 清除日志
func log_clear() -> void:
	log = ""

## 在日志中追加一个消息
func log_info(text: String) -> void:
	log += text + "\n"
	print(text)

## 在日志中追加一个警告
func log_warn(text: String) -> void:
	log += "[color=yellow]" + text + "[/color]\n"
	push_warning(text)

## 在日志中追加一个错误
func log_error(text: String) -> void:
	log += "[color=red]" + text + "[/color]\n"
	push_error(text)
#endregion

## 搜寻游戏的高级封装，将返回一个md5匹配的绝对路径，如果寻找不到md5匹配的路径但至少找到了文件存在的路径，就返回一个该条件的路径
func search_game() -> String:
	log_info("开始自动寻找游戏")
	## 00寻找
	var drivers_names: PackedStringArray = [] #声明局部字符串数组，用作盘符列表
	for driver_index in DirAccess.get_drive_count(): #按索引遍历所有驱动器分区
		drivers_names.append(DirAccess.get_drive_name(driver_index)) #将当前遍历到的驱动器分区名记录到盘符列表
	log_info("找到驱动器分区：" + str(drivers_names)) #日志输出
	var absolute_pathes: PackedStringArray = game_searcher.search_game_path_on_drives(drivers_names) #将盘符列表传递给游戏查找器，获得一个包含着文件存在的绝对路径列表
	## /00
	## 01输出
	if (absolute_pathes.is_empty()): #如果为空，意味着找不到游戏
		log_warn("找不到游戏") #日志输出
		return "" #返回一个空文本
	for absolute_path in absolute_pathes: #遍历找到文件的路径列表
		if (verify_md5(absolute_path)): #如果找到md5验证正确的文件
			log_info("找到了符合md5值的游戏文件") #日志输出
			return absolute_path #返回当前遍历的路径
	log_warn("找到了游戏文件但md5校验失败")
	return absolute_pathes[0] #返回第一个找到的路径
	## /01

## 验证游戏的md5值是否匹配已知的任意一个md5值，传入一个绝对路径，应指向Subnautica.exe。本方法不能保证指向的文件绝对是正确无损的68598版Subnautica.exe
func verify_md5(absolute_path: String) -> bool:
	var current_md5: String = FileAccess.get_md5(absolute_path) #获取文件md5
	return SUBNAUTICA_EXE_MD5.has(current_md5) #检查已知md5值列表是否含有该文件的md5，并返回结果

## 检测游戏安装状态，传入一个指向Subnautica.exe的绝对路径
func game_state_detect(absolute_path: String) -> GameStateReport:
	log_info("开始检查游戏状态")
	var result: GameStateReport = GameStateReport.new() #新建结果实例
	var root_dir: DirAccess = DirAccess.open(absolute_path.get_base_dir()) #打开给定的绝对路径的所在目录为DirAccess
	if (root_dir == null): #如果DirAccess打开失败
		log_error("DirAccess打开失败")
		result.game_version_verify = GameStateReport.GameVersionVerify.ERROR
		result.is_bepinex_exist = false
		result.is_qmods_exist = false
		result.baichuan_installed = GameStateReport.BaiChuanInstalled.ERROR
		return result
	if (absolute_path.get_file() != "Subnautica.exe"): #如果给定的路径不是指向Subnautica.exe的
		log_error("指定的路径不指向Subnautica.exe")
		result.game_version_verify = GameStateReport.GameVersionVerify.NOT_FOUND
	if (verify_md5(absolute_path)): #验证md5，若通过
		log_info("md5验证通过")
		result.game_version_verify = GameStateReport.GameVersionVerify.VERIFY_SUCCESS
	else: #否则(若md5验证不通过)
		log_warn("md5验证不通过")
		result.game_version_verify = GameStateReport.GameVersionVerify.VERIFY_FAILED
	result.is_bepinex_exist = root_dir.dir_exists("BepInEx/core")
	result.is_qmods_exist = root_dir.dir_exists("QMods")
	## 00百川安装状态检测
	var files: PackedStringArray = root_dir.get_files()
	var i: int = 0
	if (files.has("baichuan_install_data.json")): #如果存在安装标识信息
		log_info("已找到百川安装标识文件")
		i += 1
	if (files.has("uninstall.bcis")): #如果存在卸载脚本
		log_info("已找到百川卸载脚本文件")
		i += 1
	if (root_dir.file_exists("QMods/CustomCraft2SML/WorkingFiles/AllriversflowtotheseaRESET.txt")): #如果存在百川mod特征文件
		log_info("已找到百川mod特征文件")
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
