extends RefCounted
class_name BaiChuanInstaller_ScriptExecuter
## 百川安装器-脚本执行器

## 上一次方法调用是否包含错误
var was_last_operation_error: bool = false

## 分段脚本，同时检查命令格式，返回一个容纳了分段后命令的数组。如果出错was_last_operation_error会变为true，届时该方法返回的输出请勿信任
func split_script(script_content: String, logger: BaiChuanInstaller_Logger) -> Array[PackedStringArray]:
	was_last_operation_error = true
	var commands: PackedStringArray = script_content.split("\n", false)
	var result: Array[PackedStringArray] = []
	for command in commands: #遍历每行文本
		var splitted: PackedStringArray = CommandSplitter.split(command, logger) #获取一个已分段数组，如果为空数组代表出错
		if (splitted.is_empty()): #如果数组为空，意味着分段时出错
			was_last_operation_error = false
			logger.log_error("命令分段出错，该行命令完整内容：" + command)
		result.append(splitted)
	return result

## 已解析的脚本，定义本类是用来其他部分代码强类型化的
class ScriptParsed extends RefCounted:
	## 该脚本的已分段命令
	var commands_splitted: Array[PackedStringArray]

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
