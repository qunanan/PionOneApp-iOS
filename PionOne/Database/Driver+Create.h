//
//  Driver+Create.h
//  PionOne
//
//  Created by Qxn on 15/9/4.
//  Copyright (c) 2015年 SeeedStudio. All rights reserved.
//

#import "Driver.h"

#define kJsonDriverName @"ClassName"
#define kJsonGroveName @"GroveName"
#define kJsonDriverID @"ID"
#define kJsonImageURL @"ImageURL"
#define kJsonDriverInterfaceType @"InterfaceType"
#define kJsonDriverSKU @"SKU"

@interface Driver (Create)
+ (Driver *)driverWithInfo:(NSDictionary *)dic inManagedObjectContext:(NSManagedObjectContext *)context;

@end
