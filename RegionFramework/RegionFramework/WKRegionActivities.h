//
//  WKRegionActivities.h
//  RegionFramework
//
//  Created by 秦 道平 on 14/12/8.
//  Copyright (c) 2014年 秦 道平. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WKRegionActivity.h"
#define WKRegionActivitiesUpdatePath @"http://check.xiaobenapp.com/static/region.test.json"
#define WKRegionActivitiesRefreshRegionsCompleted @"WKRegionActivitiesRefreshRegionsCompleted"
@interface WKRegionActivities : NSObject{
}
@property (nonatomic,assign) double lastupdateTime;
@property (nonatomic,strong) NSMutableArray *activities;
@property (nonatomic,readonly) NSArray *allMonitoringRegions;
@property (nonatomic,strong) void (^onRefreshBeacons)(NSDictionary *regionBeacons);
@property (nonatomic,readonly) BOOL locationServiceEnabled;
@property (nonatomic,readonly) BOOL isRangingAvailable;
///整个功能有没有打开
@property (nonatomic,assign) BOOL on;
+(instancetype)sharedActivities;
-(void)startLocationService;
-(void)updateActivities;
-(void)updateActivitiesIfExpired;
-(void)startRefreshBeacons;
-(void)stopRefreshBeacons;
@end
