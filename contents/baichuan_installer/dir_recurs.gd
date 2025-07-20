extends RefCounted
class_name BaiChuanInstaller_DirRecurs
## 百川安装器-目录递归器。以静态运行

## 将源目录中的内容递归地复制到目标目录中，需要传入两个绝对路径，返回成功与否
## 当目标目录不存在时，本方法需要实现其的创建功能
static func copy_recursive(source_dir: String, target_dir: String, logger: BaiChuanInstaller_Logger) -> bool:
	if (not (target_dir.is_absolute_path() and source_dir.is_absolute_path())): #如果给定的路径不是绝对路径
		logger.log_error("FileRecurs: 意外异常，请联系安装器开发者报告问题，copy_recursive()方法接收到了非绝对路径的参数")
		return false
	if (not DirAccess.dir_exists_absolute(source_dir)): #如果源目录不存在
		logger.log_error("FileRecurs: 源目录不存在")
		return false
	var success: bool = true
	DirAccess.make_dir_recursive_absolute(target_dir) #递归创建目标目录
	var files: PackedStringArray = DirAccess.get_files_at(source_dir) #获取当前源目录下的所有文件
	for file in files: #遍历文件
		if (FileAccess.file_exists(source_dir.path_join(file))):
			DirAccess.copy_absolute(source_dir.path_join(file), target_dir.path_join(file))
			continue
		success = false
		logger.log_error("FileRecurs: 文件在复制过程中丢失：" + source_dir.path_join(file))
	var dirs: PackedStringArray = DirAccess.get_directories_at(source_dir) #获取当前源目录下的所有目录
	for dir in dirs: #遍历目录
		DirAccess.make_dir_recursive_absolute(target_dir.path_join(dir))
		success = success and copy_recursive(source_dir.path_join(dir), target_dir.path_join(dir), logger)
	return success

## 删除一个文件或递归地删除一个目录，返回成功与否
static func delete_recursive(target: String, logger: BaiChuanInstaller_Logger) -> bool:
	if (FileAccess.file_exists(target)):
		if (DirAccess.remove_absolute(target) != OK):
			logger.log_error("FileRecurs: 删除文件时出错：" + target)
			return false
	elif (DirAccess.dir_exists_absolute(target)):
		return clear_recursive(target, logger)
	logger.log_warn("FileRecurs: 未找到文件或目录：" + target)
	return false

## 递归地清空一个目录，返回成功与否
static func clear_recursive(target_dir: String, logger: BaiChuanInstaller_Logger) -> bool:
	var success: bool = true
	if (not target_dir.is_absolute_path()):
		logger.log_error("FileRecurs: 意外异常，请联系安装器开发者报告问题，clear_recursive()方法接收到了非绝对路径的参数")
		return false
	for file in DirAccess.get_files_at(target_dir):
		var file_path: String = target_dir.path_join(file)
		if (FileAccess.file_exists(file_path)):
			success = success and DirAccess.remove_absolute(file_path) == OK
			continue
		logger.log_warn("FileRecurs: 文件在删除过程中丢失：" + file_path)
	for dir in DirAccess.get_directories_at(target_dir):
		var dir_path: String = target_dir.path_join(dir)
		if (DirAccess.dir_exists_absolute(dir_path)):
			success = success and clear_recursive(dir_path, logger)
			if (DirAccess.remove_absolute(dir_path) != OK):
				success = false
				logger.log_error("FileRecurs: 删除目录时出错：" + dir_path)
			continue
		logger.log_warn("FileRecurs: 目录在删除过程中丢失：" + dir_path)
	return success
