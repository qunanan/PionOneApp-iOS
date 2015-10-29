//
//  MenuVC.h
//  PionOne
//
//  Created by Qxn on 15/9/4.
//  Copyright (c) 2015年 SeeedStudio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RESideMenu.h"


#define kTitle @"Title"
#define kIcon @"Icon"
#define kControllerID @"ControllerID"

@interface MenuVC : UIViewController <RESideMenuDelegate>
@property (nonatomic, strong) RESideMenu *rootViewController;
@end
