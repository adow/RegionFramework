//
//  WKRegionActivities.m
//  RegionFramework
//
//  Created by 秦 道平 on 14/12/8.
//  Copyright (c) 2014年 秦 道平. All rights reserved.
//

#import "WKRegionActivities.h"
#import <CoreLocation/CoreLocation.h>

#define kLastUpdateTime @"region.activities.lastupdatetime"
#define kOn @"region.activities.on"
#define kFirstLaunch @"region.activities.firstlaunch"
@interface WKRegionActivities()<CLLocationManagerDelegate>
@property (nonatomic,readonly) NSString *localFilename;
@property (nonatomic,strong) CLLocationManager *locationManager;
///本地任务列表是否已经过期
@property (nonatomic,readonly) BOOL activitiesExpired;
///每个区域下对应的beacons
@property (nonatomic,strong) NSMutableDictionary *regionBeacons;
@property (nonatomic,strong) NSOperationQueue *globalQueue;
@end
@implementation WKRegionActivities
-(id)init{
    self = [super init];
    if (self){
        self.globalQueue = [[NSOperationQueue alloc]init];
        self.activities = [[NSMutableArray alloc]init];
        ///如果第一次运行直接开始
        if (![[NSUserDefaults standardUserDefaults] boolForKey:kFirstLaunch]){
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kFirstLaunch];
            [[NSUserDefaults standardUserDefaults] synchronize];
            NSLog(@"first launch and activities will run");
            self.on = YES;
        }
    }
    return self;
}
+(instancetype)sharedActivities{
    static WKRegionActivities *_activities = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _activities = [[WKRegionActivities alloc]init];
    });
    return _activities;
}
#pragma mark - Properties
-(BOOL)locationServicesEnabled{
    return [CLLocationManager locationServicesEnabled];
}
-(BOOL)isRangingAvailable{
    return [self.locationManager respondsToSelector:@selector(isRangingAvailable)] && [CLLocationManager isRangingAvailable];
}
-(void)setOn:(BOOL)on{
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:on] forKey:kOn];
    [[NSUserDefaults standardUserDefaults] synchronize];
    if (!on){
        [self stopLocationService];///关闭所有监控区域
    }
    else{
        [self startLocationService];///开始监控
    }
}
-(BOOL)on{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kOn];
}
-(void)setLastupdateTime:(double)lastupdateTime{
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithDouble:lastupdateTime] forKey:kLastUpdateTime];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
-(double)lastupdateTime{
    return [[[NSUserDefaults standardUserDefaults] stringForKey:kLastUpdateTime] doubleValue];
}
-(BOOL)activitiesExpired{
    double now = [NSDate date].timeIntervalSince1970;
    return fabs(now - self.lastupdateTime) > 3600 * 24;  /// 一天更新一次
}
///本地缓存的活动区域文件
-(NSString*)localFilename{
    NSString *document=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *filename=[document stringByAppendingPathComponent:@"region.activities.json"];
    return filename;
}
///全部正在监控的区域
-(NSArray*)allMonitoringRegions{
    return self.locationManager.monitoredRegions.allObjects;
}
#pragma mark - Activities
///读取本地缓存的区域活动任务列表,如果有本地文件，返回YES,如果没有返回NO
-(BOOL)_loadLocalActivities{
    NSLog(@"load local activities:%@",self.localFilename);
    NSData *data = [NSData dataWithContentsOfFile:self.localFilename];
    if (!data){
        NSLog(@"local activities not found");
        return NO;
    }
    NSArray *array = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    [self.activities removeAllObjects];
    for (NSDictionary *dict in array) {
        WKRegionActivity *activity = [WKRegionActivity regionActivityFromDict:dict];
        [self.activities addObject:activity];
    }
    return YES;
}
///强制更新区域活动任务列表
-(void)updateActivities{
    NSLog(@"updateActivities");
    self.lastupdateTime = [NSDate date].timeIntervalSince1970;
    ///刷新接口，更新任务列表，并保存在本地,更新列表，刷新监控区域
    NSString *path = [WKRegionActivitiesUpdatePath stringByAppendingFormat:@"?_=%@",[NSUUID UUID].UUIDString];
    NSURL *url = [NSURL URLWithString:path];
    NSLog(@"udpateActivities:%@",url.absoluteString);
    NSURLRequest *request =[NSURLRequest requestWithURL:url];
    [NSURLConnection sendAsynchronousRequest:request queue:self.globalQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [data writeToFile:self.localFilename atomically:NO];
            if ([self _loadLocalActivities]){
                [self _refreshMonitoringRegions];
            }
        });
        
    }];
}
///超过一定时间后更新活动列表
-(void)updateActivitiesIfExpired{
    if (self.activitiesExpired){
        [self updateActivities];
    }
    
}
///测试用的数据
-(void)_testUpdateActivities{
    WKRegionActivity *activity_1 = [WKRegionActivity beaconActivityIdentifier:@"test.beacon.office" regionName:@"智慧无锡技术部办公室" uuid:@"96EFF254-BDB5-4AAA-9CCA-3552C236DC29"];
    activity_1.major = @"0";
    activity_1.minor = @"5";
    activity_1.expireAt = [NSDate dateWithTimeIntervalSinceNow:3600*24*3].timeIntervalSince1970;
    
    WKRegionActivity *activity_2 = [WKRegionActivity circularActivityIdentifier:@"test.circular.building" regionName:@"无锡广电传媒中心" centerLat:31.5611234140784 centerLng:120.277440363643 centerRadius:500.0];
    activity_2.expireAt = [NSDate dateWithTimeIntervalSinceNow:3600*24*3].timeIntervalSince1970;
    
    NSArray *list = @[activity_1.dict,activity_2.dict,];
    NSData *data = [NSJSONSerialization dataWithJSONObject:list options:NSJSONWritingPrettyPrinted error:nil];
    [data writeToFile:self.localFilename atomically:YES];
    NSLog(@"write test local activities:%@",self.localFilename);
}
#pragma mark - Region
///使用identifier查找监控区域
-(CLRegion*)_findMonitoringRegionByIdentifier:(NSString*)identifier{
    __block CLRegion *region = nil;
    [self.locationManager.monitoredRegions.allObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CLRegion *find_region = (CLRegion*)obj;
        if ([find_region.identifier isEqualToString:identifier]){
            region = find_region;
            return;
        }
    }];
    
    return region;
}
///使用identifier查找区域任务
-(WKRegionActivity*)_findActivityByIdentifier:(NSString*)identifier{
    __block WKRegionActivity *activity = nil;
    [self.activities enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        WKRegionActivity *find_activity = (WKRegionActivity*)obj;
        if ([find_activity.identifier isEqualToString:identifier]){
            activity = find_activity;
            return;
        }
    }];
    return activity;
}
///更新正在监控的区域
-(void)_refreshMonitoringRegions{
    ///output test
    NSLog(@"activities");
    for (WKRegionActivity *activity in self.activities) {
        NSLog(@"%@",activity);
    }
    NSLog(@"monitoring regions");
    for (CLRegion *region in self.locationManager.monitoredRegions.allObjects) {
        NSLog(@"region:%@,%@",region.identifier,[region class]);
    }
    ///
    __weak WKRegionActivities *weak_self = self;
    ///循环任务，更新监控区域
    [self.activities enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        WKRegionActivity *activity = (WKRegionActivity*)obj;
        CLRegion *region = [weak_self _findMonitoringRegionByIdentifier:activity.identifier];
        ///已经存在的区域已经过期，停止监控
        if (activity.isExpired && region){
            [weak_self.locationManager stopMonitoringForRegion:region];
            [activity logString:@"stop region"];
            NSLog(@"stop region:%@,%@",region.identifier,[region class]);
        }
        ///不存在监控，但是有任务
        else if (!activity.isExpired && !region){
            if (activity.isBeaconRegion){
                if (!NSClassFromString(@"CLBeaconRegion")){
                    NSLog(@"CLBeaconRegion is not supported under system of iOS 7.0");
                }
                else{
                    NSUUID *uuid = [[NSUUID alloc]initWithUUIDString:activity.uuid];
                    if (activity.major.length >0 && activity.minor.length > 0){
                        region = [[CLBeaconRegion alloc]initWithProximityUUID:uuid major:[activity.major intValue] minor:[activity.minor intValue] identifier:activity.identifier];
                    }
                    else if (activity.major.length > 0){
                        region = [[CLBeaconRegion alloc]initWithProximityUUID:uuid major:[activity.major intValue] identifier:activity.identifier];
                    }
                    else{
                        region = [[CLBeaconRegion alloc]initWithProximityUUID:uuid identifier:activity.identifier];
                    }
                    region.notifyOnEntry = YES;
                    region.notifyOnExit = YES;
                    CLBeaconRegion *beaconRegion = (CLBeaconRegion*)region;
                    beaconRegion.notifyEntryStateOnDisplay = YES;
                    [weak_self.locationManager startMonitoringForRegion:region];
                    [activity logString:@"start region"];
                    NSLog(@"start region:%@,%@",region.identifier,[region class]);
                }
            }
            else if (activity.isCircularRegion){
                if (!NSClassFromString(@"CLCircularRegion")){
                    NSLog(@"CLCircularRegion is not avaliable under sysytem of iOS 7.0");
                }
                else{
                    region = [[CLCircularRegion alloc]initWithCenter:CLLocationCoordinate2DMake(activity.centerLat, activity.centerLng) radius:activity.centerRadius identifier:activity.identifier];
                    region.notifyOnEntry = YES;
                    region.notifyOnExit = YES;
                    [weak_self.locationManager startMonitoringForRegion:region];
                    [activity logString:@"start region"];
                    NSLog(@"start region:%@,%@",region.identifier,[region class]);
                }
            }
            
        }
        else if (region){
            NSLog(@"running region:%@,%@",region.identifier,NSStringFromClass([region class]));
            [activity logString:@"region is running"];
        }
        else{
            
            
        }
    }];
    ///循环监控区域，查找对应的任务，如果已经过期就删除监控
    [self.locationManager.monitoredRegions.allObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CLRegion *region = (CLRegion*)obj;
        WKRegionActivity *activity = [weak_self _findActivityByIdentifier:region.identifier];
        if (!activity || activity.isExpired){
            [weak_self.locationManager stopMonitoringForRegion:region];
            NSLog(@"stop region:%@,%@",region.identifier,[region class]);
        }
    }];
    [[NSNotificationCenter defaultCenter] postNotificationName:WKRegionActivitiesRefreshRegionsCompleted object:nil]; ///通知刷新
}
///开始位置服务
-(void)startLocationService{
    if (!self.on){
        NSLog(@"WKRegionActivities is off");
        return;
    }
    ///不要反复开始
    if (self.locationManager){
        NSLog(@"location is running");
        return;
    }
    if (!self.locationServiceEnabled){
        NSLog(@"定位服务没有打开");
//        return;
    }
    if (!self.isRangingAvailable){
        NSLog(@"iBeacon 区域不可用,只有 CircularRegion 可用");
    }
    self.locationManager = [[CLLocationManager alloc]init];
    self.locationManager.delegate = self;
    if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]){
        [self.locationManager requestAlwaysAuthorization];
        
    }
