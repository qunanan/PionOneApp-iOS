//
//  PionOneManager.m
//  PionOne
//
//  Created by Qxn on 15/9/3.
//  Copyright (c) 2015年 SeeedStudio. All rights reserved.
//

#import "PionOneManager.h"
#import "AFNetworking.h"
#import "NSString+Email.h"
#import "GCDAsyncUdpSocket.h"
#import "NodeAPI.h"


#define PionOneManagerQueueName "PionOneManagerQueueName"

@import SystemConfiguration.CaptiveNetwork;

@interface PionOneManager()
@property (nonatomic, strong) AFHTTPRequestOperationManager *httpManager;
@property (nonatomic, strong) GCDAsyncUdpSocket *udpSocket;
@property (atomic ,assign) __block BOOL canceled;
@property (atomic ,assign) __block BOOL isAPConfigSuccess;
@property (atomic ,assign) __block BOOL foundTheNodeOnServer;
@property (nonatomic, strong) User *userBackground;

@end
@implementation PionOneManager

+ (instancetype)sharedInstance
{
    static PionOneManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[PionOneManager alloc] init];
    });
    return sharedInstance;
}
#pragma -mark Property methods
- (AFHTTPRequestOperationManager *)httpManager {
    if (_httpManager == nil) {
        NSString *urlStr = [[NSUserDefaults standardUserDefaults] stringForKey:kPionOneBaseURL];
        if (urlStr == nil) {
            [[NSUserDefaults standardUserDefaults] setObject:PionOneDefaultBaseURL forKey:kPionOneBaseURL];
            urlStr = PionOneDefaultBaseURL;
        }
        NSURL *baseURL = [NSURL URLWithString:urlStr];
        _httpManager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:baseURL];
        _httpManager.securityPolicy.allowInvalidCertificates = NO;
        _httpManager.responseSerializer = [AFJSONResponseSerializer serializer];
        _httpManager.responseSerializer.acceptableContentTypes = [_httpManager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/html"];
        _httpManager.requestSerializer.timeoutInterval = 30.0f;
    }
    return _httpManager;
}

- (User *)user {
    if (_user == nil) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"User"];
        request.predicate = nil;
        request.sortDescriptors = nil;//@[[[NSSortDescriptor alloc] initWithKey:@"token" ascending:YES selector:@selector(localizedStandardCompare:)]];
        NSArray *result = [self.mainMOC executeFetchRequest:request error:nil];
        _user = [result lastObject];
    }
    return _user;
}
- (User *)userBackground {
    if (_userBackground == nil) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"User"];
        request.predicate = nil;
        request.sortDescriptors = nil;
        NSArray *result = [self.backgroundMOC executeFetchRequest:request error:nil];
        _userBackground = [result lastObject];
    }
    return _userBackground;
}

- (void)setAPConfigurationDone:(BOOL)APConfigurationDone {
    _APConfigurationDone = APConfigurationDone;
    if (_APConfigurationDone) {
        self.tmpNodeSN = nil;
        self.tmpNodeKey = nil;
        self.cachedPassword = nil;
        self.cachedNodeName = nil;
        self.cachedSSID = nil;
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kPionOneTmpNodeSN];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kPionOneTmpNodeKey];
    }
}

- (GCDAsyncUdpSocket *)udpSocket {
    if (_udpSocket == nil) {
        _udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        [_udpSocket enableBroadcast:YES error:nil];
        [self.udpSocket bindToPort:1025 error:nil];
        [self.udpSocket enableBroadcast:YES error:nil];
    }
    return _udpSocket;
}


#pragma -mark User Management API

- (void)signUpWithEmail:(NSString *)email
                 andPwd:(NSString *)pwd
      completionHandler:(void (^)(BOOL succse,NSString *msg))handler
{
    if (![email isEmail]) {
        if (handler) {
            handler(NO,@"Invalid email address.");
        }
        return;
    }
    if (pwd.length < 4) {
        if (handler) {
            handler(NO,@"Password must be at least 4 characters long.");
        }
        return;
    }
    if (!self.mainMOC) {
        NSLog(@"To call the APIs, you need to setManagedObjectContext");
        if (handler) handler(NO,nil);
        return;
    }
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:@[email, pwd] forKeys:@[@"email", @"password"]];
    self.httpManager.requestSerializer.timeoutInterval = 10.0f;
    [self.httpManager POST:aPionOneUserCreate parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSNumber *status = [(NSDictionary *)responseObject objectForKey:@"status"];
        NSString *msg = [(NSDictionary *)responseObject objectForKey:@"msg"];
        if (status.integerValue == 200) {
            self.user = [User userWithInfo:responseObject inManagedObjectContext:self.mainMOC];
            [self saveContext];
            [[NSUserDefaults standardUserDefaults] setObject:self.user.token forKey:kPionOneUserToken];
            if(handler) handler(YES,msg);
        } else {
            if(handler) handler(NO,msg);
        }
        NSLog(@"JSON: %@", responseObject);
    } failure:^(AFHTTPRequestOperation * __nonnull operation, NSError * __nonnull error) {
        if (handler) {
            handler(NO,@"SignUp:Connecting to Server failed!");
        }
        NSLog(@"Networking error: %@", error);
    }];
}

