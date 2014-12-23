## WKJs

## variables
* wk_activity_identifier: 当前activity 的identifier;
* wk_activity_region_name: 当前activity 的 region_name;

## console
* wk_console_log(str): 在控制台输出日志,

## Activity
* wk_log_activity(str,identifier): 写入activity的日志文件
* wk_log_activity_read(identifier): 返回activity今天的日志文件

## dir
* wk_dir_document():返回沙盒 document 文件的路径
* wk_dir_temp():返回沙盒 temp 文件的路径,
* wk_dir_activity(identifier):返回activity identifier 对应的目录,

## file
* wk_file_writes(str,filename): 写入字符串到文件
* wk_file_reads(filename): 返回从文件读取字符串
* wk_file_append(str,filename): 往文件追加写入字符串
* wk_file_delete(filename): 删除文件
* wk_file_exists(filename): 检查文件是否存在

## http
* wk_http_get(path,callback_function whose first argument is str): http get 访问
* wk_http_post(path,form_dict,callback_function whose first argument is str): http post 访问

## NSUserDefault
* wk_userdefault_set(key,value): 写入 NSUserDefault
* wk_userdefault_get(key): 返回读取 NSUserDefault的字符串

## Local Notification
* wk_send_notification(alert,sound,badge,userinfo): 发送本地通知
