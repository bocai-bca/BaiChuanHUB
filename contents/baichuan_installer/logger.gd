extends RefCounted
class_name BaiChuanInstaller_Logger
## 日志输出

## 日志
var log_string: String = ""

## 清除日志
func log_clear() -> void:
	log_string = ""

## 在日志中追加一个消息
func log_info(text: String) -> void:
	log_string += text + "\n"
	print(text)

## 在日志中追加一个警告
func log_warn(text: String) -> void:
	log_string += "[color=yellow]" + text + "[/color]\n"
	push_warning(text)

## 在日志中追加一个错误
func log_error(text: String) -> void:
	log_string += "[color=red]" + text + "[/color]\n"
	push_error(text)
