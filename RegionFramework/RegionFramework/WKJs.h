//
//  WKJs.h
//  RegionFramework
//
//  Created by 秦 道平 on 14/12/11.
//  Copyright (c) 2014年 秦 道平. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
@interface WKJs : NSObject{
}
@property (nonatomic,retain) JSContext *js;
-(id)initWithJSContext:(JSContext*)js;
+(WKJs*)localJs;
-(JSValue*)evaluateScript:(NSString*)script;
@end
