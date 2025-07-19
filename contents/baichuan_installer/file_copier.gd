extends RefCounted
class_name BaiChuanInstaller_FileCopier
## 百川安装器-文件复制器。以静态运行

## 将源目录中的内容递归地复制到目标目录中，需要传入两个绝对路径，返回成功与否
## 当目标目录不存在时，本方法需要实现其的创建功能
static func copy_recursive(source_dir: String, target_dir: String, logger: BaiChuanInstaller_Logger) -> bool:
	if (not (target_dir.is_absolute_path() and source_dir.is_absolute_path())): #如果给定的路径不是绝对路径
		logger.log_error("FileCopier: 意外异常，请联系安装器开发者报告问题，copy_recursive()方法接收到了非绝对路径的参数")
		return false
	if (not DirAccess.dir_exists_absolute(source_dir)): #如果源目录不存在
		logger.log_error("FileCopier: 源目录不存在")
		return false
	DirAccess.make_dir_recursive_absolute(target_dir) #递归创建目标目录
	var target_dir_access: DirAccess = DirAccess.open(target_dir)
	return true
