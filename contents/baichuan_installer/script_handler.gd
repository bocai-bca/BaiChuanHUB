extends RefCounted
class_name BaiChuanInstaller_ScriptHandler
## 百川安装器-脚本处理器

## 上一次方法调用是否包含错误
var was_last_operation_error: bool = false

## 解析脚本的高级封装，给定一个指向脚本文件的绝对路径，返回一个ScriptParsed，或者发生错误(包括命令格式、语法错误或引用了不存在的资源)时返回null，自身不影响was_last_operation_error
func parse_script(absolute_path: String, pack_access: BaiChuanInstaller_PackAccess, logger: BaiChuanInstaller_Logger) -> ScriptParsed:
	if (not FileAccess.file_exists(absolute_path)): #如果路径指不到文件
		logger.log_error("未找到脚本：" + absolute_path)
		return null
	var commands_splitted: Array[PackedStringArray] = split_script(FileAccess.get_file_as_string(absolute_path), logger)
	if (was_last_operation_error): #如果分段脚本时出现错误
		logger.log_error("脚本分段因错误中止，路径：" + absolute_path)
		return null
	var was_command_error: bool = false
	for command_splitted in commands_splitted: #遍历所有已分段命令
		if (not is_command_executable(command_splitted, pack_access)): #如果该命令不可执行
			was_command_error = true
			logger.log_error("命令检查出错，该行命令完整分段：" + str(command_splitted))

	return ScriptParsed.new(commands_splitted)

## 分段脚本，同时检查命令格式，返回一个容纳了分段后命令的数组。如果出错was_last_operation_error会变为true，届时该方法返回的输出请勿信任
func split_script(script_content: String, logger: BaiChuanInstaller_Logger) -> Array[PackedStringArray]:
	was_last_operation_error = false
	var commands: PackedStringArray = script_content.split("\n", false)
	var result: Array[PackedStringArray] = []
	for command in commands: #遍历每行文本
		var splitted: PackedStringArray = CommandSplitter.split(command, logger) #获取一个已分段数组，如果为空数组代表出错
		if (splitted.is_empty()): #如果数组为空，意味着分段时出错
			was_last_operation_error = true
			logger.log_error("命令分段出错，该行命令完整内容：" + command)
		result.append(splitted)
	return result

## 检查命令是否可安全执行，结果将返回到was_last_operation_error，方法将返回错误理由
func is_command_executable(command_splitted: PackedStringArray, pack_access: BaiChuanInstaller_PackAccess) -> String:
	if (command_splitted.is_empty()): #如果命令为空
		was_last_operation_error = true
		return "不允许空行命令"
	match (command_splitted[0]): #匹配首项
		"q", "b": #qmods和bepinex，用于将模组添加到游戏特定位置
			if (command_splitted.size() < 2): #如果命令分段数不足
				was_last_operation_error = true
				return "命令缺少参数"
			var ref_name: String = command_splitted[1]
			for mod in pack_access.pack_meta.mods_list: #遍历模组列表
				if (ref_name == mod.name): #如果名称匹配上了
					was_last_operation_error = false
					return "命令可安全执行"
			was_last_operation_error = true
			return "命令引用了不存在的模组引用名"
		"d", "c": #delete和clear，用于删除文件/目录或清空目录
			if (command_splitted.size() < 2): #如果命令分段数不足
				was_last_operation_error = true
				return "命令缺少参数"
		"cf", "cd": #copyfile和copydir，用于复制文件或目录
			if (command_splitted.size() < 4): #如果命令分段数不足
				was_last_operation_error = true
				return "命令缺少参数"
			match (command_splitted[1]): #匹配第二段
				"p":
					if (not (FileAccess.file_exists(pack_access.dir_access.get_current_dir().path_join(command_splitted[2])) or pack_access.dir_access.dir_exists(command_splitted[2]))): #如果不存在指定的文件或目录
						was_last_operation_error = true
						return "命令引用的包内路径不存在"
					was_last_operation_error = false
					return "命令可安全执行"
				"g":
					was_last_operation_error = false
					return "命令可安全执行"
			was_last_operation_error = true
			return "命令使用了不存在的子命令"
	was_last_operation_error = true
	return "无效命令"

## 执行命令
func run_command(command_splitted: PackedStringArray, logger: BaiChuanInstaller_Logger) -> bool:
	return true

## 已解析的脚本，定义本类是用来其他部分代码强类型化的
class ScriptParsed extends RefCounted:
	## 该脚本的已分段命令
	var commands_splitted: Array[PackedStringArray]
	func _init(new_commands_splitted: Array[PackedStringArray]) -> void:
		commands_splitted = new_commands_splitted

class CommandSplitter extends Object:
	## 空格
	const SPACE: String = " "
	## 引号
	const QUOTATION_MARK: String = "\""

	## 命令分段器，将一行命令按语法格式分为多个段，如果出现问题将返回空数组，也因此请勿传入空文本
	static func split(command: String, logger: BaiChuanInstaller_Logger) -> PackedStringArray:
		var result: PackedStringArray = []
		var length: int = command.length() #获取行长度
		var current_at: int = 0 #字符索引指针
		var is_in_quotation: bool = false #是否在引号内，为true时将使分段器暂时不以空格进行分段
		var current_start_at: int = 0 #当前分段的起始索引位置
		while (current_at < length): #循环直到指针超出
			if (command[current_at] == QUOTATION_MARK): #如果当前字符为引号
				if (is_in_quotation): #如果当前状态处在引号内
					## 此处为退出引号
					if (is_offset_part_bound(command, current_at, 1)): #如果右侧是边界
						is_in_quotation = false #标记当前处于引号外
					else: #否则(右侧不是边界，这就不对了)
						logger.log_error("分段命令时发现问题，在退出引号时发现右侧紧跟其他内容")
						return []
				else: #否则(当前状态在引号外)
					## 此处为进入引号
					if (is_offset_part_bound(command, current_at, -1)): #如果左侧是边界
						is_in_quotation = true #标记当前处于引号内
					else: #否则(左侧不是边界，这就不对了)
						logger.log_error("分段命令时发现问题，在非分段处发现了进入引号")
						return []
			elif (command[current_at] == SPACE): #否则如果当前字符为空格
				if (is_in_quotation): #如果当前字符处于引号内
					## 直接记录分段
					result.append(command.substr(current_start_at, current_at - current_start_at + 1))
					current_start_at = current_at + 1
				#else: #否则(当前字符不处于引号内)
					## 忽视分段
			current_at += 1
		return result

	## 给定索引的特定偏移处的是否是段落边界，偏移索引正数代表向右偏移，负数代表向左偏移，0代表不偏移，如果出现问题也将返回false
	## 将使用空格和超出command参数边界作为判断标准，但无法对空格进行是否在引号内进行判断
	static func is_offset_part_bound(command: String, focus_index: int, index_offset: int) -> bool:
		var index_after_offset: int = focus_index + index_offset #制作求和后的索引
		if (0 <= index_after_offset and index_after_offset < command.length()): #如果求和后的索引在有效范围内
			return command[index_after_offset] == SPACE
		return true
