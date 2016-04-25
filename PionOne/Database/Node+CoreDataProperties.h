//
//  Node+CoreDataProperties.h
//  Wio Link
//
//  Created by Qxn on 16/4/20.
//  Copyright © 2016年 SeeedStudio. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Node.h"

NS_ASSUME_NONNULL_BEGIN

@interface Node (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *board;
@property (nullable, nonatomic, retain) NSString *dataServerURL;
@property (nullable, nonatomic, retain) NSDate *date;
@property (nullable, nonatomic, retain) NSString *key;
@property (nullable, nonatomic, retain) NSString *macAddress;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSNumber *nodeID;
@property (nullable, nonatomic, retain) NSNumber *online;
@property (nullable, nonatomic, retain) NSString *sn;
@property (nullable, nonatomic, retain) NSSet<Grove *> *groves;
@property (nullable, nonatomic, retain) User *user;

@end

@interface Node (CoreDataGeneratedAccessors)

- (void)addGrovesObject:(Grove *)value;
- (void)removeGrovesObject:(Grove *)value;
- (void)addGroves:(NSSet<Grove *> *)values;
- (void)removeGroves:(NSSet<Grove *> *)values;

@end

NS_ASSUME_NONNULL_END
