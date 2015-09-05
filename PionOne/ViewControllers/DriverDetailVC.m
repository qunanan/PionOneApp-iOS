//
//  DriverDetailVC.m
//  PionOne
//
//  Created by Qxn on 15/9/4.
//  Copyright (c) 2015年 SeeedStudio. All rights reserved.
//

#import "DriverDetailVC.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface DriverDetailVC()
@property (weak, nonatomic) IBOutlet UIImageView *driverImageView;

@end

@implementation DriverDetailVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.driverImageView.image = self.driverImage;
}
@end
