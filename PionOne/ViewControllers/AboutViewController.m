//
//  AboutViewController.m
//  PionOne
//
//  Created by Qxn on 15/10/29.
//  Copyright © 2015年 SeeedStudio. All rights reserved.
//

#import "AboutViewController.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import <FBSDKShareKit/FBSDKShareKit.h>

@interface AboutViewController ()

@end

@implementation AboutViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    FBSDKLoginButton *loginButton = [[FBSDKLoginButton alloc] init];
    CGPoint pst = CGPointMake(self.view.center.x, 150);
    loginButton.center = pst;
    [self.view addSubview:loginButton];

    FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
    content.contentURL = [NSURL URLWithString:@"https://developers.facebook.com"];

    FBSDKLikeControl *button = [[FBSDKLikeControl alloc] init];
    button.objectID = @"https://www.facebook.com/FacebookDevelopers";
    button.center = CGPointMake(self.view.center.x, 200);
    [self.view addSubview:button];

    FBSDKShareButton *button2 = [[FBSDKShareButton alloc] init];
    button2.center = CGPointMake(self.view.center.x, 250);
    button2.shareContent = content;
    [self.view addSubview:button2];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
