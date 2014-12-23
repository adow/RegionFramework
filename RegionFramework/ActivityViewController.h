//
//  ActivityViewController.h
//  RegionFramework
//
//  Created by 秦 道平 on 14/12/10.
//  Copyright (c) 2014年 秦 道平. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WKRegionActivities.h"
@interface ActivityViewController : UIViewController{
    
}
@property (nonatomic,retain) IBOutlet UISegmentedControl *segmentControl;
@property (nonatomic,retain) IBOutlet UITextView *textView;
@property (nonatomic,retain) IBOutlet UILabel *titleLabel;
@property (nonatomic,retain) IBOutlet UILabel *uuidLabel;
@property (nonatomic,retain) IBOutlet UILabel *identifierLabel;
@property (nonatomic,retain) IBOutlet UIButton *executeButton;
@property (nonatomic,retain) WKRegionActivity *activity;
@end
