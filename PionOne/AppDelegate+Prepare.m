//
//  AppDelegate+Prepare.m
//  PionOne
//
//  Created by Qxn on 15/9/3.
//  Copyright (c) 2015年 SeeedStudio. All rights reserved.
//

#import "AppDelegate+Prepare.h"
#import "PionOneUserDefaults.h"

@implementation AppDelegate (Prepare)

- (BOOL)isUserExist {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *userkey = [userDefaults stringForKey:kPionOneUserToken];
    if ([userkey length] > 10) { //the key length must bigger than 10, I diden't check what is the exactly value.
        return YES;
    }
    return NO;
}

- (void)registerAPconfigLocalNotification{
    
    UIUserNotificationType types = UIUserNotificationTypeAlert | UIUserNotificationTypeSound;
    UIUserNotificationSettings *connectToNodeSettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
    
    [[UIApplication sharedApplication] registerUserNotificationSettings:connectToNodeSettings];

}

@end
