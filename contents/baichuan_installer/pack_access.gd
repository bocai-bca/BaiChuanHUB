extends RefCounted
class_name BaiChuanInstaller_PackAccess
## 百川安装器-安装包访问

## 安装包下难度目录
const DIFFICULTS_DIR: String = "difficults"
## 安装包下模组目录
const MODS_DIR: String = "mods"
## 安装包下附属包目录
const ADDONS_DIR: String = "addons"
## 安装包下前置目录
const FRAMEWORKS_DIR: String = "frameworks"
## 安装包下数据目录
const DATA_DIR: String = "data"
## 安装脚本文件名
const INSTALL_SCRIPT_NAME: String = "install.bcis"
## 卸载脚本文件名
const UNINSTALL_SCRIPT_NAME: String = "uninstall.bcis"
## 安装包元数据
const ROOT_PACK_META: String = "pack.json"
## 附属包元数据
const ADDON_META: String = "addon.json"

## 包DirAccess
var dir_access: DirAccess
## 包元数据，相当于pack.json的反序列化结果
var pack_meta: PackMeta
## 存储所有已解析的(命令格式上可读的)脚本，采用该脚本在安装包中的路径作为键
var scripts_parsed: Dictionary[String, BaiChuanInstaller_ScriptExecuter.ScriptParsed]

## 开启新包，会将文件读入自身的pack_dir_access成员变量中，如果失败或发生问题将返回false，成功返回true。尽管发生问题，dir_access仍然会被覆盖
func open_new(pack_path: String, logger: BaiChuanInstaller_Logger) -> bool:
	dir_access = DirAccess.create_temp("BaiChuanHUB") #新建临时目录
	if (dir_access == null): #如果返回为null，说明出错了
		logger.log_error("在创建新临时目录时发生错误，加载安装包将中止")
		return false
	var zip_reader: ZIPReader = ZIPReader.new() #新建一个压缩包读取实例
	if (zip_reader.open(pack_path) != OK): #如果打开压缩包发生了错误
		logger.log_error("在打开压缩包时发生错误，加载安装包将中止")
		return false
	var pathes: PackedStringArray = zip_reader.get_files()
	for path in pathes: #遍历压缩包中的所有项
		if path.ends_with("/"): #如果该项以正斜杠结尾，说明是目录
			dir_access.make_dir_recursive(path) #递归创建目录
			continue
		dir_access.make_dir_recursive(dir_access.get_current_dir().path_join(path).get_base_dir()) #当该项为文件，递归创建该文件所在的目录结构
		var file = FileAccess.open(dir_access.get_current_dir().path_join(path), FileAccess.WRITE) #新建文件
		file.store_buffer(zip_reader.read_file(path)) #从压缩包读出内容存储在文件中
	return true

