extends RefCounted
class_name BaiChuanLauncher
## 百川启动器，以静态形式运作

const GAME_DIR: String = "game"
const GAME_NAME: String = "Subnautica.exe"

static func is_builtin_game_exist() -> bool:
	var this_dir: DirAccess = DirAccess.open(OS.get_executable_path().get_base_dir())
	if (this_dir == null):
		push_error("BaiChuanLauncher: 打开目录失败，原因=", DirAccess.get_open_error())
	if (this_dir.file_exists(GAME_DIR.path_join(GAME_NAME))):
		return true
	return false
