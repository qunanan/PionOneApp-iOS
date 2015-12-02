//
//  PionOneManager.m
//  PionOne
//
//  Created by Qxn on 15/9/3.
//  Copyright (c) 2015年 SeeedStudio. All rights reserved.
//

#import "PionOneManager.h"
#import "NSString+Email.h"
#import "GCDAsyncUdpSocket.h"
#import "NSString+escapedUnicode.h"
#include <netdb.h> 
#include <arpa/inet.h> 

//#define NSLog(format, ...)
#define PionOneManagerQueueName "PionOneManagerQueueName"

@import SystemConfiguration.CaptiveNetwork;

@interface PionOneManager()
@property (nonatomic, strong) GCDAsyncUdpSocket *udpSocket;
@property (atomic, assign) __block BOOL canceled;
@property (atomic, assign) __block BOOL isAPConfigSuccess;
@property (atomic, assign) __block BOOL isGetMacAddressSuccess;
@property (atomic, assign) __block BOOL foundTheNodeOnServer;
@property (atomic, strong) __block NSString *macAddress;


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
        NSString *urlStr = [[NSUserDefaults standardUserDefaults] stringForKey:kPionOneOTAServerBaseURL];
        if (urlStr == nil) {
            // Please Input a Valid Server IP address
            NSLog(@"Please Input a Valid Server IP address..");
        }
        NSURL *baseURL = [NSURL URLWithString:urlStr];
        _httpManager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:baseURL];
        _httpManager.securityPolicy.allowInvalidCertificates = YES;
        _httpManager.securityPolicy.validatesDomainName = NO;
        _httpManager.responseSerializer = [AFJSONResponseSerializer serializer];
        _httpManager.responseSerializer.acceptableContentTypes = [_httpManager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/html"];
        _httpManager.requestSerializer.timeoutInterval = 30.0f;
    }
    return _httpManager;
}