- (void)signInWithEmail:(NSString *)email
                 andPwd:(NSString *)pwd
      completionHandler:(void (^)(BOOL succse,NSString *msg))handler
{
    if (![email isEmail]) {
        if (handler) {
            handler(NO,@"Invalid email address.");
        }
        return;
    }
    if (pwd.length < 4) {
        if (handler) {
            handler(NO,@"Password must be at least 4 characters long.");
        }
        return;
    }

    if (!self.mainMOC) {
        NSLog(@"To call the APIs, you need to setManagedObjectContext");
        if (handler) handler(NO,nil);
        return;
    }
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:@[email, pwd] forKeys:@[@"email", @"password"]];
    self.httpManager.requestSerializer.timeoutInterval = 10.0f;
    [self.httpManager POST:aPionOneUserLogin parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSNumber *status = [(NSDictionary *)responseObject objectForKey:@"status"];
        NSString *msg = [(NSDictionary *)responseObject objectForKey:@"msg"];
        if (status.integerValue == 200) {
            self.user = [User userWithInfo:responseObject inManagedObjectContext:self.mainMOC];
            [self saveContext];
            [[NSUserDefaults standardUserDefaults] setObject:self.user.token forKey:kPionOneUserToken];
            if(handler) handler(YES,msg);
        } else {
            if(handler) handler(NO,msg);
        }
        NSLog(@"JSON: %@", responseObject);
    } failure:^(AFHTTPRequestOperation * __nonnull operation, NSError * __nonnull error) {
        if (handler) {
            handler(NO,@"SignIn:Connecting to Server failed!");
        }
        NSLog(@"Networking error: %@", error);
    }];
}

- (void)logout {
    if (!self.mainMOC) {
        NSLog(@"To call the APIs, you need to setManagedObjectContext");
        return;
    }
    if (!self.user) {
        NSLog(@"It's not logined");
        return;
    }
    [self.mainMOC deleteObject:self.user];
    [self saveContext];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kPionOneUserToken];
}

- (void)retrievePwdForAccount:(NSString *)email completionHandler:(void (^)(BOOL succse, NSString *msg))handler
{
    if (![email isEmail]) {
        if (handler) {
            handler(NO,@"Invalid email address.");
        }
        return;
    }

    if (!self.mainMOC) {
        NSLog(@"To call the APIs, you need to setManagedObjectContext");
        if (handler) handler(NO,nil);
        return;
    }
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:@[email] forKeys:@[@"email"]];
    self.httpManager.requestSerializer.timeoutInterval = 30.0f;
    [self.httpManager POST:aPionOneUserRetrievepassword parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSNumber *status = [(NSDictionary *)responseObject objectForKey:@"status"];
        NSString *msg = [(NSDictionary *)responseObject objectForKey:@"msg"];
        if (status.integerValue == 200) {
            if (handler) handler(YES,msg);
        } else {
            if (handler) handler(NO,msg);
        }
        NSLog(@"JSON: %@", responseObject);
    } failure:^(AFHTTPRequestOperation * __nonnull operation, NSError * __nonnull error) {
        if (handler) {
            handler(NO,@"RetrievePWD:Connecting to Server failed!");
        }
        NSLog(@"Networking error: %@", error);
    }];
}

- (void)changePasswordWithNewPassword:(NSString *)newPwd
                    completionHandler:(void (^)(BOOL succse, NSString *msg))handler
{
    if (!self.mainMOC) {
        NSLog(@"To call the APIs, you need to setManagedObjectContext");
        if (handler) handler(NO,nil);
        return;
    }
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:@[newPwd] forKeys:@[@"password"]];
    self.httpManager.requestSerializer.timeoutInterval = 30.0f;
    [self.httpManager POST:aPionOneUserChangePassword parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSNumber *status = [(NSDictionary *)responseObject objectForKey:@"status"];
        NSString *msg = [(NSDictionary *)responseObject objectForKey:@"msg"];
        if (status.integerValue == 200) {
            NSString *newToken = [(NSDictionary *)responseObject objectForKey:@"token"];
            self.user.token = newToken;
            [self saveContext];
            [[NSUserDefaults standardUserDefaults] setObject:newToken forKey:kPionOneUserToken];
            if (handler) handler(YES,msg);
        } else {
            if (handler) handler(NO,msg);
        }
        NSLog(@"JSON: %@", responseObject);
    } failure:^(AFHTTPRequestOperation * __nonnull operation, NSError * __nonnull error) {
        if (handler) {
            handler(NO,@"ChangePWD:Connecting to Server failed!");
        }
        NSLog(@"Networking error: %@", error);
    }];
}

