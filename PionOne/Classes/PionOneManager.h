//
//  PionOneManager.h
//  PionOne
//
//  Created by Qxn on 15/9/3.
//  Copyright (c) 2015年 SeeedStudio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CoreData/CoreData.h"
#import "User+Create.h"
#import "Node+Setup.h"
#import "Driver+Create.h"
#import "Grove.h"

@interface PionOneManager : NSObject
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext; //if you want to call the API, it must not be nil
@property (nonatomic, strong) User *user;
@property (nonatomic, strong) NSString *tmpNodeSN;
@property (nonatomic, strong) NSString *tmpNodeKey;
@property (nonatomic, strong) NSString *cachedSSID;
@property (nonatomic, strong) NSString *cachedPassword;
@property (nonatomic, strong) NSString *cachedNodeName;
@property (nonatomic, assign) BOOL APConfigurationDone;

+ (instancetype)sharedInstance;

#pragma -mark User Management API
- (void)signUpWithEmail:(NSString *)email
                andPwd:(NSString *)pwd
     completionHandler:(void (^)(BOOL success,NSString *msg))handler;
- (void)signInWithEmail:(NSString *)name
                andPwd:(NSString *)pwd
     completionHandler:(void (^)(BOOL success, NSString *msg))handler;
- (void)logout;
- (void)retrievePwdForAccount:(NSString *)email completionHandler:(void (^)(BOOL success, NSString *msg))handler;
- (void)changePasswordWithNewPassword:(NSString *)newPwd completionHandler:(void (^)(BOOL success, NSString *msg))handler;

#pragma -mark Node Management API
- (void)createNodeWithName:(NSString *)name completionHandler:(void (^)(BOOL success, NSString *msg))handler;
- (void)getNodeListWithCompletionHandler:(void (^)(BOOL success, NSString *msg))handler;
- (void)removeNode:(Node *)node completionHandler:(void (^)(BOOL success, NSString *msg))handler;
- (void)renameNode:(Node *)node withName:(NSString *)name completionHandler:(void (^)(BOOL success, NSString *msg))handler;

#pragma -mark Driver Management API
- (void)scanDriverListWithCompletionHandler:(void (^)(BOOL success, NSString *msg))handler;

#pragma -mark AP Config Method
- (BOOL)isConnectedToPionOne;
- (void)deleteZombieNodeWithCompletionHandler:(void (^)(BOOL success, NSString *msg))handler;
- (void)cacheCurrentSSID;
- (void)APConfigNodeWithCompletionHandler:(void (^)(BOOL success, NSString *msg))handler;
- (void)findTheConfiguringNodeFromSeverWithCompletionHandler:(void (^)(BOOL success, NSString *msg))handler;
- (void)setNodeName:(NSString *)name withNodeSN:(NSString *)sn completionHandler:(void (^)(BOOL success, NSString *msg))handler;
- (void)checkIfConnectedToPionOneWithCompletionHandler:(void (^)(BOOL success, NSString *msg))handler;
- (void)startAPConfigWithProgressHandler:(void (^)(BOOL success, NSInteger step, NSString *msg))handler;
- (void)longDurationProcessBegin;
- (void)cancel;

#pragma -mark Node Settings Method
- (void)node:(Node *)node startOTAWithprogressHandler:(void (^)(BOOL success, NSString *msg, NSString *ota_msg, NSString *ota_staus))handler;
@end
