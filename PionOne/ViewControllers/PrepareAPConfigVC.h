//
//  StartAPConfigVC.h
//  PionOne
//
//  Created by Qxn on 15/9/5.
//  Copyright (c) 2015年 SeeedStudio. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PrepareAPConfigVC : UIViewController
@property (nonatomic, strong) NSString *selectedSSID;

- (void)showDialog;
@end
