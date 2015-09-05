//
//  PionOneManager.m
//  PionOne
//
//  Created by Qxn on 15/9/3.
//  Copyright (c) 2015年 SeeedStudio. All rights reserved.
//

#import "PionOneManager.h"
#import "AFNetworking.h"
#import "PionOneUserDefaults.h"
#import "NSString+Email.h"
#import "GCDAsyncUdpSocket.h"
@import SystemConfiguration.CaptiveNetwork;

@interface PionOneManager()
@property (nonatomic, strong) AFHTTPRequestOperationManager *httpManager;
@property (nonatomic, strong) GCDAsyncUdpSocket *udpSocket;
@property (atomic ,assign) __block BOOL canceled;
@property (atomic ,assign) __block BOOL isConfigurationSuccess;

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
        NSArray *result = [self.managedObjectContext executeFetchRequest:request error:nil];
        _user = [result lastObject];
    }
    return _user;
}

- (void)setAPConfigurationDone:(BOOL)APConfigurationDone {
    _APConfigurationDone = APConfigurationDone;
    if (_APConfigurationDone) {
        self.tmpNodeSN = nil;
        self.tmpNodeKey = nil;
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

    if (!self.managedObjectContext) {
        NSLog(@"To call the APIs, you need to setManagedObjectContext");
        if (handler) handler(NO,nil);
        return;
    }
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:@[email, pwd] forKeys:@[@"email", @"password"]];
    [self.httpManager POST:aPionOneUserCreate parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSNumber *status = [(NSDictionary *)responseObject objectForKey:@"status"];
        NSString *msg = [(NSDictionary *)responseObject objectForKey:@"msg"];
        if (status.integerValue == 200) {
            self.user = [User userWithInfo:responseObject inManagedObjectContext:self.managedObjectContext];
            [self saveContext];
            [[NSUserDefaults standardUserDefaults] setObject:self.user.token forKey:kPionOneUserToken];
            if(handler) handler(YES,msg);
        } else {
            if(handler) handler(NO,msg);
        }
        NSLog(@"JSON: %@", responseObject);
    } failure:^(AFHTTPRequestOperation * __nonnull operation, NSError * __nonnull error) {
        if (handler) {
            handler(NO,@"Connecting to Server failed!");
        }
        NSLog(@"Networking error: %@", error.helpAnchor);
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

    if (!self.managedObjectContext) {
        NSLog(@"To call the APIs, you need to setManagedObjectContext");
        if (handler) handler(NO,nil);
        return;
    }
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:@[email, pwd] forKeys:@[@"email", @"password"]];
    [self.httpManager POST:aPionOneUserLogin parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSNumber *status = [(NSDictionary *)responseObject objectForKey:@"status"];
        NSString *msg = [(NSDictionary *)responseObject objectForKey:@"msg"];
        if (status.integerValue == 200) {
            self.user = [User userWithInfo:responseObject inManagedObjectContext:self.managedObjectContext];
            [self saveContext];
            [[NSUserDefaults standardUserDefaults] setObject:self.user.token forKey:kPionOneUserToken];
            if(handler) handler(YES,msg);
        } else {
            if(handler) handler(NO,msg);
        }
        NSLog(@"JSON: %@", responseObject);
    } failure:^(AFHTTPRequestOperation * __nonnull operation, NSError * __nonnull error) {
        if (handler) {
            handler(NO,@"Connecting to Server failed!");
        }
        NSLog(@"Networking error: %@", error.helpAnchor);
    }];
}

- (void)logout {
    if (!self.managedObjectContext) {
        NSLog(@"To call the APIs, you need to setManagedObjectContext");
        return;
    }
    if (!self.user) {
        NSLog(@"It's not logined");
        return;
    }
    [self.managedObjectContext deleteObject:self.user];
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

    if (!self.managedObjectContext) {
        NSLog(@"To call the APIs, you need to setManagedObjectContext");
        if (handler) handler(NO,nil);
        return;
    }
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:@[email] forKeys:@[@"email"]];
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
            handler(NO,@"Connecting to Server failed!");
        }
        NSLog(@"Networking error: %@", error.helpAnchor);
    }];
}

