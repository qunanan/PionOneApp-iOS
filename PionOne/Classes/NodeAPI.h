//
//  NodeAPI.h
//  PionOne
//
//  Created by Qxn on 15/9/13.
//  Copyright © 2015年 SeeedStudio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Node.h"

@interface NodeAPI : NSObject
@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSArray *args;
@property (nonatomic, strong) NSString *argNameArray;
@property (nonatomic, strong) Node *node;

- (instancetype)initWithNode:(Node *)node andAPIString:(NSString *)str;

- (void)callAPIWhitCompletionHandler:(void (^)(BOOL success))handler;

@end

#import <RETableViewManager/RETableViewManager.h>
@interface NodeAPIArg : NSObject
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *value;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) RETextItem *boundItem;
@end