#pragma -mark Node Management API
- (void)createNodeWithName:(NSString *)name completionHandler:(void (^)(BOOL, NSString *))handler {
    if (!self.user) {
        NSLog(@"To call the APIs, you need to set User.");
        if (handler) handler(NO,nil);
        return;
    }
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:@[self.user.token, name] forKeys:@[@"access_token", @"name"]];
    self.httpManager.requestSerializer.timeoutInterval = 10.0f;
    [self.httpManager POST:aPionOneNodeCreate parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSNumber *status = [(NSDictionary *)responseObject objectForKey:@"status"];
        NSString *msg = [(NSDictionary *)responseObject objectForKey:@"msg"];
        if (status.integerValue == 200) {
            //save the temp node info to UserDefaults for if the app was closed by user,
            //it can be removed when launch the app next time
            self.tmpNodeSN = [(NSDictionary *)responseObject objectForKey:@"node_sn"];
            self.tmpNodeKey = [(NSDictionary *)responseObject objectForKey:@"node_key"];
            [[NSUserDefaults standardUserDefaults] setObject:self.tmpNodeSN forKey:kPionOneTmpNodeSN];
            [[NSUserDefaults standardUserDefaults] setObject:self.tmpNodeKey forKey:kPionOneTmpNodeKey];

            if (handler) handler(YES,msg);
        } else {
            if (handler) handler(NO,msg);
        }
        NSLog(@"JSON: %@", responseObject);
    } failure:^(AFHTTPRequestOperation * __nonnull operation, NSError * __nonnull error) {
        if (handler) {
            handler(NO,@"CreatNode:Connecting to Server failed!");
        }
        NSLog(@"Networking error: %@", error);
    }];
}

- (void)renameNode:(Node *)node withName:(NSString *)name completionHandler:(void (^)(BOOL, NSString *))handler {
    if (!self.user) {
        NSLog(@"To call the APIs, you need to set User.");
        if (handler) handler(NO,nil);
        return;
    }
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:@[self.user.token, node.sn, name] forKeys:@[@"access_token", @"node_sn", @"name"]];
    self.httpManager.requestSerializer.timeoutInterval = 10.0f;
    [self.httpManager POST:aPionOneNodeRename parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSNumber *status = [(NSDictionary *)responseObject objectForKey:@"status"];
        NSString *msg = [(NSDictionary *)responseObject objectForKey:@"msg"];
        if (status.integerValue == 200) {
            node.name = name;
            if (handler) handler(YES,msg);
        } else {
            if (handler) handler(NO,msg);
        }
        NSLog(@"JSON: %@", responseObject);
    } failure:^(AFHTTPRequestOperation * __nonnull operation, NSError * __nonnull error) {
        if (handler) {
            handler(NO,@"CreatNode:Connecting to Server failed!");
        }
        NSLog(@"Networking error: %@", error);
    }];
}

- (void)getNodeListWithCompletionHandler:(void (^)(BOOL, NSString *))handler {
    if (!self.user) {
        NSLog(@"To call the APIs, you need to set User.");
        if (handler) handler(NO,nil);
        return;
    }
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:@[self.user.token] forKeys:@[@"access_token"]];
    self.httpManager.requestSerializer.timeoutInterval = 10.0f;
    [self.httpManager GET:aPionOneNodeList parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSNumber *status = [(NSDictionary *)responseObject objectForKey:@"status"];
        NSString *msg = [(NSDictionary *)responseObject objectForKey:@"msg"];
        if (status.integerValue == 200) {
            NSArray * nodelist = (NSArray *)[(NSDictionary *)responseObject objectForKey:@"nodes"];
            [self.user refreshNodeListWithArry:nodelist];
            if (handler) handler(YES,msg);
        } else {
            if (handler) handler(NO,msg);
        }
        NSLog(@"JSON: %@", responseObject);
    } failure:^(AFHTTPRequestOperation * __nonnull operation, NSError * __nonnull error) {
        if (handler) {
            handler(NO,@"GetNodeList:Connecting to Server failed!");
        }
        NSLog(@"Networking error: %@", error);
    }];
}

