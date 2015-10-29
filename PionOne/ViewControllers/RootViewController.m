//
//  RootViewController.m
//  PionOne
//
//  Created by Qxn on 15/9/4.
//  Copyright (c) 2015年 SeeedStudio. All rights reserved.
//

#import "RootViewController.h"
#import "MenuVC.h"

@interface RootViewController() <RESideMenuDelegate>
@end
@implementation RootViewController
- (void)awakeFromNib
{
    self.menuPreferredStatusBarStyle = UIStatusBarStyleDefault;
    self.contentViewShadowColor = [UIColor blackColor];
    self.contentViewShadowOffset = CGSizeMake(4, 1);
    self.contentViewShadowOpacity = 0.6;
    self.contentViewShadowRadius = 4;
    self.contentViewShadowEnabled = YES;
    self.scaleContentView = NO;
    self.contentViewScaleValue = 0.9;
    self.scaleBackgroundImageView = NO;
    self.scaleMenuView = NO;
    self.backgroundImage = nil;
    self.fadeMenuView = NO;
    self.parallaxEnabled = NO;
    self.interactivePopGestureRecognizerEnabled = NO;

    float offset = - ([UIScreen mainScreen].applicationFrame.size.width / 2 - 80);
    self.contentViewInPortraitOffsetCenterX = offset;
    self.panGestureEnabled = YES;
    self.contentViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"contentViewController"];
    MenuVC *menuViewVC = [self.storyboard instantiateViewControllerWithIdentifier:@"MenuViewController"];
    self.leftMenuViewController = menuViewVC;
    menuViewVC.rootViewController = self;
    
//    self.rightMenuViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"rightMenuViewController"];
//    self.backgroundImage = [UIImage imageNamed:@"backImage"];
    self.delegate = self;
}

#pragma mark -
#pragma mark RESideMenu Delegate

- (void)sideMenu:(RESideMenu *)sideMenu willShowMenuViewController:(UIViewController *)menuViewController
{
    NSLog(@"willShowMenuViewController: %@", NSStringFromClass([menuViewController class]));
}

- (void)sideMenu:(RESideMenu *)sideMenu didShowMenuViewController:(UIViewController *)menuViewController
{
    NSLog(@"didShowMenuViewController: %@", NSStringFromClass([menuViewController class]));
}

- (void)sideMenu:(RESideMenu *)sideMenu willHideMenuViewController:(UIViewController *)menuViewController
{
    NSLog(@"willHideMenuViewController: %@", NSStringFromClass([menuViewController class]));
}

- (void)sideMenu:(RESideMenu *)sideMenu didHideMenuViewController:(UIViewController *)menuViewController
{
    NSLog(@"didHideMenuViewController: %@", NSStringFromClass([menuViewController class]));
}


@end
