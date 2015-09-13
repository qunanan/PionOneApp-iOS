//
//  User+Create.m
//  WiFi IoT Node
//
//  Created by Qxn on 15/8/30.
//  Copyright (c) 2015年 SeeedStudio. All rights reserved.
//

#import "User+Create.h"
#import "Node+Setup.h"

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

- (void)refreshNodeListWithArry:(NSArray *)arry {
    //First remove the nodes which are in the local database but not in the server
    NSArray *nodelist = self.nodes.copy;
    for (Node *node in nodelist) {
        BOOL isNodeBeDeletedInServer = YES;
        for (NSDictionary *nodeDic in arry) {
            if ([node.sn isEqualToString:nodeDic[@"node_sn"]]) {
                isNodeBeDeletedInServer = NO;
            }
        }
        if (isNodeBeDeletedInServer) {
            [self removeNodesObject:node];
        }
    }
    //Second add new nodes into local database
    for (NSDictionary *nodeDic in arry) {
        Node *newNode = [Node nodeWithServerInfo:nodeDic inManagedObjectContext:self.managedObjectContext];
        newNode.user = self;
    }
}

@end
