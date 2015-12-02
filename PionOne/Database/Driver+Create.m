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
    request.predicate = [NSPredicate predicateWithFormat:@"driverID = %@", driverID];
    
    NSError *error;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (!matches || error || ([matches count] > 1)) {
        // handle error
    } else if ([matches count]) {
        driver = [matches firstObject];
    } else {
        driver = [NSEntityDescription insertNewObjectForEntityForName:@"Driver"
                                             inManagedObjectContext:context];
        
    }
    driver.driverID = driverID;
    driver.groveName = dic[kJsonGroveName];
    driver.driverName = dic[kJsonDriverName];
    driver.imageURL = dic[kJsonImageURL];
    driver.interfaceType = dic[kJsonDriverInterfaceType];
    driver.skuID = dic[kJsonDriverSKU];
    return driver;
}

+ (void)refreshDriverListWithArray:(NSArray *)list inManagedObjectContext:(NSManagedObjectContext *)context {
    NSMutableArray *newDriverList = [[NSMutableArray alloc] init];
    for (NSDictionary *dic in list) {
        [newDriverList addObject:[Driver driverWithInfo:dic inManagedObjectContext:context]];
    }
    
    //remove drivers that are no longer supported.
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Driver"];
    request.predicate = nil;
    NSError *error;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (error || !matches) {
        // handle error
    } else {
        for (Driver *driver in matches) {
            BOOL supported = NO;
            for (Driver *newDriver in newDriverList) {
                if ([newDriver.driverID isEqualToNumber:driver.driverID]) {
                    supported = YES;
                }
            }
            if (!supported) {
                [context deleteObject:driver];
//                NSInteger idid = driver.driverID.integerValue;
                NSLog(@"remove Driver: %@",driver);
            }
        }
    }
}


@end