- (void)changePasswordWithNewPassword:(NSString *)newPwd
                    completionHandler:(void (^)(BOOL succse, NSString *msg))handler
{
    if (!self.managedObjectContext) {
        NSLog(@"To call the APIs, you need to setManagedObjectContext");
        if (handler) handler(NO,nil);
        return;
    }
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:@[newPwd] forKeys:@[@"password"]];
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
            handler(NO,@"Connecting to Server failed!");
        }
        NSLog(@"Networking error: %@", error.helpAnchor);
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
            handler(NO,@"Connecting to Server failed!");
        }
        NSLog(@"Networking error: %@", error.helpAnchor);
    }];
}

- (void)getNodeListWithCompletionHandler:(void (^)(BOOL, NSString *))handler {
    if (!self.user) {
        NSLog(@"To call the APIs, you need to set User.");
        if (handler) handler(NO,nil);
        return;
    }
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:@[self.user.token] forKeys:@[@"access_token"]];
    [self.httpManager GET:aPionOneNodeList parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSNumber *status = [(NSDictionary *)responseObject objectForKey:@"status"];
        NSString *msg = [(NSDictionary *)responseObject objectForKey:@"msg"];
        if (status.integerValue == 200) {
            NSArray * nodelist = (NSArray *)[(NSDictionary *)responseObject objectForKey:@"nodes"];
            for (NSDictionary *dic in nodelist) {
                Node *node = [Node nodeWithServerInfo:dic inManagedObjectContext:self.managedObjectContext];
                node.user = self.user;
                node.online = (NSNumber *)dic[@"online"];
            }
            [self saveContext];
            if (handler) handler(YES,msg);
        } else {
            if (handler) handler(NO,msg);
        }
        NSLog(@"JSON: %@", responseObject);
    } failure:^(AFHTTPRequestOperation * __nonnull operation, NSError * __nonnull error) {
        if (handler) {
            handler(NO,@"Connecting to Server failed!");
        }
        NSLog(@"Networking error: %@", error.helpAnchor);
    }];
}

- (void)removeNode:(Node *)node completionHandler:(void (^)(BOOL, NSString *))handler {
    if (!self.user) {
        NSLog(@"To call the APIs, you need to set User.");
        if (handler) handler(NO,nil);
        return;
    }
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:@[self.user.token, node.sn] forKeys:@[@"access_token", @"node_sn"]];
    [self.httpManager POST:aPionOneNodeDelete parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSNumber *status = [(NSDictionary *)responseObject objectForKey:@"status"];
        NSString *msg =[(NSDictionary *)responseObject objectForKey:@"msg"];
        if (status.integerValue == 200) {
            [self.managedObjectContext deleteObject:node];
            [self saveContext];
            if (handler) handler(YES,msg);
        } else {
            if(handler) handler(NO,msg);
        }
        NSLog(@"JSON: %@", responseObject);
    } failure:^(AFHTTPRequestOperation * __nonnull operation, NSError * __nonnull error) {
        if (handler) {
            handler(NO,@"Connecting to Server failed!");
        }
        NSLog(@"Networking error: %@", error.helpAnchor);
    }];

}

#pragma -mark Driver Management API
- (void)scanDriverListWithCompletionHandler:(void (^)(BOOL succes, NSString *msg))handler {
    
    if (!self.user) {
        NSLog(@"To call the APIs, you need to set User.");
        if (handler) handler(NO,nil);
        return;
    }
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:@[self.user.token] forKeys:@[@"access_token"]];
    [self.httpManager GET:aPionOneDriverScan parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        for (NSDictionary *dic in (NSArray *)responseObject) {
            Driver *driver = [Driver driverWithInfo:dic inManagedObjectContext:self.managedObjectContext];
            NSLog(@"%@",driver);
        }
        [self saveContext];
        if(handler) handler(YES,nil);
        NSLog(@"JSON: %@", responseObject);
    } failure:^(AFHTTPRequestOperation * __nonnull operation, NSError * __nonnull error) {
        if (handler) {
            handler(NO,@"Connecting to Server failed!");
        }
        NSLog(@"Networking error: %@", error.helpAnchor);
    }];
}



