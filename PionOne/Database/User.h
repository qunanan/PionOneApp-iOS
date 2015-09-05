//
//  User.h
//  PionOne
//
//  Created by Qxn on 15/9/4.
//  Copyright (c) 2015年 SeeedStudio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Node;

@interface User : NSManagedObject

@property (nonatomic, retain) NSString * token;
@property (nonatomic, retain) NSNumber * userID;
@property (nonatomic, retain) NSSet *nodes;
@end

@interface User (CoreDataGeneratedAccessors)

- (void)addNodesObject:(Node *)value;
- (void)removeNodesObject:(Node *)value;
- (void)addNodes:(NSSet *)values;
- (void)removeNodes:(NSSet *)values;

@end
