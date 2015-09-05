//
//  Grove.h
//  PionOne
//
//  Created by Qxn on 15/9/4.
//  Copyright (c) 2015年 SeeedStudio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Node;

@interface Grove : NSManagedObject

@property (nonatomic, retain) NSString * imageURL;
@property (nonatomic, retain) NSString * interfaceType;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * pinNum;
@property (nonatomic, retain) Node *node;

@end
