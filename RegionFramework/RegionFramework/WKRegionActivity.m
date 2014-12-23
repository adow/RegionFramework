//
//  WKRegionActivity.m
//  RegionFramework
//
//  Created by 秦 道平 on 14/12/8.
//  Copyright (c) 2014年 秦 道平. All rights reserved.
//

#import "WKRegionActivity.h"
#import "WKJs.h"
#define kRegionActivityIdentifier @"identifier"
#define kRegionActivityRegionName @"region_name"
#define kRegionActivityExpireAt @"expire_at"
#define kRegionActivityEnterScripts @"enter_scripts"
#define kRegionActivityExitScripts @"exit_scripts"
#define kRegionActivityCenterLat @"center_lat"
#define kRegionActivityCenterLng @"center_lng"
#define kRegionActivityCenterRadius @"center_radius"
#define kRegionActivityUUID @"uuid"
#define kRegionActivityMajor @"major"
#define kRegionActivityMinor @"minor"
@implementation WKRegionActivity
-(id)init{
    self = [super init];
    if (self){
        self.identifier = @"";
        self.regionName = @"";
        self.enterScripts = @"";
        self.exitScripts = @"";
        self.uuid = @"";
        self.major = @"";
        self.minor = @"";
    }
    return self;
}
-(NSDate*)expireAt_dt{
    return [NSDate dateWithTimeIntervalSince1970:self.expireAt];
}
///是否过期
-(BOOL)isExpired{
    double now = [[NSDate date] timeIntervalSince1970];
    return now>self.expireAt;
}
///是否是地理围栏区域
-(BOOL)isCircularRegion{
    if (self.centerLat != 0.0 && self.centerLng !=0.0 && self.centerRadius != 0.0){
        return YES;
    }
    else{
        return NO;
    }
}
///是否是iBeacon区域
-(BOOL)isBeaconRegion{
    if (self.uuid.length >0 ){
        return YES;
    }
    else{
        return NO;
    }
}
-(NSString*)description{
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    formatter.timeStyle = NSDateFormatterShortStyle;
    formatter.dateStyle = NSDateFormatterShortStyle;
    NSString* expire_str = [formatter stringFromDate:self.expireAt_dt];
    if (self.isCircularRegion){
        return [NSString stringWithFormat:@"identifer:%@,regionName:%@,center_lat:%f,center_lng:%f,center_radius:%f,expire:%@",self.identifier,self.regionName,self.centerLat,self.centerLng,self.centerRadius,expire_str];
    }
    else if (self.isBeaconRegion){
        return [NSString stringWithFormat:@"identifier:%@,regionName:%@,uuid:%@,major:%@,minor:%@,%@",self.identifier,self.regionName,self.uuid,self.major,self.minor,expire_str];
    }
    else{
        return @"unknown activity region";
    }
}
-(NSDictionary*)dict{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[kRegionActivityIdentifier] = self.identifier;
    dict[kRegionActivityRegionName] = self.regionName;
    dict[kRegionActivityExpireAt] = [NSNumber numberWithDouble:self.expireAt];
    dict[kRegionActivityEnterScripts] = self.enterScripts;
    dict[kRegionActivityExitScripts] = self.exitScripts;
    dict[kRegionActivityCenterLat] = [NSNumber numberWithDouble:self.centerLat];
    dict[kRegionActivityCenterLng] = [NSNumber numberWithDouble:self.centerLng];
    dict[kRegionActivityCenterRadius] = [NSNumber numberWithDouble:self.centerRadius];
    dict[kRegionActivityUUID] = self.uuid;
    dict[kRegionActivityMajor] = self.major;
    dict[kRegionActivityMinor] = self.minor;
    return dict;
    
}
+(instancetype)regionActivityFromDict:(NSDictionary *)dict{
    WKRegionActivity *activity = [[WKRegionActivity alloc]init];
    activity.identifier = dict[kRegionActivityIdentifier];
    activity.regionName = dict[kRegionActivityRegionName];
    activity.expireAt = [dict[kRegionActivityExpireAt] doubleValue];
    activity.enterScripts = dict[kRegionActivityEnterScripts];
    activity.exitScripts = dict[kRegionActivityExitScripts];
    activity.centerLat = [dict[kRegionActivityCenterLat] doubleValue];
    activity.centerLng = [dict[kRegionActivityCenterLng] doubleValue];
    activity.centerRadius = [dict[kRegionActivityCenterRadius] doubleValue];
    activity.uuid = dict[kRegionActivityUUID];
    activity.major = dict[kRegionActivityMajor];
    activity.minor = dict[kRegionActivityMinor];
    return activity;
}
+(instancetype)beaconActivityIdentifier:(NSString *)identifier regionName:(NSString *)regionName uuid:(NSString *)uuid{
    WKRegionActivity *activity = [[WKRegionActivity alloc]init];
    activity.identifier = identifier;
    activity.regionName = regionName;
    activity.uuid = uuid;
    return activity;
}
+(instancetype)circularActivityIdentifier:(NSString *)identifier regionName:(NSString *)regionName centerLat:(double)centerLat centerLng:(double)centerLng centerRadius:(double)centerRadius{
    WKRegionActivity *activity = [[WKRegionActivity alloc]init];
    activity.identifier = identifier;
    activity.regionName = regionName;
    activity.centerLat = centerLat;
    activity.centerLng = centerLng;
    activity.centerRadius = centerRadius;
    return activity;
}
///进入区域时运行脚本
-(void)runEnterScripts{
    NSLog(@"run enter scripts:\n%@",self.enterScripts);
    ///运行时注入全局变量
    NSMutableString *global_scripts = [NSMutableString string];
    [global_scripts appendFormat:@"var wk_activity_identifier = '%@';\n",self.identifier];///区域的identfiier
    [global_scripts appendFormat:@"var wk_activity_region_name = '%@';\n",self.regionName];///区域名字
    [[WKJs localJs] evaluateScript:global_scripts];
    [[WKJs localJs] evaluateScript:self.enterScripts];
}
///退出区域时运行脚本
-(void)runExitScripts{
    NSLog(@"run exit scrips:\n%@",self.exitScripts);
//    [[WKJs localJs] evaluateScript:@"wk_console_log('exit');"];
//    JSValue *dir_document = [[WKJs localJs] evaluateScript:@"wk_dir_document();"];
//    NSLog(@"dir_document:%@",[dir_document toString]);
//    [[WKJs localJs] evaluateScript:@"wk_send_notification('exit notification',null,1,{'module':'news','id':123});"];
    
//    NSMutableString *scripts = [NSMutableString string];
//    [scripts appendString:@"wk_console_log('exit');\n"];
//    [scripts appendString:@"var document = wk_dir_document();\n"];
//    [scripts appendString:@"var temp = wk_dir_temp();\n"];
//    [scripts appendString:@"wk_log_activity('document:'+document,'test.beacon.office');\n"];
//    [scripts appendString:@"wk_log_activity('document:'+temp,'test.beacon.office');\n"];
//    [scripts appendString:@"var test_file = document + '/' + 'test.txt';\n"];
//    [scripts appendString:@"wk_file_append('document:'+document+'\\n',test_file);\n"];
//    [scripts appendString:@"wk_file_append('temp:'+temp+'\\n',test_file);\n"];
//    [scripts appendString:@"wk_userdefault_set('test_key','test_value');\n"];
//    [scripts appendString:@"var test_value = wk_userdefault_get('test_key');\n"];
//    [scripts appendString:@"wk_log_activity('test_value:'+test_value,'test.beacon.office');\n"];
//    [scripts appendString:@"wk_send_notification('test_value:'+test_value,'default',1,null);\n"];
//    [[WKJs localJs] evaluateScript:scripts];
    
//    NSMutableString *scripts = [NSMutableString string];
//    [scripts appendString:@"function check_in(in_out){\n"];
//    [scripts appendString:@"var temp = wk_dir_temp();\n"];
//    [scripts appendString:@"var today = new Date();\n"];
//    [scripts appendString:@"var today_str = String(today.getFullYear()) + String(today.getMonth()) + String(today.getDate());\n"];
//    [scripts appendString:@"var filename = temp+'/' + wk_activity_identifier + '_' + today_str + '_check_in.log';\n"];
//    [scripts appendString:@"wk_console_log(filename);\n"];
//    [scripts appendString:@"var timestamp = String(Date.now());\n"];
//    [scripts appendString:@"var time_str = today.toString();\n"];
//    [scripts appendString:@"var log = in_out + '|' + time_str + '|' + timestamp + '|' + wk_activity_identifier +'|' + wk_activity_region_name +'\\n';\n"];
//    [scripts appendString:@"wk_console_log(log);\n"];
//    [scripts appendString:@"wk_file_append(log,filename);\n"];
//    [scripts appendString:@"}\n"];
//    [scripts appendString:@"check_in('in');\n"];
//    [[WKJs localJs] evaluateScript:scripts];
    
//    NSMutableString *scripts_2 = [NSMutableString string];
//    [scripts_2 appendString:@"function send_check_notification(){\n"];
//    [scripts_2 appendString:@"var now = Date.now();\n"];
//    [scripts_2 appendString:@"var k_notification_time = wk_activity_identifier+'.notification_time';\n"];
//    [scripts_2 appendString:@"var last_notification_time = wk_userdefault_get(k_notification_time);\n"];
//    [scripts_2 appendString:@"wk_console_log(String('last_notification_time:'+last_notification_time));\n"];
//    [scripts_2 appendString:@"if (last_notification_time){\n"];
//    [scripts_2 appendString:@"var duration = Math.abs(now-parseInt(last_notification_time));\n"];
//    [scripts_2 appendString:@"wk_console_log(String('duration:'+duration));\n"];
//    [scripts_2 appendString:@"if (duration < 60 * 1 * 1000){\n"];
//    [scripts_2 appendString:@"wk_console_log('send notification too short');\n"];
//    [scripts_2 appendString:@"return;\n"];
//    [scripts_2 appendString:@"}\n"];
//    [scripts_2 appendString:@"}\n"];
//    [scripts_2 appendFormat:@"wk_userdefault_set(k_notification_time,String(now));"];
//    [scripts_2 appendString:@"wk_send_notification('欢迎回来上班','default',1,null);\n"];
//    [scripts_2 appendString:@"}\n"];
//    [scripts_2 appendString:@"send_check_notification();\n"];
//    [[WKJs localJs] evaluateScript:scripts_2];

    ///运行时注入全局变量
    NSMutableString *global_scripts = [NSMutableString string];
    [global_scripts appendFormat:@"var wk_activity_identifier = '%@';\n",self.identifier]; ///区域identifier
    [global_scripts appendFormat:@"var wk_activity_region_name = '%@';\n",self.regionName];///区域名字
    [[WKJs localJs] evaluateScript:global_scripts];
    [[WKJs localJs] evaluateScript:self.exitScripts];
}
#pragma mark - Log
-(NSString*)logFilename{
    NSDate *date = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    formatter.dateFormat = @"yyyyMMdd";
    NSString *date_str = [formatter stringFromDate:date];
    NSString *document=NSTemporaryDirectory();
    NSString *dir = [document stringByAppendingPathComponent:date_str];
    if (![[NSFileManager defaultManager] fileExistsAtPath:dir]){
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *filename=[dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.log",self.identifier]];
    return filename;
}
///写入日志
-(void)logString:(NSString*)log{
    NSDate *date = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    formatter.timeStyle = NSDateFormatterLongStyle;
    formatter.dateStyle=  NSDateFormatterShortStyle;
    NSString *time_str = [formatter stringFromDate:date];
    NSString *log_line = [NSString stringWithFormat:@"%@: %@ \n",time_str,log];
    NSString *log_filename = self.logFilename;
    if (![[NSFileManager defaultManager] fileExistsAtPath:log_filename]){
        [[NSFileManager defaultManager] createFileAtPath:log_filename contents:[log_line dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
    }
    else{
        NSFileHandle *fileHandler= [NSFileHandle fileHandleForWritingAtPath:[self logFilename]];
        [fileHandler seekToEndOfFile];
        [fileHandler writeData:[log_line dataUsingEncoding:NSUTF8StringEncoding]];
        [fileHandler closeFile];
    }
}
-(NSString*)logContent{
    NSString *content = [NSString stringWithContentsOfFile:self.logFilename encoding:NSUTF8StringEncoding error:nil];
    return content;
}
@end
