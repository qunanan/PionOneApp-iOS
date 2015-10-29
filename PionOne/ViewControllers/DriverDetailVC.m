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
    self.navigationItem.title = self.driver.groveName;
    NSURL *url = [NSURL URLWithString:self.driver.imageURL];
    [self.driverImageView sd_setImageWithURL:url placeholderImage:[UIImage imageNamed:@"About"]];
}
@end
