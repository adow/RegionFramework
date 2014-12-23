//
//  BeaconsViewController.m
//  RegionFramework
//
//  Created by 秦 道平 on 14/12/10.
//  Copyright (c) 2014年 秦 道平. All rights reserved.
//

#import "BeaconsViewController.h"
#import <CoreLocation/CoreLocation.h>
#import "WKRegionActivities.h"
@interface BeaconsViewController ()
@property (nonatomic,retain) NSDictionary *regionBeacons;
@end

@implementation BeaconsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    __weak BeaconsViewController *weak_self = self;
    [WKRegionActivities sharedActivities].onRefreshBeacons = ^(NSDictionary *dict){
        weak_self.regionBeacons = dict;
        [weak_self.tableView reloadData];
    };
    [[WKRegionActivities sharedActivities] startRefreshBeacons];
}
-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [[WKRegionActivities sharedActivities] stopRefreshBeacons];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return self.regionBeacons.allKeys.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    NSString *identifier = self.regionBeacons.allKeys[section];
    NSArray *beacons = self.regionBeacons[identifier];
    return beacons.count;
    
}
-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    NSString *identifier = self.regionBeacons.allKeys[section];
    return identifier;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"beacon-cell" forIndexPath:indexPath];
    NSString *identifier = self.regionBeacons.allKeys[indexPath.section];
    NSArray *beacons = self.regionBeacons[identifier];
    CLBeacon *beacon = beacons[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@,%@,%@",beacon.major,beacon.minor,beacon.proximityUUID.UUIDString];
    NSString *position = @"未知";
    switch (beacon.proximity) {
        case CLProximityFar:
            position = @"远";
            break;
        case CLProximityImmediate:
            position = @"旁边";
            break;
        case CLProximityNear:
            position = @"近";
            break;
        case CLProximityUnknown:
            position = @"未知";
            break;
        default:
            break;
    }
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ rssi:%ld, accuracy:%f",position,(long)beacon.rssi,beacon.accuracy];
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
