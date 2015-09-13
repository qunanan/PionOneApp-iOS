//
//  Grove+Create.m
//  PionOne
//
//  Created by Qxn on 15/9/10.
//  Copyright (c) 2015年 SeeedStudio. All rights reserved.
//

#import "Grove+Create.h"
#import "PionOneManager.h"

@implementation Grove (Create)

+ (Grove *)groveForNode:(Node *)node WithDriver:(Driver *)driver connector:(NSString *)cntName inManagedContext:(NSManagedObjectContext *)context {
    Grove *grove = nil;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Grove"];
    request.predicate = [NSPredicate predicateWithFormat:@"connectorName = %@ AND node = %@", cntName, node];

    NSError *error;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (!matches || error || ([matches count] > 1)) {
        // handle error
    } else if ([matches count] == 1) {
        grove = [matches firstObject];
    } else {
        grove = [NSEntityDescription insertNewObjectForEntityForName:@"Grove"
                                             inManagedObjectContext:context];
    }

    grove.driver = driver;
    grove.instanceName = [driver.driverName stringByAppendingString:cntName];
    grove.connectorName = cntName;
    NSArray *pins = [[PionOneManager sharedInstance] pinNumberWithconnectorName:cntName];
    grove.pinNum0 = [pins firstObject];
    grove.pinNum1 = [pins lastObject];
    grove.node = node;
    return grove;
}
@end
