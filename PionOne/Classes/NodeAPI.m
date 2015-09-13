//
//  NodeAPI.m
//  PionOne
//
//  Created by Qxn on 15/9/13.
//  Copyright © 2015年 SeeedStudio. All rights reserved.
//

#import "NodeAPI.h"
#import "AFNetworking.h"
#import "PionOneManager.h"

@interface NodeAPI ()
@property (nonatomic, strong) AFHTTPRequestOperationManager *httpManager;
@end
@implementation NodeAPI
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

- (instancetype)initWithNode:(Node *)node andAPIString:(NSString *)str
{
    self = [super init];
    if (self) {
        NSArray *components = nil;
        if ([str containsString:@"GET"]) {
            self.type = @"GET";
            components = [str componentsSeparatedByString:@" -> "];
        } else if ([str containsString:@"POST"]) {
            self.type = @"POST";
            components = [str componentsSeparatedByString:@" <- "];
        } else {
            //Envent here
            return nil;
        }
        NSString *url = [[[components firstObject] componentsSeparatedByString:@" "] lastObject];
        self.url = url;
        NSArray *argList = [[components lastObject] componentsSeparatedByString:@", "];
        NSMutableArray *args = [[NSMutableArray alloc] init];
        for (NSString *argStr in argList) {
            NodeAPIArg *arg = [[NodeAPIArg alloc] init];
            [arg setType:[[argStr componentsSeparatedByString:@" "] firstObject]];
            [arg setName:[[argStr componentsSeparatedByString:@" "] lastObject]];
            [args addObject:arg];
        }
        self.args = args;
        self.node = node;
    }
    return self;
}

- (void)callAPIWhitCompletionHandler:(void (^)(BOOL))handler {
    if ([self.type isEqualToString:@"Event"]) {
        return;
    }
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObjects:@[self.node.key] forKeys:@[@"access_token"]];
////    for (NodeAPIArg *arg in self.args) {
////        [parameters setObject:arg.value forKeyedSubscript:arg.name];
////    }
    self.httpManager.requestSerializer.timeoutInterval = 10.0f;
    NSString *api = self.url;
    if ([self.type isEqualToString:@"POST"]) {
        for (NodeAPIArg *arg in self.args) {
            api = [api stringByAppendingFormat:@"/%@",arg.value];
        }
        api = [api stringByAppendingFormat:@"?access_token=%@",self.node.key];
        [self.httpManager POST:api
                   parameters:nil
                      success:^(AFHTTPRequestOperation * __nonnull operation, id  __nonnull responseObject) {
//                          NSString *msg =(NSString *)[(NSDictionary *)responseObject objectForKey:@"msg"];
                          NSString *status =(NSString *)[(NSDictionary *)responseObject objectForKey:@"status"];
                          if (status.integerValue == 200) {
                              if (handler) {
                                  handler(YES);
                              }
                          } else {
                              if (handler) {
                                  handler(NO);
                              }
                          }
                          NSLog(@"JSON: %@", responseObject);
                      }
                      failure:^(AFHTTPRequestOperation * __nonnull operation, NSError * __nonnull error) {
                          if (handler) {
                              handler(NO);
                          }
                          NSLog(@"Networking error: %@", error);
                      }];
    }
    if ([self.type isEqualToString:@"GET"]) {
        [self.httpManager GET:api
                    parameters:parameters
                       success:^(AFHTTPRequestOperation * __nonnull operation, id  __nonnull responseObject) {
                           NSString *msg =(NSString *)[(NSDictionary *)responseObject objectForKey:@"msg"];
                           NSString *status =(NSString *)[(NSDictionary *)responseObject objectForKey:@"status"];
                           if (status.integerValue == 200) {
                               for (NodeAPIArg *arg in self.args) {
                                   arg.value = [(NSNumber *)[(NSDictionary *)msg valueForKey:arg.name] stringValue];
                               }
                               if (handler) {
                                   handler(YES);
                               }
                           } else {
                               if (handler) {
                                   handler(NO);
                               }
                           }
                           NSLog(@"JSON: %@", responseObject);
                       }
                       failure:^(AFHTTPRequestOperation * __nonnull operation, NSError * __nonnull error) {
                           if (handler) {
                               handler(NO);
                           }
                           NSLog(@"Networking error: %@", error);
                       }];
    }
}

@end


@implementation NodeAPIArg
@synthesize value = _value;
- (void)setValue:(NSString *)value {
    _value = value;
    self.boundItem.value = value;
}

- (NSString *)value {
    if (_boundItem) {
        _value = _boundItem.value;
    }
    return _value;
}

@end