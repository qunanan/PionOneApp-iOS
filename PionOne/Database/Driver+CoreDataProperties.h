//
//  Driver+CoreDataProperties.h
//  Pion One
//
//  Created by Qxn on 15/11/13.
//  Copyright © 2015年 SeeedStudio. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Driver.h"

NS_ASSUME_NONNULL_BEGIN

@interface Driver (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *driverID;
@property (nullable, nonatomic, retain) NSString *driverName;
@property (nullable, nonatomic, retain) NSString *groveName;
@property (nullable, nonatomic, retain) NSString *imageURL;
@property (nullable, nonatomic, retain) NSString *interfaceType;
@property (nullable, nonatomic, retain) NSString *skuID;
@property (nullable, nonatomic, retain) NSSet<Grove *> *groves;

@end

@interface Driver (CoreDataGeneratedAccessors)

- (void)addGrovesObject:(Grove *)value;
- (void)removeGrovesObject:(Grove *)value;
- (void)addGroves:(NSSet<Grove *> *)values;
- (void)removeGroves:(NSSet<Grove *> *)values;

@end

NS_ASSUME_NONNULL_END
