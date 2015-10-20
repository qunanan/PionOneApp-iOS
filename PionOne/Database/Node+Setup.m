//
//  Node+Setup.m
//  PionOne
//
//  Created by Qxn on 15/9/3.
//  Copyright (c) 2015年 SeeedStudio. All rights reserved.
//

#import "Node+Setup.h"
#import "PionOneManager.h"
#import "Grove+Create.h"
#import "PionOneManager.h"

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
        node.key = nodeDictionary[NODE_KEY];
        NSDate *now = [[NSDate alloc] init];
        node.date = now;        
    }
    node.name = nodeDictionary[NODE_NAME];
    node.online = nodeDictionary[NODE_ONLINE_STATUS];

    return node;
}

- (void)refreshNodeSettingsWithArray:(NSArray *)settingsArray {
    [self removeGroves:self.groves];   //remove all sttings
    for (NSDictionary *settingDic in settingsArray) {
        NSString *groveName = settingDic[@"name"];
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Driver"];
        request.predicate = [NSPredicate predicateWithFormat:@"groveName = %@", groveName];
        NSError *error;
        NSArray *matches = [self.managedObjectContext executeFetchRequest:request error:&error];
        Driver *driver = nil;
        if (!matches || error || ([matches count] > 1 || [matches count] == 0)) {
            // handle error
        } else if ([matches count]) {
            driver = [matches firstObject];
            NSString *connectorName = [[PionOneManager sharedInstance] connectoNameForPin:settingDic[@"pin"]];
            Grove *grove = [Grove groveForNode:self WithDriver:driver connector:connectorName inManagedContext:self.managedObjectContext];
            [self addGrovesObject:grove];
        }
    }
}
    
- (NSString *)apiURL {
    NSString *otaServerAddress = [NSString stringWithFormat:@"https://%@", [[NSUserDefaults standardUserDefaults] objectForKey:kPionOneOTAServerIPAddress]];
    NSString *dataServerIP = [[NSUserDefaults standardUserDefaults] objectForKey:kPionOneDataServerIPAddress];
    return [NSString stringWithFormat:@"%@%@?access_token=%@&data_server=%@", otaServerAddress, aPionOneNodeResources,self.key, dataServerIP];
}

@end
