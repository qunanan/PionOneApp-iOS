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
    if ([nodeDictionary[NODE_DATA_SERVER_IP] isKindOfClass:[NSString class]]) {
        node.dataServerIP = nodeDictionary[NODE_DATA_SERVER_IP];
    } else {
        node.dataServerIP = nil;
    }
    node.name = nodeDictionary[NODE_NAME];
    node.online = nodeDictionary[NODE_ONLINE_STATUS];

    return node;
}
- (void)addNewGroveWithDriver:(Driver *)driver cntName:(NSString *)cntName {
    Grove *grove = nil;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Grove"];
    request.predicate = [NSPredicate predicateWithFormat:@"connectorName = %@ AND node = %@", cntName, self];
    
    NSError *error;
    NSArray *matches = [self.managedObjectContext executeFetchRequest:request error:&error];
    
    if (!matches || error || ([matches count] > 1)) {
        // handle error
    } else if ([matches count] == 1) {
        grove = [matches firstObject];
    } else {
        grove = [NSEntityDescription insertNewObjectForEntityForName:@"Grove"
                                              inManagedObjectContext:self.managedObjectContext];
    }
    grove.driver = driver;
    grove.instanceName = [driver.driverName stringByAppendingString:cntName];
    grove.connectorName = cntName;
    NSArray *pins = [[PionOneManager sharedInstance] pinNumberWithconnectorName:cntName];
    grove.pinNum0 = [pins firstObject];
    grove.pinNum1 = [pins lastObject];
    grove.node = self;
}

- (void)addI2CGrovesWithDrivers:(NSArray *)drivers cntName:(NSString *)cntName{
    Grove *grove = nil;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Grove"];
    request.predicate = [NSPredicate predicateWithFormat:@"connectorName = %@ AND node = %@", cntName, self];
    
    NSError *error;
    NSArray *matches = [self.managedObjectContext executeFetchRequest:request error:&error];
    
    if (!matches || error) {
        // handle error
    } else if ([matches count] > 0) {
        for (Grove *oldGrove in matches) {
            [self removeGrovesObject:oldGrove];
        }
    }
    for (Driver *driver in drivers) {
        grove = [NSEntityDescription insertNewObjectForEntityForName:@"Grove"
                                              inManagedObjectContext:self.managedObjectContext];
        grove.driver = driver;
        grove.instanceName = [NSString stringWithFormat:@"%@%@%lu", driver.driverName, cntName, (unsigned long)[drivers indexOfObject:driver]];
        grove.connectorName = cntName;
        NSArray *pins = [[PionOneManager sharedInstance] pinNumberWithconnectorName:cntName];
        grove.pinNum0 = [pins firstObject];
        grove.pinNum1 = [pins lastObject];
        grove.node = self;
    }
}

- (void)refreshNodeSettingsWithArray:(NSArray *)settingsArray {
    [self removeGroves:self.groves];   //remove all sttings
    for (NSDictionary *settingDic in settingsArray) {
//        NSString *groveName = settingDic[@"name"];
        NSString *sku = settingDic[@"SKU"];
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Driver"];
        request.predicate = [NSPredicate predicateWithFormat:@"skuID = %@", sku];
        NSError *error;
        NSArray *matches = [self.managedObjectContext executeFetchRequest:request error:&error];
        Driver *driver = nil;
        if (!matches || error || ([matches count] > 1 || [matches count] == 0)) {
            // handle error
        } else if ([matches count]) {
            driver = [matches firstObject];
            NSString *connectorName = [[PionOneManager sharedInstance] connectoNameForPin:settingDic[@"pin"]];
            Grove *grove = [NSEntityDescription insertNewObjectForEntityForName:@"Grove"
                                                  inManagedObjectContext:self.managedObjectContext];
            grove.driver = driver;
            grove.instanceName = [settingDic objectForKey:@"instanceName"];
            grove.connectorName = connectorName;
            NSArray *pins = [[PionOneManager sharedInstance] pinNumberWithconnectorName:connectorName];
            grove.pinNum0 = [pins firstObject];
            grove.pinNum1 = [pins lastObject];
            grove.node = self;
        }
    }
}

- (void)refreshNodeSettingsWithJson:(NSDictionary *)json {
    [self removeGroves:self.groves];   //remove all sttings
    NSArray *settings = json[@"connections"];
    for (NSDictionary *settingDic in settings) {
        //        NSString *groveName = settingDic[@"name"];
        NSString *sku = settingDic[@"sku"];
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Driver"];
        request.predicate = [NSPredicate predicateWithFormat:@"skuID = %@", sku];
        NSError *error;
        NSArray *matches = [self.managedObjectContext executeFetchRequest:request error:&error];
        Driver *driver = nil;
        if (!matches || error || ([matches count] > 1 || [matches count] == 0)) {
            // handle error
        } else if ([matches count]) {
            driver = [matches firstObject];
            NSString *connectorName = [[PionOneManager sharedInstance] connectorNameForPort:settingDic[@"port"]];
            Grove *grove = [NSEntityDescription insertNewObjectForEntityForName:@"Grove"
                                                         inManagedObjectContext:self.managedObjectContext];
            grove.driver = driver;
            grove.connectorName = connectorName;
            NSArray *pins = [[PionOneManager sharedInstance] pinNumberWithconnectorName:connectorName];
            grove.pinNum0 = [pins firstObject];
            grove.pinNum1 = [pins lastObject];
            grove.node = self;
        }
    }
}

- (NSString *)apiURL {
    NSString *otaServerAddress = [NSString stringWithFormat:@"%@", [[NSUserDefaults standardUserDefaults] objectForKey:kPionOneOTAServerBaseURL]];
    NSString *dataServerIP = [[NSUserDefaults standardUserDefaults] objectForKey:kPionOneDataServerIPAddress];
    return [NSString stringWithFormat:@"%@%@?access_token=%@&data_server=%@", otaServerAddress, aPionOneNodeResources,self.key, dataServerIP];
}

@end
