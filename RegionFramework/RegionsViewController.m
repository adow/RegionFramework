//
//  RegionsViewController.m
//  RegionFramework
//
//  Created by 秦 道平 on 14/12/10.
//  Copyright (c) 2014年 秦 道平. All rights reserved.
//

#import "RegionsViewController.h"
#import <CoreLocation/CoreLocation.h>
#import "WKRegionActivities.h"
#import "WKJs.h"
#import "RegionsTableViewCell.h"
#import "ActivityViewController.h"
@interface RegionsViewController ()

@end

@implementation RegionsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onNotificationRefreshRegions:) name:WKRegionActivitiesRefreshRegionsCompleted object:nil];
    [[WKRegionActivities sharedActivities] startLocationService];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
-(IBAction)onRefresh:(id)sender{
    [[WKRegionActivities sharedActivities] updateActivities];
}
#pragma mark - Notification
-(void)onNotificationRefreshRegions:(NSNotification*)notification{
    [self.tableView reloadData];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:[WKRegionActivities sharedActivities].lastupdateTime];
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    formatter.timeStyle = NSDateFormatterShortStyle;
    formatter.dateStyle = NSDateFormatterShortStyle;
    self.navigationItem.prompt = [formatter stringFromDate:date];
}
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}
-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if (section == 0){
        return @"Regions";
    }
    else{
        return @"Update";
    }
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if (section == 0){
        return [WKRegionActivities sharedActivities].activities.count;
    }
    else{
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0){
        RegionsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"region-cell" forIndexPath:indexPath];
        WKRegionActivity *activity = [WKRegionActivities sharedActivities].activities[indexPath.row];
        cell.regionNameLabel.text = activity.regionName;
        if (activity.isBeaconRegion){
            cell.identifierLable.text = [NSString stringWithFormat:@"%@ (%@,%@)",activity.identifier,activity.major,activity.minor];
            cell.regionTypeLabel.text = NSStringFromClass([CLBeaconRegion class]);
        }
        else if (activity.isCircularRegion){
            cell.identifierLable.text = [NSString stringWithFormat:@"%@ (%.3f,%.3f,%.1f)",
                                         activity.identifier,
                                         activity.centerLat,activity.centerLng,activity.centerRadius];
            cell.regionTypeLabel.text = NSStringFromClass([CLCircularRegion class]);
        }
        
        return cell;
    }
    else{
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"update-cell"];
        return cell;
    }
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [[WKRegionActivities sharedActivities] updateActivities];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    NSIndexPath *indexPath = self.tableView.indexPathForSelectedRow;
    WKRegionActivity *activity = [WKRegionActivities sharedActivities].activities[indexPath.row];
    ActivityViewController *activityViewController = (ActivityViewController*)segue.destinationViewController;
    activityViewController.activity = activity;
}


@end
