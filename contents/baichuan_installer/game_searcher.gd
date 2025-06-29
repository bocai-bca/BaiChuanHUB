extends RefCounted
class_name BaiChuanInstaller_GameSearcher
## 百川安装器-游戏寻找器

## 本类主要服务于寻找Steam的安装目录

## 常见Steam游戏路径，用于结合盘符合成为绝对路径，以供检查
const STEAM_GAME_PATH: PackedStringArray = [
	"/Program Files/Steam/steamapps/common/Subnautica/Subnautica.exe",
	"/Program Files (x86)/Steam/steamapps/common/Subnautica/Subnautica.exe",
	"/SteamLibrary/steamapps/common/Subnautica/Subnautica.exe",
]

## 在给定分区中搜寻存在的深海游戏(Subnautica.exe)路径，并打包进一个紧缩字符串数组中返回，只返回可见的符合该名称的文件的路径，不保证文件可用、正确
func search_game_path_on_drives(drivers_names: PackedStringArray) -> PackedStringArray:
	var result: PackedStringArray = []
	for driver_name in drivers_names: #遍历给定的分区名
		for game_path in STEAM_GAME_PATH: #遍历已知的可能路径
			var absolute_path: String = driver_name + game_path #合成为绝对路径
			if (FileAccess.file_exists(absolute_path)): #如果文件存在
				result.append(absolute_path) #将当前绝对路径添加到结果列表
	return result