- (void)removeNode:(Node *)node completionHandler:(void (^)(BOOL, NSString *))handler {
    if (!self.user) {
        NSLog(@"To call the APIs, you need to set User.");
        if (handler) handler(NO,nil);
        return;
    }
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:@[self.user.token, node.sn] forKeys:@[@"access_token", @"node_sn"]];
    self.httpManager.requestSerializer.timeoutInterval = 10.0f;
    [self.httpManager POST:aPionOneNodeDelete parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSNumber *status = [(NSDictionary *)responseObject objectForKey:@"status"];
        NSString *msg =[(NSDictionary *)responseObject objectForKey:@"msg"];
        if (status.integerValue == 200) {
            [self.mainMOC deleteObject:node];
            if (handler) handler(YES,msg);
        } else {
            if(handler) handler(NO,msg);
        }
        NSLog(@"JSON: %@", responseObject);
    } failure:^(AFHTTPRequestOperation * __nonnull operation, NSError * __nonnull error) {
        if (handler) {
            handler(NO,@"DeleteNode:Connecting to Server failed!");
        }
        NSLog(@"Networking error: %@", error);
    }];

}

#pragma -mark Driver Management API
- (void)scanDriverListWithCompletionHandler:(void (^)(BOOL success, NSString *msg))handler {
    
    if (!self.user) {
        NSLog(@"To call the APIs, you need to set User.");
        if (handler) handler(NO,nil);
        return;
    }
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:@[self.user.token] forKeys:@[@"access_token"]];
    self.httpManager.requestSerializer.timeoutInterval = 30.0f;
    [self.httpManager GET:aPionOneDriverScan parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        for (NSDictionary *dic in (NSArray *)responseObject) {
            Driver *driver = [Driver driverWithInfo:dic inManagedObjectContext:self.mainMOC];
            NSLog(@"%@",driver);
        }
        if(handler) handler(YES,nil);
        NSLog(@"JSON: %@", responseObject);
    } failure:^(AFHTTPRequestOperation * __nonnull operation, NSError * __nonnull error) {
        if (handler) {
            handler(NO,@"ScanDriver:Connecting to Server failed!");
        }
        NSLog(@"Networking error: %@", error);
    }];
}



#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.mainMOC;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

#pragma -mark AP Config Method
// refer to http://stackoverflow.com/questions/5198716/iphone-get-ssid-without-private-library
- (NSDictionary *)fetchSSIDInfo {
    NSArray *ifs = (__bridge_transfer NSArray *)CNCopySupportedInterfaces();
    NSLog(@"Supported interfaces: %@", ifs);
    NSDictionary *info;
    for (NSString *ifnam in ifs) {
        info = (__bridge_transfer NSDictionary *)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        NSLog(@"%@ => %@", ifnam, info);
        if (info && [info count]) { break; }
    }
    return info;
}

- (BOOL)isConnectedToPionOne {
    NSDictionary *nwkInfo = [self fetchSSIDInfo];
    NSString *ssid = nwkInfo[@"SSID"];
    if ([ssid containsString:@"PionOne"]) {
        return YES;
    }
    return NO;
}

- (void)deleteZombieNodeWithCompletionHandler:(void (^)(BOOL, NSString *))handler {
    NSString *zombieNodeSN = [[NSUserDefaults standardUserDefaults] objectForKey:kPionOneTmpNodeSN];
    if (zombieNodeSN == nil) {
        NSLog(@"It's clean, there is no Zombie Node here.");
        if (handler) handler(YES,nil);
        return;
    }
    if (!self.user) {
        NSLog(@"To call the APIs, you need to set User.");
        if (handler) handler(NO,nil);
        return;
    }
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:@[self.user.token, zombieNodeSN] forKeys:@[@"access_token", @"node_sn"]];
    self.httpManager.requestSerializer.timeoutInterval = 30.0f;
    [self.httpManager POST:aPionOneNodeDelete parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSNumber *status = [(NSDictionary *)responseObject objectForKey:@"status"];
        NSString *msg =[(NSDictionary *)responseObject objectForKey:@"msg"];
        if (status.integerValue == 200) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:kPionOneTmpNodeSN];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:kPionOneTmpNodeKey];
            if (handler) handler(YES,msg);
        } else {
            if(handler) handler(NO,msg);
        }
        NSLog(@"JSON: %@", responseObject);
    } failure:^(AFHTTPRequestOperation * __nonnull operation, NSError * __nonnull error) {
        if (handler) {
            handler(NO,@"DeleteZombie:Connecting to Server failed!");
        }
        NSLog(@"Networking error: %@", error);
    }];
}

- (void)cacheCurrentSSID {
    NSDictionary *nwkInfo = [self fetchSSIDInfo];
    self.cachedSSID = nwkInfo[@"SSID"];
    NSLog(@"CachedSSID: %@", self.cachedSSID);
}

