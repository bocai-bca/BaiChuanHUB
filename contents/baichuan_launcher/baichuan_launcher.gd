extends RefCounted
class_name BaiChuanLauncher
## 百川启动器，以静态形式运作

const GAME_DIR: String = "game"
const GAME_NAME: String = "Subnautica.exe"

static func is_builtin_game_dir_exist() -> bool:
	var this_dir: DirAccess = DirAccess.open(OS.get_executable_path())
	if (this_dir.dir_exists(GAME_DIR)):
		return true
	return false
