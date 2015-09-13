//
//  Driver.h
//  PionOne
//
//  Created by Qxn on 15/9/12.
//  Copyright (c) 2015年 SeeedStudio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Grove;

@interface Driver : NSManagedObject

@property (nonatomic, retain) NSNumber * driverID;
@property (nonatomic, retain) NSString * driverName;
@property (nonatomic, retain) NSString * groveName;
@property (nonatomic, retain) NSString * imageURL;
@property (nonatomic, retain) NSString * interfaceType;
@property (nonatomic, retain) NSSet *groves;
@end

@interface Driver (CoreDataGeneratedAccessors)

- (void)addGrovesObject:(Grove *)value;
- (void)removeGrovesObject:(Grove *)value;
- (void)addGroves:(NSSet *)values;
- (void)removeGroves:(NSSet *)values;

@end