- (void)APConfigNodeWithCompletionHandler:(void (^)(BOOL, NSString *))handler {
    if (self.tmpNodeKey == nil || self.tmpNodeSN == nil ||self.cachedSSID == nil || self.cachedPassword == nil) {
        NSString *error = @"Incomplete setup node progress infomation";
        NSLog(@"%@",error);
        if (handler) {
            handler(NO,error);
        }
        return;
    }
    self.isAPConfigSuccess = NO;
    __block BOOL timeout = NO;
    int64_t delay = 30.0; // In seconds
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC);
    dispatch_after(time,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 1), ^{
        timeout = YES;
    });
    dispatch_async(dispatch_queue_create(PionOneManagerQueueName, NULL), ^{
        [self openUdpObserver];
        while (!timeout && !self.canceled && !self.isAPConfigSuccess) {
            [self udpSendPionOneConfiguration];
            [NSThread sleepForTimeInterval:3];
        }
        [self closeUdpObserver];
        dispatch_async(dispatch_get_main_queue(), ^{
            if(self.isAPConfigSuccess == YES) {
                if (handler) {
                    handler(YES,[NSString stringWithFormat:@"setup success!"]);
                }
            } else {
                if (handler) {
                    if (handler && !self.canceled) {
                        handler(NO,@"APConfig:setup canceled or time out!");
                    }
                }
            }
        });
    });
}

- (void)findTheConfiguringNodeFromSeverWithCompletionHandler:(void (^)(BOOL success, NSString *msg))handler {
    self.foundTheNodeOnServer = NO;
    __block BOOL timeout = NO;
    int64_t delay = 60.0; // In seconds
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC);
    dispatch_after(time,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 1), ^{
        timeout = YES;
    });
    NSString *user_token = self.user.token;
    dispatch_async(dispatch_queue_create(PionOneManagerQueueName, NULL), ^{
        while (!timeout && !self.canceled && !self.foundTheNodeOnServer) {
            NSDictionary *parameters = [NSDictionary dictionaryWithObjects:@[user_token] forKeys:@[@"access_token"]];
            [self.httpManager GET:aPionOneNodeList parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSNumber *status = [(NSDictionary *)responseObject objectForKey:@"status"];
                if (status.integerValue == 200) {
                    NSArray * nodelist = (NSArray *)[(NSDictionary *)responseObject objectForKey:@"nodes"];
                    for (NSDictionary *dic in nodelist) {
                        NSString *sn = dic[@"node_sn"];
                        if ([sn isEqualToString:self.tmpNodeSN]) {
                            NSNumber *online = dic[@"online"];
                            if (online.boolValue) {
                                self.foundTheNodeOnServer = YES;
                            }
                        }
                    }
                }
                NSLog(@"JSON: %@", responseObject);
            } failure:^(AFHTTPRequestOperation * __nonnull operation, NSError * __nonnull error) {
                NSLog(@"Networking error: %@", error);
            }];
            [NSThread sleepForTimeInterval:3];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if(self.foundTheNodeOnServer == YES) {
                if (handler) {
                    handler(YES,[NSString stringWithFormat:@"setup success!"]);
                }
            } else {
                if (handler && !self.canceled) {
                    handler(NO,@"FindNodeInServer:setup canceled or time out!");
                }
            }
        });
    });
}

- (void)setNodeName:(NSString *)name withNodeSN:(NSString *)sn completionHandler:(void (^)(BOOL, NSString *))handler {
    if (!self.user) {
        NSLog(@"To call the APIs, you need to set User.");
        if (handler) handler(NO,nil);
        return;
    }
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:@[self.user.token, sn, name] forKeys:@[@"access_token", @"node_sn", @"name"]];
    self.httpManager.requestSerializer.timeoutInterval = 30.0f;
    [self.httpManager POST:aPionOneNodeRename parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSNumber *status = [(NSDictionary *)responseObject objectForKey:@"status"];
        NSString *msg =[(NSDictionary *)responseObject objectForKey:@"msg"];
        if (status.integerValue == 200) {
            if (handler) handler(YES,msg);
        } else {
            if(handler) handler(NO,msg);
        }
        NSLog(@"JSON: %@", responseObject);
    } failure:^(AFHTTPRequestOperation * __nonnull operation, NSError * __nonnull error) {
        if (handler) {
            handler(NO,@"APConfigSetNodeName:Connecting to Server failed!");
        }
        NSLog(@"Networking error: %@", error);
    }];
}

- (void)checkIfConnectedToPionOneWithCompletionHandler:(void (^)(BOOL, NSString *))handler {
    self.canceled = NO;
    __block BOOL timeout = NO;
    int64_t delay = 60.0; // In seconds
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC);
    dispatch_after(time,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 1), ^{
        timeout = YES;
    });
    dispatch_async(dispatch_queue_create(PionOneManagerQueueName, NULL), ^{
        while (!timeout && ![self isConnectedToPionOne] && !self.canceled) {
            [NSThread sleepForTimeInterval:1];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (handler) {
                handler(self.isConnectedToPionOne,nil);
            }
        });
    });
}