## 解析pack.json，当发生问题时返回false，一切正常返回true。尽管发生问题，pack_meta成员仍然会被覆盖
func parse_meta(logger: BaiChuanInstaller_Logger) -> bool:
	## 00基本解析
	if (not dir_access.file_exists(ROOT_PACK_META)): #如果压缩包内找不到pack.json
		logger.log_error("找不到包元数据，解析将中止")
		return false
	pack_meta = PackMeta.new() #新建PackMeta实例
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(dir_access.get_current_dir().path_join(ROOT_PACK_META))) as Dictionary #尝试解析pack.json
	if (parsed == null): #json解析失败时会返回null
		logger.log_error("包元数据JSON解析失败，解析将中止")
		return false
	if (not (parsed.has("version") and parsed.has("version_name") and parsed.has("fork_version") and parsed.has("difficults") and parsed.has("mods") and parsed.has("addons"))):
		logger.log_error("包元数据不完整，解析将中止")
		return false
	## /00
	## 01元数据反序列化
	pack_meta.version = parsed["version"]
	pack_meta.version_name = parsed["version_name"]
	pack_meta.fork_version = parsed["fork_version"]
	pack_meta.difficults_list = []
	for difficult_object in parsed["difficults"] as Array[Dictionary]:
		if (difficult_object.has("path") and difficult_object.has("name")):
			pack_meta.difficults_list.append(PathNameObject.new(difficult_object["path"], difficult_object["name"]))
		logger.log_error("解析元数据时发现问题，难度列表有必要键丢失，解析将中止")
		return false
	for mod_object in parsed["mods"] as Array[Dictionary]:
		if (mod_object.has("path") and mod_object.has("name") and mod_object.has("hash_list")):
			var mod_registry_object: ModRegistryObject = ModRegistryObject.new(mod_object["path"], mod_object["name"])
			for hash_list_obj in mod_object["hash_list"] as Array[Dictionary]: #遍历每个哈希验证表中的字典
				if (not hash_list_obj.has("path") and hash_list_obj.has("md5")):
					logger.log_error("解析元数据时发现问题，模组哈希验证表缺少必要键，解析将中止")
					return false
				mod_registry_object.hash_list.append(HashListObject.new(hash_list_obj["path"], hash_list_obj["md5"]))
			pack_meta.mods_list.append(mod_registry_object)
		logger.log_error("解析元数据时发现问题，模组列表有必要键丢失，解析将中止")
		return false
	for addon_object in parsed["addons"] as Array[Dictionary]:
		if (addon_object.has("path") and addon_object.has("name")):
			var addon_path: String = addon_object["path"]
			var addon_name: String = addon_object["name"]
			var addon_registry_object: AddonRegistryObject = AddonRegistryObject.new(addon_path, addon_name)
			if (not dir_access.file_exists(ADDONS_DIR.path_join(addon_path).path_join(ADDON_META))): #如果不存在安装包元数据
				logger.log_error("解析元数据时发现问题，附属包\"" + addon_name + "\"(" + addon_path + ")缺少元数据文件，解析将中止")
				return false
			var parsed_addon: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(dir_access.get_current_dir().path_join(ADDONS_DIR).path_join(addon_path).path_join(ADDON_META))) as Dictionary #尝试解析addon.json
			if (parsed_addon == null): #如果解析失败
				logger.log_error("附属包\"" + addon_name + "\"(" + addon_path + ")元数据解析失败，解析将中止")
				return false
			if (not parsed_addon.has("mods")):
				logger.log_error("附属包\"" + addon_name + "\"(" + addon_path + ")元数据不完整，解析将中止")
				return false
			for addon_mod in parsed_addon["mods"] as Array[Dictionary]:
				if (addon_mod.has("path") and addon_mod.has("name") and addon_mod.has("hash_list")):
					var mod_registry_object: ModRegistryObject = ModRegistryObject.new(addon_mod["path"], addon_mod["name"])
					for hash_list_obj in addon_mod["hash_list"] as Array[Dictionary]: #遍历每个哈希验证表中的字典
						if (not hash_list_obj.has("path") and hash_list_obj.has("md5")):
							logger.log_error("解析附属包\"" + addon_name + "\"(" + addon_path + ")元数据时发现问题，模组哈希验证表缺少必要键，解析将中止")
							return false
						mod_registry_object.hash_list.append(HashListObject.new(hash_list_obj["path"], hash_list_obj["md5"]))
					addon_registry_object.mods.append(mod_registry_object)
				logger.log_error("解析附属包\"" + addon_name + "\"(" + addon_path + ")元数据时发现问题，模组列表有必要键丢失，解析将中止")
				return false
			addon_registry_object.support_difficults = dir_access.get_directories_at(ADDONS_DIR.path_join(addon_path).path_join(DIFFICULTS_DIR)) #获取该附属包的所有难度
			pack_meta.addons_list.append(addon_registry_object)
		logger.log_error("解析元数据时发现问题，附属包列表有必要键丢失，解析将中止")
		return false
	## /01
	return true

