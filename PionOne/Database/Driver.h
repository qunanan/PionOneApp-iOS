//
//  Driver.h
//  PionOne
//
//  Created by Qxn on 15/9/4.
//  Copyright (c) 2015年 SeeedStudio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Driver : NSManagedObject

@property (nonatomic, retain) NSString * driverName;
@property (nonatomic, retain) NSString * groveName;
@property (nonatomic, retain) NSNumber * driverID;
@property (nonatomic, retain) NSString * imageURL;
@property (nonatomic, retain) NSString * interfaceType;

@end