- (void)startAPConfigWithProgressHandler:(void (^)(BOOL, NSInteger, NSString *))handler {
    __typeof (&*self) __weak weakSelf = self;

    self.canceled = NO;
    if (self.cachedNodeName && self.cachedPassword) {
        if (handler) {
            handler(YES, 1, nil);
        }
    } else {
        NSLog(@"To Start APConfig, setNodenName and setPassword first!");
        return;
    }
    NSLog(@"APConfig step1:Sending UDP package");
    [weakSelf APConfigNodeWithCompletionHandler:^(BOOL succes, NSString *msg) {
        if (succes) {
            if(handler) {
                handler(YES, 2, msg);
            }
            NSLog(@"APConfig step2:Find Node in Server");
            [weakSelf findTheConfiguringNodeFromSeverWithCompletionHandler:^(BOOL succes, NSString *msg) {
                if (succes) {
                    if(handler) {
                        handler(YES, 3, msg);
                    }
                    NSLog(@"APConfig step3:Set Node Name");
                    [weakSelf setNodeName:self.cachedNodeName withNodeSN:self.tmpNodeSN completionHandler:^(BOOL success, NSString *msg) {
                        if (success) {
                            NSLog(@"APConfig step4:Refresh Node List");
                            [weakSelf getNodeListWithCompletionHandler:^(BOOL succes, NSString *msg) {
                                if (success) {
                                    NSLog(@"APConfig step1:Done");
                                    [weakSelf setAPConfigurationDone:YES];
                                    if (handler) {
                                        handler(YES, 4, msg);
                                    }
                                } else {
                                    handler(NO, 4, msg);
                                }
                            }];
                        } else {
                            handler(NO, 4, msg);
                        }
                    }];
                } else {
                    if (handler) {
                        handler(NO, 3, msg);
                    }
                }
            }];
        } else {
            if (handler) {
                handler(NO, 2, msg);
            }
        }
    }];
}

- (void)longDurationProcessBegin {
    self.canceled = NO;
}

- (void)cancel {
    self.canceled = YES;
    self.cachedPassword = nil;
    self.cachedNodeName = nil;
}


#pragma -mark UDP Methods
- (void)openUdpObserver {
    [self.udpSocket beginReceiving:nil];;
}

- (void)closeUdpObserver {
    [self.udpSocket pauseReceiving];
}
- (void)udpSendPionOneConfiguration {
    NSString *cfg = [NSString stringWithFormat:@"APCFG: %@\t%@\t%@\t%@\t",self.cachedSSID, self.cachedPassword, self.tmpNodeKey, self.tmpNodeSN];
    NSData *cfgData = [cfg dataUsingEncoding:NSUTF8StringEncoding];
    [self.udpSocket sendData:cfgData toHost:PionOneConfigurationAddr port:1025 withTimeout:-1 tag:1025];
}

#pragma mark- AsyncUdpSocketDelegate
-(void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext {
    NSString* str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if ([str containsString:@"ok"]) {
        self.isAPConfigSuccess = YES;
    }
}



#pragma -mark Node Settings Method
- (void)node:(Node *)node startOTAWithprogressHandler:(void (^)(BOOL, NSString *, NSString *, NSString *))handler {
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:@[node.key, [self yamlWithnode:node]] forKeys:@[@"access_token", @"yaml"]];
    self.httpManager.requestSerializer.timeoutInterval = 30.0f;
    [self.httpManager POST:aPionOneUserDownload
            parameters:parameters
               success:^(AFHTTPRequestOperation * __nonnull operation, id  __nonnull responseObject) {
                   NSString *otaMsg =(NSString *)[(NSDictionary *)responseObject objectForKey:@"ota_msg"];
                   NSString *msg =(NSString *)[(NSDictionary *)responseObject objectForKey:@"msg"];
                   NSString *status =(NSString *)[(NSDictionary *)responseObject objectForKey:@"status"];
                   NSString *otaStatus =(NSString *)[(NSDictionary *)responseObject objectForKey:@"ota_status"];
                   if (status.integerValue == 200) {
                       if (handler) {
                           handler(YES,msg,otaMsg,otaStatus);
                           [self node:node OTAStatusWithprogressHandler:handler];
                       }
                   } else {
                       if (handler) {
                           handler(NO,msg,otaStatus,otaStatus);
                       }
                   }
                   NSLog(@"JSON: %@", responseObject);
               }
               failure:^(AFHTTPRequestOperation * __nonnull operation, NSError * __nonnull error) {
                   if (handler) {
                       handler(NO,@"OTA:Connecting to Server failed!",nil,nil);
                   }
                   NSLog(@"Networking error: %@", error);
               }];
}

