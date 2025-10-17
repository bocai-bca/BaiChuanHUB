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
	installer.multiple_threads_install(OS.get_executable_path().get_base_dir().path_join(GAME_DIR), launch_difficult, launch_addons, true, [run_game])

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
