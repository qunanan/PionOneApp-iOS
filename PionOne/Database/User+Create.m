//
//  User+Create.m
//  WiFi IoT Node
//
//  Created by Qxn on 15/8/30.
//  Copyright (c) 2015年 SeeedStudio. All rights reserved.
//

#import "User+Create.h"

@implementation User (Create)
+ (User *)userWithInfo:(NSDictionary *)dic inManagedObjectContext:(NSManagedObjectContext *)context {

    User *user = nil;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"User"];
    NSError *error;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (!matches || error || ([matches count] > 1)) {
        // handle error
    } else if ([matches count] == 1) {
        user = [matches firstObject];
    } else {
        user = [NSEntityDescription insertNewObjectForEntityForName:@"User"
                                             inManagedObjectContext:context];
        user.userID = [dic objectForKey:@"user_id"];
        user.token = [dic objectForKey:@"token"];
    }
    return user;
}

@end
