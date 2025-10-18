extends RefCounted
class_name BaiChuanLauncher
## 百川启动器，以静态形式运作

const GAME_DIR: String = "game"
const GAME_NAME: String = "Subnautica.exe"

## 启动器将通过此日志进行GUI日志输出
static var logger: BaiChuanInstaller_Logger
## 多线程互斥锁
static var mutex: Mutex
## 多线程线程实例
static var thread: Thread

## 检查内建游戏是否存在
static func is_builtin_game_exist() -> bool:
	var this_dir: DirAccess = DirAccess.open(OS.get_executable_path().get_base_dir())
	if (this_dir == null):
		logger.log_error("BaiChuanLauncher: 打开目录失败，原因=" + str(DirAccess.get_open_error()))
	if (this_dir.file_exists(GAME_DIR.path_join(GAME_NAME))):
		return true
	return false

## 使用安装法启动
static func launch_as_install_method(installer: BaiChuanInstaller, launch_difficult: int, launch_addons: PackedInt32Array) -> void:
	var game_dir: String = OS.get_executable_path().get_base_dir().path_join(GAME_DIR)
	var install_meta_path: String = game_dir.path_join(BaiChuanInstaller_PackAccess.INSTALLED_META)
	if (FileAccess.file_exists(install_meta_path)):
		var install_meta_content: String = FileAccess.get_file_as_string(install_meta_path)
		if (not install_meta_content.is_empty()):
			var json: Dictionary[String, Variant] = JSON.parse_string(install_meta_content) as Dictionary[String, Variant]
			if (
				json.has("installer_version") and (json["installer_version"] as int) == BaiChuanInstaller.INSTALLER_VERSION
				and
				json.has("version") and (json["version"] as int) == installer.pack_access.pack_meta.version
				and
				json.has("fork_version") and (json["fork_version"] as int) == installer.pack_access.pack_meta.fork_version
				and
				json.has("difficult_index") and (json["difficult_index"] as int) == launch_difficult
				and
				json.has("addons_indexs") and sort_int32_arr_and_back(json["addons_indexs"] as PackedInt32Array) == sort_int32_arr_and_back(launch_addons)
			):
				logger.log_info("当前已安装的元数据完全匹配，将跳过安装部分")
				run_game()
				return
		else:
			logger.log_error("BaiChuanLauncher: 未能读取安装元数据，位置=" + install_meta_path + "，原因=" + str(FileAccess.get_open_error()))
	installer.multiple_threads_install(game_dir, launch_difficult, launch_addons, true, [run_game])

## 使用链接法启动
static func launch_as_mklink_method(installer: BaiChuanInstaller, launch_difficult: int, launch_addons: PackedInt32Array) -> void:
	if (thread.is_alive()):
		logger.log_error("BaiChuanLauncher: 启动器繁忙，将拒绝新的启动任务")
		return
	if (thread.is_started()):
		thread.wait_to_finish()
	thread.start(mklink_launch_main.bind(installer, launch_difficult, launch_addons), Thread.PRIORITY_HIGH)

static func mklink_launch_main(installer: BaiChuanInstaller, launch_difficult: int, launch_addons: PackedInt32Array) -> void:
	pass

## 运行游戏，一般需要通过多线程回调来调用
static func run_game() -> void:
	logger.log_info("正在启动游戏")
	var absolute_path: String = OS.get_executable_path().get_base_dir().path_join(GAME_DIR).path_join(GAME_NAME)
	if (FileAccess.file_exists(absolute_path)):
		var pid: int = OS.create_process(absolute_path, ["-vrmode", "none"])
		if (pid == -1):
			logger.log_error("BaiChuanLauncher: 未能获取进程PID，进程可能启动失败")
		else:
			logger.log_info("游戏已启动，PID:" + str(pid))
	else:
		logger.log_error("BaiChuanLauncher: 启动前未找到游戏可执行文件，位置:" + absolute_path)

## 小工具方法，对一个数组调用排序并使其返回排序后的自身
static func sort_int32_arr_and_back(arr: PackedInt32Array) -> PackedInt32Array:
	arr.sort()
	return arr