- (User *)user {
    if (_user == nil) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"User"];
        request.predicate = [NSPredicate predicateWithFormat:@"token = %@", [[NSUserDefaults standardUserDefaults] objectForKey:kPionOneUserToken]];
        NSError *error;
        NSArray *matches = [self.mainMOC executeFetchRequest:request error:nil];
        if (!matches || error || ([matches count] > 1)) {
            // handle error
        } else if ([matches count] == 1) {
            _user = [matches firstObject];
        } else {
            //handle error
        }

        _user = [matches lastObject];
    }
    return _user;
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
            handler(NO,@"Password must be at least 4 characters.");
        }
        return;
    }
    if (!self.mainMOC) {
        NSLog(@"To call the APIs, you need to setManagedObjectContext");
        if (handler) handler(NO,nil);
        return;
    }
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:@[email, pwd] forKeys:@[@"email", @"password"]];
    self.httpManager.requestSerializer.timeoutInterval = 20.0f;
    [self.httpManager POST:aPionOneUserCreate parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSNumber *status = [(NSDictionary *)responseObject objectForKey:@"status"];
        NSString *msg = [(NSDictionary *)responseObject objectForKey:@"msg"];
        if (status.integerValue == 200) {
            self.user = [User userWithInfo:responseObject inManagedObjectContext:self.mainMOC];
            //save context
            [self.mainMOC performBlock:^{
                NSError *parentError = nil;
                if (![_mainMOC save:&parentError]) {
                    NSLog(@"Error saving parent");
                }
            }];
            [[NSUserDefaults standardUserDefaults] setObject:self.user.token forKey:kPionOneUserToken];
            [[NSUserDefaults standardUserDefaults] setObject:email forKey:kPionOneUserEmail];
            if(handler) handler(YES,msg);
        } else {
            if(handler) handler(NO,msg);
        }
        NSLog(@"JSON:SignUp: %@", responseObject);
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
    self.httpManager.requestSerializer.timeoutInterval = 20.0f;
    [self.httpManager POST:aPionOneUserLogin parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSNumber *status = [(NSDictionary *)responseObject objectForKey:@"status"];
        NSString *msg = [(NSDictionary *)responseObject objectForKey:@"msg"];
        if (status.integerValue == 200) {
            self.user = [User userWithInfo:responseObject inManagedObjectContext:self.mainMOC];
            //save context
            [self.mainMOC performBlock:^{
                NSError *parentError = nil;
                if (![_mainMOC save:&parentError]) {
                    NSLog(@"Error saving parent");
                }
            }];
            [[NSUserDefaults standardUserDefaults] setObject:self.user.token forKey:kPionOneUserToken];
            [[NSUserDefaults standardUserDefaults] setObject:email forKey:kPionOneUserEmail];
            if(handler) handler(YES,msg);
        } else {
            if(handler) handler(NO,msg);
        }
        NSLog(@"JSON:SignIn: %@", responseObject);
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
//    [self.mainMOC deleteObject:self.user];
    //save context
    [self.mainMOC performBlock:^{
        NSError *parentError = nil;
        if (![_mainMOC save:&parentError]) {
            NSLog(@"Error saving parent");
        }
    }];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kPionOneUserToken];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kPionOneUserEmail];
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
        NSLog(@"JSON:RetrievePWD %@", responseObject);
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
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:@[newPwd, self.user.token] forKeys:@[@"password", @"access_token"]];
    self.httpManager.requestSerializer.timeoutInterval = 20.0f;
    [self.httpManager POST:aPionOneUserChangePassword parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSNumber *status = [(NSDictionary *)responseObject objectForKey:@"status"];
        NSString *msg = [(NSDictionary *)responseObject objectForKey:@"msg"];
        if (status.integerValue == 200) {
            NSString *newToken = [(NSDictionary *)responseObject objectForKey:@"token"];
            self.user.token = newToken;
            //save context
            [self.mainMOC performBlock:^{
                NSError *parentError = nil;
                if (![_mainMOC save:&parentError]) {
                    NSLog(@"Error saving parent");
                }
            }];
            [[NSUserDefaults standardUserDefaults] setObject:newToken forKey:kPionOneUserToken];
            if (handler) handler(YES,msg);
        } else {
            if (handler) handler(NO,msg);
        }
        NSLog(@"JSON:ChangePWD %@", responseObject);
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
    self.httpManager.requestSerializer.timeoutInterval = 20.0f;
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
        NSLog(@"JSON:CreateNode: %@", responseObject);
    } failure:^(AFHTTPRequestOperation * __nonnull operation, NSError * __nonnull error) {
        if (handler) {
            handler(NO,@"CreateNode:Connecting to Server failed!");
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
    self.httpManager.requestSerializer.timeoutInterval = 20.0f;
    [self.httpManager POST:aPionOneNodeRename parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSNumber *status = [(NSDictionary *)responseObject objectForKey:@"status"];
        NSString *msg = [(NSDictionary *)responseObject objectForKey:@"msg"];
        if (status.integerValue == 200) {
            node.name = name;
            if (handler) handler(YES,msg);
        } else {
            if (handler) handler(NO,msg);
        }
        NSLog(@"JSON:renameNode: %@", responseObject);
    } failure:^(AFHTTPRequestOperation * __nonnull operation, NSError * __nonnull error) {
        if (handler) {
            handler(NO,@"renameNode:Connecting to Server failed!");
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
    self.httpManager.requestSerializer.timeoutInterval = 20.0f;
    [self.httpManager GET:aPionOneNodeList parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSNumber *status = [(NSDictionary *)responseObject objectForKey:@"status"];
        NSString *msg = [(NSDictionary *)responseObject objectForKey:@"msg"];
        if (status.integerValue == 200) {
            NSArray * nodelist = (NSArray *)[(NSDictionary *)responseObject objectForKey:@"nodes"];
            NSManagedObjectContext *refreshMOC = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
            refreshMOC.parentContext = self.mainMOC;
            [refreshMOC performBlock:^{
                User *tmpUser = [refreshMOC objectWithID:self.user.objectID];
                [tmpUser refreshNodeListWithArry:nodelist];
            }];
            [self saveChildContext:refreshMOC];
            if (handler) handler(YES,msg);
        } else {
            if (handler) handler(NO,msg);
        }
        NSLog(@"JSON:GetNodeList: %@", responseObject);
    } failure:^(AFHTTPRequestOperation * __nonnull operation, NSError * __nonnull error) {
        if (handler) {
            handler(NO,@"GetNodeList:Connecting to Server failed!");
        }
        NSLog(@"Networking error: %@", error);
    }];
}

- (void)getNodeListAndNodeSettingsWithCompletionHandler:(void (^)(BOOL, NSString *))handler {
    if (!self.user) {
        NSLog(@"To call the APIs, you need to set User.");
        if (handler) handler(NO,nil);
        return;
    }
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:@[self.user.token] forKeys:@[@"access_token"]];
    self.httpManager.requestSerializer.timeoutInterval = 20.0f;
    [self.httpManager GET:aPionOneNodeList parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSNumber *status = [(NSDictionary *)responseObject objectForKey:@"status"];
        NSString *msg = [(NSDictionary *)responseObject objectForKey:@"msg"];
        if (status.integerValue == 200) {
            NSArray * nodelist = (NSArray *)[(NSDictionary *)responseObject objectForKey:@"nodes"];
            NSManagedObjectContext *refreshMOC = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
            refreshMOC.parentContext = self.mainMOC;
            [refreshMOC performBlock:^{
                User *tmpUser = [refreshMOC objectWithID:self.user.objectID];
                [tmpUser refreshNodeListWithArry:nodelist];
                __block NSInteger count = tmpUser.nodes.count;
                if (count == 0) {
                    [self saveChildContext:refreshMOC];
                    if (handler) handler(YES,msg);
                } else {
                    for (Node *tmpNode in tmpUser.nodes) {
                        [self node:tmpNode getSettingsWithCompletionHandler:^(BOOL success, NSString *msg) {
                            if (--count == 0) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [self saveChildContext:refreshMOC];
                                    if (handler) handler(success,msg);
                                });
                            }
                        }];
                    }
                }
            }];
        } else {
            if (handler) handler(NO,msg);
        }
        NSLog(@"JSON:GetNodeList: %@", responseObject);
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
    self.httpManager.requestSerializer.timeoutInterval = 20.0f;
    [self.httpManager POST:aPionOneNodeDelete parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSNumber *status = [(NSDictionary *)responseObject objectForKey:@"status"];
        NSString *msg =[(NSDictionary *)responseObject objectForKey:@"msg"];
        if (status.integerValue == 200) {
            [self.mainMOC deleteObject:node];
            if (handler) handler(YES,msg);
        } else {
            if(handler) handler(NO,msg);
        }
        NSLog(@"JSON:DeleteNode: %@", responseObject);
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
        NSManagedObjectContext *refreshMOC = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        refreshMOC.parentContext = self.mainMOC;

        [refreshMOC performBlock:^{
            [Driver refreshDriverListWithArray:responseObject inManagedObjectContext:refreshMOC];
            //save context
            [self saveChildContext:refreshMOC];
        }];
        if(handler) handler(YES,nil);
        NSLog(@"JSON:ScanDriver: %@", responseObject);
    } failure:^(AFHTTPRequestOperation * __nonnull operation, NSError * __nonnull error) {
        if (handler) {
            handler(NO,@"ScanDriver:Connecting to Server failed!");
        }
        NSLog(@"Networking error: %@", error);
    }];
}



