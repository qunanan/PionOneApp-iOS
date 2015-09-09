//
//  Grove.h
//  PionOne
//
//  Created by Qxn on 15/9/9.
//  Copyright (c) 2015年 SeeedStudio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Node;

@interface Grove : NSManagedObject

@property (nonatomic, retain) NSString * imageURL;
@property (nonatomic, retain) NSString * interfaceType;
@property (nonatomic, retain) NSString * instanceName;
@property (nonatomic, retain) NSString * pinNum0;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * connectorName;
@property (nonatomic, retain) NSString * pinNum1;
@property (nonatomic, retain) Node *node;

@end