- (void)node:(Node *)node OTAStatusWithprogressHandler:(void (^)(BOOL, NSString *, NSString *, NSString *))handler {
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:@[node.key] forKeys:@[@"access_token"]];
    self.httpManager.requestSerializer.timeoutInterval = 60.0f;
    [self.httpManager POST:aPionOneOTAStatus
                parameters:parameters
                   success:^(AFHTTPRequestOperation * __nonnull operation, id  __nonnull responseObject) {
                       NSString *otaMsg =(NSString *)[(NSDictionary *)responseObject objectForKey:@"ota_msg"];
                       NSString *msg =(NSString *)[(NSDictionary *)responseObject objectForKey:@"msg"];
                       NSString *status =(NSString *)[(NSDictionary *)responseObject objectForKey:@"status"];
                       NSString *otaStatus =(NSString *)[(NSDictionary *)responseObject objectForKey:@"ota_status"];
                       if (status.integerValue == 200) {
                           if (handler) {
                               handler(YES,msg,otaMsg,otaStatus);
                               if ([otaStatus isEqualToString:@"going"]) {
                                   [self node:node OTAStatusWithprogressHandler:handler];
                               }
                           }
                       } else {
                           if (handler) {
                               handler(NO,msg,otaStatus,otaStatus);
                           }
                       }
                       NSLog(@"JSON: %@", responseObject);
                   }
                   failure:^(AFHTTPRequestOperation * __nonnull operation, NSError * __nonnull error) {
                       if (handler) {
                           handler(NO,@"OTA:Connecting to Server failed!",nil,nil);
                       }
                       NSLog(@"Networking error: %@", error);
                   }];

}

- (void)node:(Node *)node getSettingsWithCompletionHandler:(void (^)(BOOL, NSString *))handler {
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:@[node.key] forKeys:@[@"access_token"]];
    self.httpManager.requestSerializer.timeoutInterval = 50.0f;
    [self.httpManager GET:aPionOneNodeGetSettings
                parameters:parameters
                   success:^(AFHTTPRequestOperation * __nonnull operation, id  __nonnull responseObject) {
                       NSString *msg =(NSString *)[(NSDictionary *)responseObject objectForKey:@"msg"];
                       NSString *status =(NSString *)[(NSDictionary *)responseObject objectForKey:@"status"];
                       if (status.integerValue == 200) {
                           NSArray *array = [self nodeSettingsFromYamlString:msg];
                           [node refreshNodeSettingsWithArray:array];
                       } else {
                           if (handler) {
                               handler(NO,msg);
                           }
                       }
                       NSLog(@"JSON: %@", responseObject);
                   }
                   failure:^(AFHTTPRequestOperation * __nonnull operation, NSError * __nonnull error) {
                       if (handler) {
                           handler(NO,@"GetNodeSettings:Connecting to Server failed!");
                       }
                       NSLog(@"Networking error: %@", error);
                   }];
}

- (NSString *)yamlWithnode:(Node *)node {
    NSString *setting = [[NSString alloc] init];
    for (Grove *grove in node.groves) {
        setting = [setting stringByAppendingString:[self yamlWithGrove:grove]];
    }
    NSLog(@"%@",setting);
    setting = [self toBase64String:setting];
    NSLog(@"%@",setting);
    return setting;
}

