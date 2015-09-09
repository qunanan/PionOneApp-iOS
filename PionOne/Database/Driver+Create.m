//
//  Driver+Create.m
//  PionOne
//
//  Created by Qxn on 15/9/4.
//  Copyright (c) 2015年 SeeedStudio. All rights reserved.
//

#import "Driver+Create.h"

@implementation Driver (Create)
+ (Driver *)driverWithInfo:(NSDictionary *)dic inManagedObjectContext:(NSManagedObjectContext *)context {
    Driver *driver = nil;
    NSNumber *driverID = dic[kJsonDriverID];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Driver"];
    request.predicate = [NSPredicate predicateWithFormat:@"driverID = %i", driverID.integerValue];
    
    NSError *error;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (!matches || error || ([matches count] > 1)) {
        // handle error
    } else if ([matches count]) {
        driver = [matches firstObject];
    } else {
        driver = [NSEntityDescription insertNewObjectForEntityForName:@"Driver"
                                             inManagedObjectContext:context];
        
        driver.driverID = driverID;
        driver.groveName = dic[kJsonGroveName];
        driver.driverName = dic[kJsonDriverName];
        driver.imageURL = dic[kJsonImageURL];
        driver.interfaceType = dic[kJsonDriverInterfaceType];
    }
    
    return driver;
}

@end
