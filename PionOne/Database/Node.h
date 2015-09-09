//
//  Node.h
//  PionOne
//
//  Created by Qxn on 15/9/9.
//  Copyright (c) 2015年 SeeedStudio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Grove, User;

@interface Node : NSManagedObject

@property (nonatomic, retain) NSString * key;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * nodeID;
@property (nonatomic, retain) NSNumber * online;
@property (nonatomic, retain) NSString * sn;
@property (nonatomic, retain) NSSet *groves;
@property (nonatomic, retain) User *user;
@end

@interface Node (CoreDataGeneratedAccessors)

- (void)addGrovesObject:(Grove *)value;
- (void)removeGrovesObject:(Grove *)value;
- (void)addGroves:(NSSet *)values;
- (void)removeGroves:(NSSet *)values;

@end