#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
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
            handler(NO,@"Connecting to Server failed!");
        }
        NSLog(@"Networking error: %@", error.helpAnchor);
    }];
}

- (void)cacheCurrentSSID {
    NSDictionary *nwkInfo = [self fetchSSIDInfo];
    self.cachedSSID = nwkInfo[@"SSID"];
    NSLog(@"CachedSSID: %@", self.cachedSSID);
}

- (void)setupNodeNodeWithCompletionHandler:(void (^)(BOOL, NSString *))handler {
    if (self.tmpNodeKey == nil || self.tmpNodeSN == nil ||self.cachedSSID == nil || self.cachedPassword == nil) {
        NSString *error = @"Incomplete setup node progress infomation";
        NSLog(@"%@",error);
        if (handler) {
            handler(NO,error);
        }
        return;
    }
    self.isConfigurationSuccess = NO;
    self.canceled = NO;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self openUdpObserver];
        int64_t delay = 30.0; // In seconds
        dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC);
        dispatch_after(time,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 1), ^{
            self.canceled = YES;
        });
        while (!self.canceled && !self.isConfigurationSuccess) {
            [self udpSendPionOneConfiguration];
            [NSThread sleepForTimeInterval:3];
        }
        [self closeUdpObserver];
        dispatch_async(dispatch_get_main_queue(), ^{
            if(self.isConfigurationSuccess == YES) {
                if (handler) {
                    handler(YES,[NSString stringWithFormat:@"setup success!"]);
                }
            } else {
                if (handler) {
                    handler(NO,@"setup canceled or time out!");
                }
            }
        });
    });
}

- (void)findTheConfiguringNodeFromSeverWithCompletionHandler:(void (^)(BOOL succes, NSString *msg))handler {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        self.canceled = NO;
        self.isConfigurationSuccess = NO;
        int64_t delay = 60.0; // In seconds
        dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC);
        dispatch_after(time,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 1), ^{
            self.canceled = YES;
        });
        while (!self.canceled && !self.isConfigurationSuccess) {
            NSDictionary *parameters = [NSDictionary dictionaryWithObjects:@[self.user.token] forKeys:@[@"access_token"]];
            [self.httpManager GET:aPionOneNodeList parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSNumber *status = [(NSDictionary *)responseObject objectForKey:@"status"];
                if (status.integerValue == 200) {
                    NSArray * nodelist = (NSArray *)[(NSDictionary *)responseObject objectForKey:@"nodes"];
                    for (NSDictionary *dic in nodelist) {
                        NSString *sn = dic[@"node_sn"];
                        if ([sn isEqualToString:self.tmpNodeSN]) {
                            NSNumber *online = dic[@"online"];
                            if (online.boolValue) {
                                self.isConfigurationSuccess = YES;
                            }
                        }
                    }
                }
                NSLog(@"JSON: %@", responseObject);
            } failure:^(AFHTTPRequestOperation * __nonnull operation, NSError * __nonnull error) {
                NSLog(@"Networking error: %@", error.helpAnchor);
            }];
            [NSThread sleepForTimeInterval:3];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if(self.isConfigurationSuccess == YES) {
                if (handler) {
                    handler(YES,[NSString stringWithFormat:@"setup success!"]);
                }
            } else {
                if (handler) {
                    handler(NO,@"setup canceled or time out!");
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
            handler(NO,@"Connecting to Server failed!");
        }
        NSLog(@"Networking error: %@", error.helpAnchor);
    }];
}

- (void)cancel {
    self.canceled = YES;
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
        self.isConfigurationSuccess = YES;
        self.canceled = YES;
    }
}

@end