## 验证安装包内容。在执行前需确保安装包已载入无误，并且已执行过parse_meta()，本方法依赖已反序列化的数据，否则将发生预期之外的事情
## 本方法将检查所有由元数据注册引用的项是否全都存在、所有被引用的脚本是否都正确无误
func parse_contents(logger: BaiChuanInstaller_Logger) -> bool:
	scripts_parsed.clear()
	var result: bool = true
	for difficult in pack_meta.difficults_list: #遍历所有难度
		if (not dir_access.dir_exists(DIFFICULTS_DIR.path_join(difficult.path))): #如果不存在指定的难度目录
			logger.log_error("解析安装包时发现问题，安装包缺少难度\"" + difficult.name + "\"，注册路径：" + difficult.path)
			result = false
			continue
		if (not dir_access.file_exists(DIFFICULTS_DIR.path_join(difficult.path).path_join(INSTALL_SCRIPT_NAME))): #如果不存在安装脚本
			logger.log_error("解析安装包时发现问题，难度\"" + difficult.name + "\"缺少安装脚本")
			result = false
		else: #否则(存在安装脚本)
			#### 制作ScriptParsed实例并添加到scripts_parsed
			pass
		if (not dir_access.file_exists(DIFFICULTS_DIR.path_join(difficult.path).path_join(UNINSTALL_SCRIPT_NAME))): #如果不存在卸载脚本
			logger.log_error("解析安装包时发现问题，难度\"" + difficult.name + "\"缺少卸载脚本")
			result = false
	for mod in pack_meta.mods_list: #遍历所有模组
		if (not dir_access.dir_exists(MODS_DIR.path_join(mod.path))): #如果不存在指定的模组目录
			logger.log_error("解析安装包时发现问题，安装包缺少模组\"" + mod.name + "\"，注册路径：" + mod.path)
			result = false
			continue
		for hash_obj in mod.hash_list: #遍历该模组的哈希验证表
			var combined_path: String = MODS_DIR.path_join(mod.path).path_join(hash_obj.path) #制作一个合并后的路径
			if (not dir_access.file_exists(combined_path)): #如果不存在该哈希验证对象指定的文件
				logger.log_error("解析安装包时发现问题，模组\"" + mod.name + "\"缺少注册的哈希验证文件\"" + hash_obj.path + "\"")
				result = false
				continue
			var current_md5: String = FileAccess.get_md5(dir_access.get_current_dir().path_join(combined_path)) #获取指向文件的md5
			if (current_md5 != hash_obj.md5.to_lower()): #如果获取的MD5与哈希验证表注册的MD5不同
				logger.log_error("解析安装包时发现问题，模组\"" + mod.name + "\"的哈希验证文件\"" + hash_obj.path + "\"取得了与注册值不同的MD5值。当前" + current_md5 + "，注册值" + hash_obj.md5)
				result = false
				continue
	for addon in pack_meta.addons_list: #遍历所有附属包
		var addon_path: String = ADDONS_DIR.path_join(addon.path) #该附属包的路径，相对于安装包根目录
		if (not dir_access.dir_exists(addon_path)): #如果不存在指定的附属包目录
			logger.log_error("解析安装包时发现问题，找不到附属包\"" + addon.name + "\"，注册路径：" + addon.path)
			result = false
			continue
		if (not dir_access.file_exists(addon_path.path_join(ADDON_META))): #如果不存在附属包元数据
			logger.log_error("解析安装包时发现问题，附属包\"" + addon.name + "\"缺少元数据")
			result = false
			continue
		for addon_mod in addon.mods: #遍历该附属包的所有模组
			var this_mod_combined_path: String = addon_path.path_join(addon_mod.path) #合并一个当前模组相对于安装包根目录的路径
			if (not dir_access.dir_exists(this_mod_combined_path)): #如果不存在指定的模组目录
				logger.log_error("解析安装包时发现问题，附属包\"" + addon.name + "\"缺少模组\"" + addon_mod.name + "\"，注册路径：" + addon_mod.path)
				result = false
				continue
			for hash_obj in addon_mod.hash_list: #遍历该附属包中的该模组的哈希验证表
				var path_of_the_file_of_hash_obj: String = this_mod_combined_path.path_join(hash_obj.path) #合并一个当前哈希验证文件相对于安装包根目录的路径
				if (not dir_access.file_exists(path_of_the_file_of_hash_obj)): #如果该文件不存在
					logger.log_error("解析安装包时发现问题，附属包\"" + addon.name + "\"的模组\"" + addon_mod.name + "\"缺少注册的哈希验证文件\"" + hash_obj.path + "\"")
					result = false
					continue
				var current_md5: String = FileAccess.get_md5(dir_access.get_current_dir().path_join(path_of_the_file_of_hash_obj)) #获取指向文件的md5
				if (current_md5 != hash_obj.md5.to_lower()): #如果获取的MD5与哈希验证表注册的MD5不同
					logger.log_error("解析安装包时发现问题，附属包\"" + addon.name + "\"的模组\"" + addon_mod.name + "\"的哈希验证文件\"" + hash_obj.path + "\"取得了与注册值不同的MD5值。当前" + current_md5 + "，注册值" + hash_obj.md5)
					result = false
		for addon_difficult in addon.support_difficults: #遍历该附属包的所有难度
			if (not dir_access.file_exists(addon_path.path_join(DIFFICULTS_DIR).path_join(addon_difficult).path_join(INSTALL_SCRIPT_NAME))): #如果不存在安装脚本
				logger.log_error("解析安装包时发现问题，附属包\"" + addon.name + "\"的难度\"" + addon_difficult + "\"(标识符)缺少安装脚本")
				result = false
			if (not dir_access.file_exists(addon_path.path_join(DIFFICULTS_DIR).path_join(addon_difficult).path_join(UNINSTALL_SCRIPT_NAME))): #如果不存在卸载脚本
				logger.log_error("解析安装包时发现问题，附属包\"" + addon.name + "\"的难度\"" + addon_difficult + "\"(标识符)缺少卸载脚本")
				result = false
	return result

