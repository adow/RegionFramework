//
//  WKRegionActivity.h
//  RegionFramework
//
//  Created by 秦 道平 on 14/12/8.
//  Copyright (c) 2014年 秦 道平. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WKRegionActivity : NSObject{
    
}
@property (nonatomic,copy) NSString *identifier;
///区域名字
@property (nonatomic,copy) NSString *regionName;
///过期时间的时间戳
@property (nonatomic,assign) NSTimeInterval expireAt;
///进入时的脚本
@property (nonatomic,copy) NSString *enterScripts;
///退出时的脚本
@property (nonatomic,copy) NSString *exitScripts;
///过期时间
@property (nonatomic,readonly) NSDate* expireAt_dt;
///当前是否已经过期
@property (nonatomic,readonly) BOOL isExpired;
///地理围栏坐标
@property (nonatomic,assign) double centerLat;
///地理围栏坐标
@property (nonatomic,assign) double centerLng;
///地理围栏半径
@property (nonatomic,assign) double centerRadius;
///iBeacon uuid
@property (nonatomic,copy) NSString *uuid;
///iBeacon major
@property (nonatomic,copy) NSString *major;
///iBeacon minor
@property (nonatomic,copy) NSString *minor;
///是否是地理围栏
@property (nonatomic,readonly) BOOL isCircularRegion;
///是否是iBeacon区域
@property (nonatomic,readonly) BOOL isBeaconRegion;
@property (nonatomic,readonly) NSDictionary *dict;
///日志路径
@property (nonatomic,readonly) NSString *logFilename;
///日志内容
@property (nonatomic,readonly) NSString *logContent;
+(instancetype)regionActivityFromDict:(NSDictionary*)dict;
+(instancetype)beaconActivityIdentifier:(NSString*)identifier regionName:(NSString*)regionName uuid:(NSString*)uuid;
+(instancetype)circularActivityIdentifier:(NSString*)identifier regionName:(NSString*)regionName centerLat:(double)centerLat centerLng:(double)centerLng centerRadius:(double)centerRadius;
///运行进入区域时的脚本
-(void)runEnterScripts;
///运行退出时的脚本
-(void)runExitScripts;
-(void)logString:(NSString*)log;
@end