- (NSString *)yamlWithGrove:(Grove *)grove {
    NSString *yaml = [NSString stringWithFormat:@"%@:\r\n",grove.instanceName];
    yaml = [yaml stringByAppendingFormat:@"  name: %@\r\n",grove.driver.groveName];
    yaml = [yaml stringByAppendingFormat:@"  construct_arg_list:\r\n"];
    if ([grove.driver.interfaceType isEqualToString:@"GPIO"]) {
        yaml = [yaml stringByAppendingFormat:@"    pin: %@\r\n",grove.pinNum0];
    } else if ([grove.driver.interfaceType isEqualToString:@"I2C"]) {
        yaml = [yaml stringByAppendingFormat:@"    pinsda: %@\r\n",grove.pinNum1];
        yaml = [yaml stringByAppendingFormat:@"    pinscl: %@\r\n",grove.pinNum0];
    } else if ([grove.driver.interfaceType isEqualToString:@"ANALOG"]) {
        yaml = [yaml stringByAppendingFormat:@"    pin: %@\r\n",grove.pinNum0];
    } else {
        NSLog(@"Grove interfaceType error~");
    }
    return yaml;
}
- (NSString *)toBase64String:(NSString *)string {
    NSData *data = [string dataUsingEncoding: NSUTF8StringEncoding];
    
    NSString *ret = [data base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
    
    return ret;
}

///有问题的，还没测试
- (NSString *)fromBase64String:(NSString *)string {
    NSData  *base64Data = [string dataUsingEncoding:NSUnicodeStringEncoding];
    
    NSString* decryptedStr = [[NSString alloc] initWithData:base64Data encoding:NSUnicodeStringEncoding];
    
    return decryptedStr;
}

- (NSString *)interfaceTypeForCntName:(NSString *)cntName {
    if ([cntName isEqualToString:@"Grove0"]) {
        return @"GPIO";
    }
    if ([cntName isEqualToString:@"Grove1"]) {
        return @"GPIO";
    }
    if ([cntName isEqualToString:@"Grove2"]) {
        return @"GPIO";
    }
    if ([cntName isEqualToString:@"Grove3"]) {
        return @"ANALOG";
    }
    if ([cntName isEqualToString:@"Grove4"]) {
        return @"UART";
    }
    if ([cntName isEqualToString:@"Grove5"]) {
        return @"I2C";
    }
    return nil;
}
- (NSArray *)pinNumberWithconnectorName:(NSString *)name {
    if ([name isEqualToString:@"Grove0"]) {
        return @[@"14",@"12"];
    }
    if ([name isEqualToString:@"Grove1"]) {
        return @[@"12",@"13"];
    }
    if ([name isEqualToString:@"Grove2"]) {
        return @[@"13",@"2"];
    }
    if ([name isEqualToString:@"Grove3"]) {
        return @[@"17"];
    }
    if ([name isEqualToString:@"Grove4"]) {
        return @[@"1",@"3"];
    }
    if ([name isEqualToString:@"Grove5"]) {
        return @[@"5",@"4"];
    }
    return nil;
}
- (NSString *)connectoNameForPin:(NSString *)pin {
    switch (pin.integerValue) {
        case 14:
            return @"Grove0";
            break;
        case 12:
            return @"Grove1";
            break;
        case 13:
        case 2:
            return @"Grove2";
            break;
        case 17:
            return @"Grove3";
        case 1:
        case 3:
            return @"Grove4";
        case 5:
        case 4:
            return @"Grove5";
            break;
            
        default:
            break;
    }
    return nil;
}
- (NSArray *)nodeSettingsFromYamlString:(NSString *)yaml {
    NSMutableArray *array = [[NSMutableArray alloc] init];
    NSMutableDictionary *dic = nil;
    NSArray *componets = [yaml componentsSeparatedByString:@"\r\n"];
    BOOL foundNewObject = NO;
    for (NSString *str in componets) {
        NSRange range = [str rangeOfString:@" "];
        if (range.location == NSNotFound) {
            //instanceName object start
            foundNewObject = YES;
            dic = [[NSMutableDictionary alloc] init];
        } else {
            if ([str containsString:@"  name: "]) {
                NSString *name = [str substringFromIndex:8];
                [dic setObject:name forKey:@"name"];
            }
            foundNewObject = NO;
            if ([str containsString:@"    pin: "]) {
                NSString *pin = [str substringFromIndex:9];
                [dic setObject:pin forKey:@"pin"];
                [array addObject:dic.copy];
                dic = nil;
            } else if ([str containsString:@"    pinscl: "]) {
                NSString *pin = [str substringFromIndex:12];
                [dic setObject:pin forKey:@"pin"];
                [array addObject:dic.copy];
                dic = nil;
            }
        }
    }
    return array;
}


#pragma -mark Node API Method
- (void)getAPIsForNode:(Node *)node completion:(void (^)(BOOL, NSString *, NSArray *))handler {
    if (!self.user) {
        NSLog(@"To call the APIs, you need to set User.");
        if (handler) handler(NO,nil,nil);
        return;
    }
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:@[node.key] forKeys:@[@"access_token"]];
    self.httpManager.requestSerializer.timeoutInterval = 30.0f;
    [self.httpManager GET:aPionOneNodeAPIs parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *status =(NSString *)[(NSDictionary *)responseObject objectForKey:@"status"];
        NSString *msg =(NSString *)[(NSDictionary *)responseObject objectForKey:@"msg"];
        if (status.integerValue == 200) {
            NSMutableArray *apis = [[NSMutableArray alloc] init];
            for (NSString *apiStr in (NSArray *)msg) {
                NodeAPI *api =[[NodeAPI alloc] initWithNode:node andAPIString:apiStr];
                if(api) {
                    [apis addObject:api];
                }
            }
            if(handler) handler(YES,nil,apis);
        } else {
            if(handler) handler(NO,msg,nil);
        }
        NSLog(@"JSON: %@", responseObject);
    } failure:^(AFHTTPRequestOperation * __nonnull operation, NSError * __nonnull error) {
        if (handler) {
            handler(NO,@"well-known:Connecting to Server failed!",nil);
        }
        NSLog(@"Networking error: %@", error);
    }];
}


@end
