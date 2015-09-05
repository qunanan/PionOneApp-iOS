//
//  Node+Setup.m
//  PionOne
//
//  Created by Qxn on 15/9/3.
//  Copyright (c) 2015年 SeeedStudio. All rights reserved.
//

#import "Node+Setup.h"

@implementation Node (Setup)
+ (Node *)nodeWithServerInfo:(NSDictionary *)nodeDictionary inManagedObjectContext:(NSManagedObjectContext *)context {
    Node *node = nil;
    
    NSString *sn = nodeDictionary[NODE_SN];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Node"];
    request.predicate = [NSPredicate predicateWithFormat:@"sn = %@", sn];
    
    NSError *error;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (!matches || error || ([matches count] > 1)) {
        // handle error
    } else if ([matches count]) {
        node = [matches firstObject];
    } else {
        node = [NSEntityDescription insertNewObjectForEntityForName:@"Node"
                                             inManagedObjectContext:context];
        
        node.sn = sn;
        node.name = nodeDictionary[NODE_NAME];
        node.key = nodeDictionary[NODE_KEY];
        node.online = nodeDictionary[NODE_ONLINE_STATUS];
    }
    
    return node;
}

@end
