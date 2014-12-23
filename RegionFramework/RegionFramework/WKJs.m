//
//  WKJs.m
//  RegionFramework
//
//  单实例运行，启动时载入所有的脚本；
//
//  Created by 秦 道平 on 14/12/11.
//  Copyright (c) 2014年 秦 道平. All rights reserved.
//

#import "WKJs.h"
#import <UIKit/UIKit.h>
@interface WKJs()
@property (nonatomic,retain) NSOperationQueue *globalQueue;
@end
@implementation WKJs
-(id)initWithJSContext:(JSContext *)js{
    self = [super init];
    if (self){
        self.globalQueue = [[NSOperationQueue alloc]init];
        self.js = js;
        self.js.exceptionHandler = ^(JSContext *context,JSValue *exception){
            NSLog(@"js error:%@",exception);
        };
        [self loadJs];
    }
    return self;
}
+(WKJs*)localJs{
    static WKJs *js = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        JSContext *context = [[JSContext alloc]init];
        js = [[WKJs alloc]initWithJSContext:context];
    });
    return js;
}
-(void)loadJs{
    [self load_console_log];
    [self load_log_activity];
    [self load_log_activity_read];
    [self load_dir_document];
    [self load_dir_temp];
    [self load_dir_activity];
    [self load_file_writes];
    [self load_file_reads];
    [self load_file_append];
    [self load_file_delete];
    [self load_file_exists];
    [self load_http_get];
    [self load_http_post];
    [self load_userdefault_set];
    [self load_userdefault_get];
    [self load_send_notification];
}
-(JSValue*)evaluateScript:(NSString *)script{
    NSLog(@"%@",script);
    return [self.js evaluateScript:script];
}
#pragma mark - log
///在控制台输出日志,wk_console_log(str)
-(void)load_console_log{
    self.js[@"wk_console_log"]=^(NSString *log){
        NSLog(@"%@",log);
    };
}
///写入activity的日志文件,wk_console_log(str,identifier)
-(void)load_log_activity{
    self.js[@"wk_log_activity"]=^(NSString* log, NSString* identifier){
        NSDate *date = [NSDate date];
        NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
        formatter.dateFormat = @"yyyyMMdd";
        NSString *date_str = [formatter stringFromDate:date];
        NSString *document=NSTemporaryDirectory();
        NSString *dir = [document stringByAppendingPathComponent:date_str];
        if (![[NSFileManager defaultManager] fileExistsAtPath:dir]){
            [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
        }
        NSString *filename=[dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.log",identifier]];
        NSString *time_str = [formatter stringFromDate:date];
        NSString *log_line = [NSString stringWithFormat:@"%@: %@ \n",time_str,log];
        if (![[NSFileManager defaultManager] fileExistsAtPath:filename]){
            [[NSFileManager defaultManager] createFileAtPath:filename contents:[log_line dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
        }
        else{
            NSFileHandle *fileHandler= [NSFileHandle fileHandleForWritingAtPath:filename];
            [fileHandler seekToEndOfFile];
            [fileHandler writeData:[log_line dataUsingEncoding:NSUTF8StringEncoding]];
            [fileHandler closeFile];
        }
    };
}
///读取activity今天的日志文件,wk_log_activity_read(identifier)
-(void)load_log_activity_read{
    self.js[@"wk_log_activity_read"] = ^(NSString *identifier){
        NSDate *date = [NSDate date];
        NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
        formatter.dateFormat = @"yyyyMMdd";
        NSString *date_str = [formatter stringFromDate:date];
        NSString *document=NSTemporaryDirectory();
        NSString *dir = [document stringByAppendingPathComponent:date_str];
        if (![[NSFileManager defaultManager] fileExistsAtPath:dir]){
            [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
        }
        NSString *filename=[dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.log",identifier]];
        return [NSString stringWithContentsOfFile:filename encoding:NSUTF8StringEncoding error:nil];
    };
}
#pragma mark - dir
///沙盒 document 文件的路径,wk_dir_document()
-(void)load_dir_document{
    self.js[@"wk_dir_document"] = ^(){
        return NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    };
}
///沙盒 temp 文件的路径, wk_dir_temp()
-(void)load_dir_temp{
    self.js[@"wk_dir_temp"] = ^(){
        return NSTemporaryDirectory();
    };
}
///activity identifier 对应的目录,wk_dir_activity(identifier)
-(void)load_dir_activity{
    self.js[@"wk_dir_activity"] = ^(NSString* identifier){
        NSString *document=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        return [document stringByAppendingPathComponent:identifier];
    };
}
#pragma mark - file
///写入字符串到文件, wk_file_writes(str,filename)
-(void)load_file_writes{
    self.js[@"wk_file_writes"] = ^(NSString *content, NSString *filename){
        [content writeToFile:filename atomically:YES encoding:NSUTF8StringEncoding error:nil];
    };
}
///从文件读取字符串, wk_file_reads(filename)
-(void)load_file_reads{
    self.js[@"wk_file_reads"] = ^(NSString *filename){
        return [NSString stringWithContentsOfFile:filename encoding:NSUTF8StringEncoding error:nil];
    };
}
///往文件追加写入字符串, wk_file_append(str,filename)
-(void)load_file_append{
    self.js[@"wk_file_append"] = ^(NSString *content, NSString *filename){
        if (![[NSFileManager defaultManager] fileExistsAtPath:filename]){
            [[NSFileManager defaultManager] createFileAtPath:filename contents:[content dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
        }
        else{
            NSFileHandle *fileHandler= [NSFileHandle fileHandleForWritingAtPath:filename];
            [fileHandler seekToEndOfFile];
            [fileHandler writeData:[content dataUsingEncoding:NSUTF8StringEncoding]];
            [fileHandler closeFile];
        }
    };
}
///删除文件, wk_file_delete(filename)
-(void)load_file_delete{
    self.js[@"wk_file_delete"] = ^(NSString *filename){
        [[NSFileManager defaultManager] removeItemAtPath:filename error:nil];
    };
}
///检查文件是否存在, wk_file_exists(filename)
-(void)load_file_exists{
    self.js[@"wk_file_exists"] = ^(NSString *filename){
        return [[NSFileManager defaultManager] fileExistsAtPath:filename];
    };
}
#pragma mark - http
/// http get 访问, wk_http_get(path,callback_function whose first argument is str)
-(void)load_http_get{
    WKJs *_weak_self = self;
    self.js[@"wk_http_get"] = ^(NSString *path,NSString *callback){
        NSURL *url = [NSURL URLWithString:path];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        [NSURLConnection sendAsynchronousRequest:request queue:_weak_self.globalQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            NSString *str = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"%@",str);
            NSString *callback_script =[NSString stringWithFormat:@"%@(\"%@\");",callback,str];
            [_weak_self.js evaluateScript:[callback_script stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"]];
        }];
    };
}
/// http post 访问, wk_http_post(path,form_dict,callback_function whose first argument is str)
-(void)load_http_post{
    WKJs *_weak_self = self;
    self.js[@"wk_http_post"] = ^(NSString *path, NSDictionary *form, NSString *callback){
        NSURL *url = [NSURL URLWithString:path];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        NSMutableString *body=[NSMutableString string];
        for (NSString *key in form.allKeys) {
            [body appendFormat:@"%@=%@&",key,form[key]];
        };
        request.HTTPBody = [body dataUsingEncoding:NSUTF8StringEncoding];
        [request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        [NSURLConnection sendAsynchronousRequest:request queue:_weak_self.globalQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            NSString *str = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"%@",str);
            NSString *callback_script =[NSString stringWithFormat:@"%@(\"%@\");",callback,str];
            [_weak_self.js evaluateScript:[callback_script stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"]];
        }];
    };
}
#pragma mark - user default
///写入 NSUserDefault, wk_userdefault_set(key,value)
-(void)load_userdefault_set{
    self.js[@"wk_userdefault_set"] = ^(NSString *key,NSString *value){
        [[NSUserDefaults standardUserDefaults] setValue:value forKey:key];
        [[NSUserDefaults standardUserDefaults] synchronize];
    };
}
///读取 NSUserDefault, wk_userdefault_get(key)
-(void)load_userdefault_get{
    self.js[@"wk_userdefault_get"] = ^(NSString *key){
        return [[NSUserDefaults standardUserDefaults] stringForKey:key];
    };
}
#pragma mark - local notification
///发送本地通知, wk_send_notification(alert,sound,badge,userinfo)
-(void)load_send_notification{
    self.js[@"wk_send_notification"] = ^(NSString *alert,NSString *sound,int badge, NSDictionary *userinfo){
        NSLog(@"send_notification:%@",alert);
        UILocalNotification *notification = [[UILocalNotification alloc]init];
        notification.alertBody=alert;
        notification.soundName=sound;
        notification.applicationIconBadgeNumber=badge;
        notification.fireDate=[NSDate dateWithTimeIntervalSinceNow:3.0];
        notification.timeZone=[NSTimeZone defaultTimeZone];
        notification.alertAction=@"打开";
        notification.userInfo=userinfo;
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    };
}
@end