#pragma mark - Core Data Saving support

//- (void)saveContext {
//    NSManagedObjectContext *managedObjectContext = self.mainMOC;
//    if (managedObjectContext != nil) {
//        NSError *error = nil;
//        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
//            // Replace this implementation with code to handle the error appropriately.
//            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
//            abort();
//        }
//    }
//}
- (void)saveChildContext:(NSManagedObjectContext *) childMOC {
    [childMOC performBlock:^{
        NSError *childError = nil;
        if ([childMOC save:&childError]) {
            [_mainMOC performBlock:^{
                NSError *parentError = nil;
                if (![_mainMOC save:&parentError]) {
                    NSLog(@"Error saving parent");
                }
            }];
        } else {
            NSLog(@"Error saving child");
        }
    }];
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
    if ([ssid containsString:@"WioLink"] || [ssid containsString:@"PionOne"]) {
        return YES;
    }
    return NO;
}

- (void)rebootPionOne {
    [self openUdpObserver];
    NSString *cfg = @"REBOOT";
    NSData *cfgData = [cfg dataUsingEncoding:NSUTF8StringEncoding];
    [self.udpSocket sendData:cfgData toHost:PionOneConfigurationAddr port:1025 withTimeout:-1 tag:1025];
    [self closeUdpObserver];
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
    self.httpManager.requestSerializer.timeoutInterval = 10.0f;
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
        NSLog(@"JSON:DeleteZombie: %@", responseObject);
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

- (void)getNodeMacAddressWithCompletionHandler:(void (^)(BOOL success, NSString *msg))handler {
    NSDictionary *nwkInfo = [self fetchSSIDInfo];
    NSString *ssid = nwkInfo[@"SSID"];
    if (![ssid containsString:@"WioLink_"] || ![ssid containsString:@"PionOne_"]) {
        NSString *error = @"This api only works with WioLink configuration network!";
        NSLog(@"%@",error);
        if (handler) {
            handler(NO,error);
        }
        return;
    }
    self.isGetMacAddressSuccess = NO;
    __block BOOL timeout = NO;
    int64_t delay = 10.0; // In seconds
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC);
    dispatch_after(time,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 1), ^{
        timeout = YES;
    });
    dispatch_async(dispatch_queue_create(PionOneManagerQueueName, NULL), ^{
        [self openUdpObserver];
        while (!timeout && !self.canceled && !self.isGetMacAddressSuccess) {
            NSString *cfg = @"Node?";
            NSData *cfgData = [cfg dataUsingEncoding:NSUTF8StringEncoding];
            [self.udpSocket sendData:cfgData toHost:PionOneConfigurationAddr port:1025 withTimeout:-1 tag:1025];
            [NSThread sleepForTimeInterval:3];
        }
        [self closeUdpObserver];
        dispatch_async(dispatch_get_main_queue(), ^{
            if(self.isGetMacAddressSuccess == YES) {
                if (handler) {
                    handler(YES,self.macAddress);
                }
            } else {
                if (handler) {
                    if (handler && !self.canceled) {
                        handler(NO,@"getMacAddress:setup canceled or time out!");
                    }
                }
            }
        });
    });
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
    int64_t delay = 60.0; // In seconds
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
                NSLog(@"JSON:findTheConfiguringNode %@", responseObject);
            } failure:^(AFHTTPRequestOperation * __nonnull operation, NSError * __nonnull error) {
                NSLog(@"Networking error:findTheConfiguringNode %@", error);
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
        NSLog(@"JSON:APConfigSetNodeName: %@", responseObject);
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
    NSString * otaServerIP = [[NSUserDefaults standardUserDefaults] objectForKey:kPionOneOTAServerIPAddress];
    NSString * dataServerIP = [[NSUserDefaults standardUserDefaults] objectForKey:kPionOneDataServerIPAddress];

    NSString *cfg = [NSString stringWithFormat:@"APCFG: %@\t%@\t%@\t%@\t%@\t%@\t",self.cachedSSID, self.cachedPassword, self.tmpNodeKey, self.tmpNodeSN, dataServerIP, otaServerIP];
    NSData *cfgData = [cfg dataUsingEncoding:NSUTF8StringEncoding];
    [self.udpSocket sendData:cfgData toHost:PionOneConfigurationAddr port:1025 withTimeout:-1 tag:1025];
}

