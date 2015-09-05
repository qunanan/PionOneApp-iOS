
//
//  MenuVC.m
//  PionOne
//
//  Created by Qxn on 15/9/4.
//  Copyright (c) 2015年 SeeedStudio. All rights reserved.
//

#import "MenuVC.h"
#import "RESideMenu.h"
#import "PionOneManager.h"

@implementation MenuVC

- (IBAction)logout {
    [[PionOneManager sharedInstance] logout];
    UIWindow *window = [[[UIApplication sharedApplication] windows] firstObject];
    [window.rootViewController removeFromParentViewController];
    window.rootViewController = [window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"WelcomeVC"];
}
- (IBAction)showDriverList {
    UITableViewController *controller = (UITableViewController *)self.sideMenuViewController.contentViewController;
    NSArray *controllers = [controller childViewControllers];
    UIViewController *nodeListVC = [controllers firstObject];;
    [nodeListVC performSegueWithIdentifier:@"ShowDriverList" sender:nil];
    [self.sideMenuViewController hideMenuViewController];
}

@end
