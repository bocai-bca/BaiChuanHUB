extends RefCounted
class_name BaiChuanInstaller_Logger
## 日志输出

## 多线程互斥锁
var mutex: Mutex
## 日志
var log_string: String = ""
## 自上次读取后的警告数量，由安装器进行复位
var warn_count_after_last_read: int = 0
## 自上次读取后的错误数量，由安装器进行复位
var error_count_after_last_read: int = 0

func _init(the_mutex: Mutex) -> void:
	mutex = the_mutex

## 清除日志
func log_clear() -> void:
	mutex.lock()
	log_string = ""
	warn_count_after_last_read = 0
	error_count_after_last_read = 0
	mutex.unlock()

## 在日志中追加一个消息
func log_info(text: String) -> void:
	mutex.lock()
	log_string += text + "\n"
	mutex.unlock()
	print(text)

## 在日志中追加一个暗淡消息
func log_darken(text: String) -> void:
	mutex.lock()
	log_string += "[color=web_gray]" + text + "[/color]\n"
	mutex.unlock()
	print(text)

## 在日志中追加一个警告
func log_warn(text: String) -> void:
	mutex.lock()
	log_string += "[color=yellow]" + text + "[/color]\n"
	warn_count_after_last_read += 1
	mutex.unlock()
	push_warning(text)

## 在日志中追加一个错误
func log_error(text: String) -> void:
	mutex.lock()
	log_string += "[color=red]" + text + "[/color]\n"
	error_count_after_last_read += 1
	mutex.unlock()
	push_error(text)