#pragma mark- AsyncUdpSocketDelegate
-(void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext {
    NSString* str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if ([str containsString:@"ok"]) {
        self.isAPConfigSuccess = YES;
    } else if ([str containsString:@"Node:"]) {
        self.macAddress = [[str componentsSeparatedByString:@","] objectAtIndex:1];
        self.isGetMacAddressSuccess = YES;
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
                   NSLog(@"JSON:OTA: %@", responseObject);
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
                       NSLog(@"JSON:OTA: %@", responseObject);
                   }
                   failure:^(AFHTTPRequestOperation * __nonnull operation, NSError * __nonnull error) {
                       if (handler) {
                           handler(NO,@"OTA:Connecting to Server failed!",nil,nil);
                       }
                       NSLog(@"Networking error: %@", error);
                   }];

}

- (void)node:(Node *)node getSettingsWithCompletionHandler:(void (^)(BOOL, NSString *))handler {
    NSManagedObjectContext *refreshMOC = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    refreshMOC.parentContext = node.managedObjectContext;
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:@[node.key] forKeys:@[@"access_token"]];
    self.httpManager.requestSerializer.timeoutInterval = 10.0f;
    [self.httpManager GET:aPionOneNodeGetSettings
                parameters:parameters
                   success:^(AFHTTPRequestOperation * __nonnull operation, id  __nonnull responseObject) {
                       NSString *msg =(NSString *)[(NSDictionary *)responseObject objectForKey:@"msg"];
                       NSString *status =(NSString *)[(NSDictionary *)responseObject objectForKey:@"status"];
                       if (status.integerValue == 200) {
                           NSArray *array = [self nodeSettingsFromYamlString:msg];
                           [refreshMOC performBlock:^{
                               Node *tmpNode = [refreshMOC objectWithID:node.objectID];
                               [tmpNode refreshNodeSettingsWithArray:array];
                               NSError *error = nil;
                               if (![refreshMOC save:&error]) {
                                   NSLog(@"Error saving parent");
                               }
                               dispatch_async(dispatch_get_main_queue(), ^{
                                   if (handler) {
                                       handler(YES,msg);
                                   }
                               });
                           }];
                       } else if (status.integerValue == 404) {
                           [refreshMOC performBlock:^{
                               Node *tmpNode = [refreshMOC objectWithID:node.objectID];
                               tmpNode.groves = nil;
                               NSError *error = nil;
                               if (![refreshMOC save:&error]) {
                                   NSLog(@"Error saving parent");
                               }
                               dispatch_async(dispatch_get_main_queue(), ^{
                                   if (handler) {
                                       handler(YES,msg);
                                   }
                               });
                           }];
                       } else {
                           if (handler) {
                               handler(NO,msg);
                           }
                       }
                       NSLog(@"JSON:GetNodeSettings: %@", responseObject);
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
    yaml = [yaml stringByAppendingFormat:@"  name: %@\r\n",grove.driver.groveName.escapedUnicode];
    yaml = [yaml stringByAppendingFormat:@"  SKU: %@\r\n",grove.driver.skuID];
    yaml = [yaml stringByAppendingFormat:@"  construct_arg_list:\r\n"];
    if ([grove.driver.interfaceType isEqualToString:@"GPIO"]) {
        yaml = [yaml stringByAppendingFormat:@"    pin: %@\r\n",grove.pinNum0];
    } else if ([grove.driver.interfaceType isEqualToString:@"I2C"]) {
        yaml = [yaml stringByAppendingFormat:@"    pinsda: %@\r\n",grove.pinNum1];
        yaml = [yaml stringByAppendingFormat:@"    pinscl: %@\r\n",grove.pinNum0];
    } else if ([grove.driver.interfaceType isEqualToString:@"ANALOG"]) {
        yaml = [yaml stringByAppendingFormat:@"    pin: %@\r\n",grove.pinNum0];
    } else if ([grove.driver.interfaceType isEqualToString:@"UART"]){
        yaml = [yaml stringByAppendingFormat:@"    pintx: %@\r\n",grove.pinNum1];
        yaml = [yaml stringByAppendingFormat:@"    pinrx: %@\r\n",grove.pinNum0];
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
    if ([cntName isEqualToString:@"Digital0"]) {
        return @"GPIO";
    }
    if ([cntName isEqualToString:@"Digital1"]) {
        return @"GPIO";
    }
    if ([cntName isEqualToString:@"Digital2"]) {
        return @"GPIO";
    }
    if ([cntName isEqualToString:@"Analog"]) {
        return @"ANALOG";
    }
    if ([cntName isEqualToString:@"UART"]) {
        return @"UART";
    }
    if ([cntName isEqualToString:@"I2C"]) {
        return @"I2C";
    }
    return nil;
}
- (NSArray *)pinNumberWithconnectorName:(NSString *)name {
    if ([name isEqualToString:@"Digital0"]) {
        return @[@"14",@"12"];
    }
    if ([name isEqualToString:@"Digital1"]) {
        return @[@"12",@"13"];
    }
    if ([name isEqualToString:@"Digital2"]) {
        return @[@"13",@"2"];
    }
    if ([name isEqualToString:@"Analog"]) {
        return @[@"17"];
    }
    if ([name isEqualToString:@"UART"]) {
        return @[@"3",@"1"];
    }
    if ([name isEqualToString:@"I2C"]) {
        return @[@"5",@"4"];
    }
    return nil;
}
- (NSString *)connectoNameForPin:(NSString *)pin {
    switch (pin.integerValue) {
        case 14:
            return @"Digital0";
            break;
        case 12:
            return @"Digital1";
            break;
        case 13:
        case 2:
            return @"Digital2";
            break;
        case 17:
            return @"Analog";
        case 1:
        case 3:
            return @"UART";
        case 5:
        case 4:
            return @"I2C";
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
            if ([str containsString:@":"]) {
                dic = [[NSMutableDictionary alloc] init];
                [dic setObject:[str substringToIndex:[str length]-1] forKey:@"instanceName"];
            }
        } else {
            if ([str containsString:@"  name: "]) {
                NSString *name = [[str substringFromIndex:8] nonLossyASCIIString];
                [dic setObject:name forKey:@"name"];
            }
            if ([str containsString:@"  SKU: "]) {
                NSString *skuID = [str substringFromIndex:7];
                [dic setObject:skuID forKey:@"SKU"];
            }
            foundNewObject = NO;
            if ([str containsString:@"    pin: "]) {
                NSString *pin = [str substringFromIndex:9];
                [dic setObject:pin forKey:@"pin"];
                if (dic) {
                    [array addObject:dic.copy];
                    dic = nil;
                }
            } else if ([str containsString:@"    pinscl: "]) {
                NSString *pin = [str substringFromIndex:12];
                [dic setObject:pin forKey:@"pin"];
                if (dic) {
                    [array addObject:dic.copy];
                    dic = nil;
                }
            } else if ([str containsString:@"    pinrx: "]) {
                NSString *pin = [str substringFromIndex:11];
                [dic setObject:pin forKey:@"pin"];
                if (dic) {
                    [array addObject:dic.copy];
                    dic = nil;
                }
            }
        }
    }
    return array;
}

#pragma -mark Node API Method
//- (void)getAPIsForNode:(Node *)node completion:(void (^)(BOOL, NSString *, NSArray *))handler {
//    if (!self.user) {
//        NSLog(@"To call the APIs, you need to set User.");
//        if (handler) handler(NO,nil,nil);
//        return;
//    }
//    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:@[node.key] forKeys:@[@"access_token"]];
//    self.httpManager.requestSerializer.timeoutInterval = 30.0f;
//    [self.httpManager GET:aPionOneNodeAPIs parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
//        NSString *status =(NSString *)[(NSDictionary *)responseObject objectForKey:@"status"];
//        NSString *msg =(NSString *)[(NSDictionary *)responseObject objectForKey:@"msg"];
//        if (status.integerValue == 200) {
//            NSMutableArray *apis = [[NSMutableArray alloc] init];
//            for (NSString *apiStr in (NSArray *)msg) {
//                NodeAPI *api =[[NodeAPI alloc] initWithNode:node andAPIString:apiStr];
//                if(api) {
//                    [apis addObject:api];
//                }
//            }
//            if(handler) handler(YES,nil,apis);
//        } else {
//            if(handler) handler(NO,msg,nil);
//        }
//        NSLog(@"JSON:well-known: %@", responseObject);
//    } failure:^(AFHTTPRequestOperation * __nonnull operation, NSError * __nonnull error) {
//        if (handler) {
//            handler(NO,@"well-known:Connecting to Server failed!",nil);
//        }
//        NSLog(@"Networking error: %@", error);
//    }];
//}

#pragma -mark setup Server IP
- (void)setRegion:(NSString*)region OTAServerIP:(NSString *)otaIP andDataSeverIP:(NSString *)dataIP {
    
    [[NSUserDefaults standardUserDefaults] setValue:region forKey:kPionOneServerRegion];

    if ([region isEqualToString:PionOneRegionNameInternational]) {
        [[NSUserDefaults standardUserDefaults] setValue:[self lookupHostIPAddressForURLString:PionOneDefaultOTAServerHostInternational] forKey:kPionOneOTAServerIPAddress];
        [[NSUserDefaults standardUserDefaults] setValue:[self lookupHostIPAddressForURLString:PionOneDefaultDataServerHostInternational] forKey:kPionOneDataServerIPAddress];
        [[NSUserDefaults standardUserDefaults] setValue:PionOneDefaultOTAServerHostInternational forKey:kPionOneOTAServerHost];
        [[NSUserDefaults standardUserDefaults] setValue:PionOneDefaultDataServerHostInternational forKey:kPionOneDataServerHost];
        NSString *baseURL = [NSString stringWithFormat:@"https://%@",PionOneDefaultOTAServerHostInternational];
        [[NSUserDefaults standardUserDefaults] setValue:baseURL forKey:kPionOneOTAServerBaseURL];
        [[PionOneManager sharedInstance] setHttpManager:nil];
        return;
    }
    if ([region isEqualToString:PionOneRegionNameChina]) {
        [[NSUserDefaults standardUserDefaults] setValue:[self lookupHostIPAddressForURLString:PionOneDefaultOTAServerHostChina] forKey:kPionOneOTAServerIPAddress];
        [[NSUserDefaults standardUserDefaults] setValue:[self lookupHostIPAddressForURLString:PionOneDefaultDataServerHostChina] forKey:kPionOneDataServerIPAddress];
        [[NSUserDefaults standardUserDefaults] setValue:PionOneDefaultOTAServerHostChina forKey:kPionOneOTAServerHost];
        [[NSUserDefaults standardUserDefaults] setValue:PionOneDefaultDataServerHostChina forKey:kPionOneDataServerHost];
        NSString *baseURL = [NSString stringWithFormat:@"https://%@",PionOneDefaultOTAServerHostChina];
        [[NSUserDefaults standardUserDefaults] setValue:baseURL forKey:kPionOneOTAServerBaseURL];
        [[PionOneManager sharedInstance] setHttpManager:nil];
        return;
    }
    
    [[NSUserDefaults standardUserDefaults] setValue:otaIP forKey:kPionOneOTAServerIPAddress];
    [[NSUserDefaults standardUserDefaults] setValue:dataIP forKey:kPionOneDataServerIPAddress];
    [[NSUserDefaults standardUserDefaults] setValue:otaIP forKey:kPionOneOTAServerHost];
    [[NSUserDefaults standardUserDefaults] setValue:dataIP forKey:kPionOneDataServerHost];
    NSString *baseURL = [NSString stringWithFormat:@"https://%@",otaIP];
    [[NSUserDefaults standardUserDefaults] setValue:baseURL forKey:kPionOneOTAServerBaseURL];
    [[PionOneManager sharedInstance] setHttpManager:nil];

}

- (NSString*)lookupHostIPAddressForURLString:(NSString*)str
{
    // Ask the unix subsytem to query the DNS
    struct hostent *remoteHostEnt = gethostbyname([str UTF8String]);
    // Get address info from host entry
    struct in_addr *remoteInAddr = (struct in_addr *) remoteHostEnt->h_addr_list[0];
    // Convert numeric addr to ASCII string
    char *sRemoteInAddr = inet_ntoa(*remoteInAddr);
    // hostIP
    NSString* hostIP = [NSString stringWithUTF8String:sRemoteInAddr];
    return hostIP;
}

@end