## 包元数据，其实差不多是把pack.json反序列化成类型数据
class PackMeta extends RefCounted:
	## 包版本
	var version: int
	## 包版本显示名称
	var version_name: String
	## 包分支版本
	var fork_version: int
	## 难度表
	var difficults_list: Array[PathNameObject]
	## 模组表
	var mods_list: Array[ModRegistryObject]
	## 附属包表
	var addons_list: Array[AddonRegistryObject]

## 路径名称对象，用于记录pack.json中列表中的对象
class PathNameObject extends RefCounted:
	## 路径
	var path: String
	## 名称
	var name: String
	func _init(new_path: String, new_name: String) -> void:
		path = new_path
		name = new_name

## 模组注册对象
class ModRegistryObject extends RefCounted:
	## 路径
	var path: String
	## 名称
	var name: String
	## 哈希验证表
	var hash_list: Array[HashListObject]
	func _init(new_path: String, new_name: String, new_hash_list: Array[HashListObject] = []) -> void:
		path = new_path
		name = new_name
		hash_list = new_hash_list

## 附属包注册对象
class AddonRegistryObject extends RefCounted:
	## 路径
	var path: String
	## 名称
	var name: String
	## 模组列表
	var mods: Array[ModRegistryObject]
	## 支持安装的难度，视addons/<addon>/difficults中的目录决定，存在与注册难度路径对应的路径即视为支持，另外有_作为通配，存在通配时将支持安装到任何难度
	## 本项只记录从附属包元数据反序列化来的数据，并不经过检测，请在后续的逻辑中进行检测
	var support_difficults: PackedStringArray
	func _init(new_path: String, new_name: String, new_support_difficults: PackedStringArray = [], new_mods: Array[ModRegistryObject] = []) -> void:
		path = new_path
		name = new_name
		support_difficults = new_support_difficults
		mods = new_mods

## 哈希验证表元素
class HashListObject extends RefCounted:
	## 路径
	var path: String
	## MD5
	var md5: String
	func _init(new_path: String, new_md5: String) -> void:
		path = new_path
		md5 = new_md5

## 难度注册项，一个实例可以记录一个难度的信息，并在注册表中按顺序排列以代表难度排序
#class DifficultRegistryObj extends RefCounted:
	### 难度所在路径，参见pack.json:difficults[].path，代表该难度注册项对应的安装包中的难度目录名称
	#var path: String
	### 难度的显示名称，参见pack.json:difficults[].name，代表该难度注册项对应的难度显示名称
	#var name: String
