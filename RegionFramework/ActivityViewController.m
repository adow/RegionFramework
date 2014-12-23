//
//  ActivityViewController.m
//  RegionFramework
//
//  Created by 秦 道平 on 14/12/10.
//  Copyright (c) 2014年 秦 道平. All rights reserved.
//

#import "ActivityViewController.h"

@interface ActivityViewController ()

@end

@implementation ActivityViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.titleLabel.text = self.activity.regionName;
    if (self.activity.isBeaconRegion){
        self.uuidLabel.text = [NSString stringWithFormat:@"%@ (%@,%@)",self.activity.uuid,self.activity.major,self.activity.minor];
    }
    else if (self.activity.isCircularRegion){
        self.uuidLabel.text = [NSString stringWithFormat:@"%.2f,%.2f,%.1f",
                               self.activity.centerLat,self.activity.centerLng,self.activity.centerRadius];
    }
    self.identifierLabel.text = self.activity.identifier;
    [self loadTextView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)loadTextView{
    switch (self.segmentControl.selectedSegmentIndex) {
        case 0:
            self.textView.text = self.activity.enterScripts;
            self.executeButton.hidden = NO;
            break;
        case 1:
            self.textView.text = self.activity.exitScripts;
            self.executeButton.hidden = NO;
            break;
        case 2:
            self.textView.text = self.activity.logContent;
            self.executeButton.hidden = YES;
            break;
        default:
            break;
    }
}
-(IBAction)onSegment:(id)sender{
    [self loadTextView];
}
-(IBAction)onButtonBack:(id)sender{
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}
-(IBAction)onButtonRefresh:(id)sender{
    [self loadTextView];
}
-(IBAction)onButtonExecute:(id)sender{
    if (self.segmentControl.selectedSegmentIndex == 0){
        [self.activity runEnterScripts];
    }
    else if (self.segmentControl.selectedSegmentIndex == 1){
        [self.activity runExitScripts];
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