//    [self.locationManager startUpdatingLocation];
    if (![self _loadLocalActivities] || self.activitiesExpired){ ///如果本地没有活动任务列表，或者本地列表已经过期，更新一次任务列表
        [self updateActivities];
    }
    else{
        [self _refreshMonitoringRegions];
        
    }
}
///停止所有的区域监控
-(void)stopLocationService{
    for (CLRegion *region in self.locationManager.monitoredRegions.allObjects) {
        [self.locationManager stopMonitoringForRegion:region];
        NSLog(@"stop monitoring region:%@",region.identifier);
    }
    self.locationManager = nil;
}
#pragma mark -  Refresh Beacons
/// 刷新所有区域内的设备
-(void)startRefreshBeacons{
    if (!NSClassFromString(@"CLBeaconRegion")){
        NSLog(@"Refresh CLBeaconRegion is not available under of system of iOS 7.0");
        return;
    }
    if (!self.regionBeacons){
        self.regionBeacons = [[NSMutableDictionary alloc]init];
    }
    [self.regionBeacons removeAllObjects];
    for (CLRegion *region in self.locationManager.monitoredRegions.allObjects) {
        if ([region isKindOfClass:[CLBeaconRegion class]]){
            self.regionBeacons[region.identifier] = @[];
        }
    }
    if (self.onRefreshBeacons){
        self.onRefreshBeacons(self.regionBeacons);
    }
    for (CLRegion *region in self.locationManager.monitoredRegions.allObjects) {
        if ([region isKindOfClass:[CLBeaconRegion class]]){
            [self.locationManager startRangingBeaconsInRegion:(CLBeaconRegion*)region];
        }
    }
}
///停止刷新所有区域内的设备
-(void)stopRefreshBeacons{
    if (!NSClassFromString(@"CLBeaconRegion")){
        NSLog(@"Refresh CLBeaconRegion is not available under of system iOS 7.0");
        return;
    }
    for (CLRegion *region in self.locationManager.monitoredRegions.allObjects) {
        if ([region isKindOfClass:[CLBeaconRegion class]]){
            [self.locationManager stopRangingBeaconsInRegion:(CLBeaconRegion*)region];
        }
    }
}
#pragma mark - CLLocationManagerDelegate
-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status{
    NSLog(@"didChangeAuthorizationStatus:%d",status);
    if (status == kCLAuthorizationStatusNotDetermined){
        if ([manager respondsToSelector:@selector(requestAlwaysAuthorization)]){
            [manager requestAlwaysAuthorization];
        }
    }
}
-(void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region{
    [manager requestStateForRegion:region];
}
-(void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error{
    NSLog(@"monitoringDidFailForRegion,iBeacon 不可用:%@",error);
    
}
-(void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region{
    NSLog(@"didDeterminState:%ld",state);
}
-(void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region{
    WKRegionActivity *activity = [self _findActivityByIdentifier:region.identifier];
    NSLog(@"didEnterRegion:%@,%@",region.identifier,activity.regionName);
    [activity runEnterScripts];
}
-(void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region{
    WKRegionActivity *activity = [self _findActivityByIdentifier:region.identifier];
    NSLog(@"didExitRegion:%@,%@",region.identifier,activity.regionName);
    [activity runExitScripts];
}
-(void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region{
    self.regionBeacons[region.identifier] = beacons;
    if (self.onRefreshBeacons){
        self.onRefreshBeacons(self.regionBeacons);
    }
}
-(void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error{
    NSLog(@"rangingBeaconsDidFailForRegion:%@,%@,%@,%@",region.proximityUUID.UUIDString,region.major,region.minor,region.identifier);
}
@end
