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
        node.board = nodeDictionary[NODE_BOARD];
        NSDate *now = [[NSDate alloc] init];
        node.date = now;        
    }
    if ([nodeDictionary[NODE_DATA_SERVER_URL] isKindOfClass:[NSString class]]) {
        node.dataServerURL = nodeDictionary[NODE_DATA_SERVER_URL];
    } else {
        node.dataServerURL = nil;
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
    
    if (!matches || error) {
        // handle error
    } else if ([matches count] > 0) {
        for (Grove *oldGrove in matches) {
            [self removeGrovesObject:oldGrove];
        }
    }
    grove = [NSEntityDescription insertNewObjectForEntityForName:@"Grove"
                                          inManagedObjectContext:self.managedObjectContext];
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
            NSString *connectorName = [self cntNameForPort:settingDic[@"port"]];
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

- (NSDictionary *)configJson {
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
    NSMutableArray *settings = [[NSMutableArray alloc] init];
    [json setValue:self.board forKey:@"board_name"];
    for (Grove *grove in self.groves) {
        NSString *port = [self portNameForGrove:grove];
        NSDictionary *setting = [NSDictionary dictionaryWithObjects:@[grove.driver.skuID, port] forKeys:@[@"sku", @"port"]];
        [settings addObject:setting];
    }
    [json setObject:settings forKey:@"connections"];
    return json;
}

- (NSString *)apiURL {
    NSString *otaServerAddress = [NSString stringWithFormat:@"%@", [[NSUserDefaults standardUserDefaults] objectForKey:kPionOneOTAServerBaseURL]];
    otaServerAddress = [otaServerAddress stringByReplacingOccurrencesOfString:@"https" withString:@"http"];
    NSString *defalutURL = [[NSUserDefaults standardUserDefaults] objectForKey:kPionOneDataServerBaseURL];
    if (self.dataServerURL) {
        defalutURL = [self.dataServerURL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
    } else {
        defalutURL = [defalutURL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
    }
    return [NSString stringWithFormat:@"%@%@?access_token=%@&data_server=%@", otaServerAddress, aPionOneNodeResources,self.key, defalutURL];
}


- (NSString *)portNameForGrove:(Grove *)grove {
    if ([self.board containsString:@"Node"]) { //wio node
        if ([grove.connectorName isEqualToString:@"PORT0"]) {
            if ([grove.driver.interfaceType isEqualToString:@"I2C"]) {
                return  @"I2C0";
            }
            if ([grove.driver.interfaceType isEqualToString:@"GPIO"]) {
                return  @"D0";
            }
            if ([grove.driver.interfaceType isEqualToString:@"UART"]) {
                return  @"UART0";
            }
        }
        if ([grove.connectorName isEqualToString:@"PORT1"]) {
            if ([grove.driver.interfaceType isEqualToString:@"I2C"]) {
                return  @"I2C1";
            }
            if ([grove.driver.interfaceType isEqualToString:@"GPIO"]) {
                return  @"D1";
            }
            if ([grove.driver.interfaceType isEqualToString:@"ANALOG"]) {
                return  @"A0";
            }
        }
    } else { // wio link
        if ([grove.connectorName isEqualToString:@"Digital0"]) {
            return @"D0";
        }
        if ([grove.connectorName isEqualToString:@"Digital1"]) {
            return @"D1";
        }
        if ([grove.connectorName isEqualToString:@"Digital2"]) {
            return @"D2";
        }
        if ([grove.connectorName isEqualToString:@"Analog"]) {
            return @"A0";
        }
        if ([grove.connectorName isEqualToString:@"UART"]) {
            return @"UART0";
        }
        if ([grove.connectorName isEqualToString:@"I2C"]) {
            return @"I2C0";
        }
    }
    return @"";
}

- (NSString *)cntNameForPort:(NSString *)port {
    if ([self.board containsString:@"Node"]) { //wio node
        if ([port isEqualToString:@"I2C0"] ||
            [port isEqualToString:@"D0"] ||
            [port isEqualToString:@"UART0"]) {
            return @"PORT0";
        }
        if ([port isEqualToString:@"I2C1"] ||
            [port isEqualToString:@"D1"] ||
            [port isEqualToString:@"A0"]) {
            return @"PORT1";
        }
    } else {
        //else wio link
        if ([port isEqualToString:@"D0"]) {
            return @"Digital0";
        }
        if ([port isEqualToString:@"D1"]) {
            return @"Digital1";
        }
        if ([port isEqualToString:@"D2"]) {
            return @"Digital2";
        }
        if ([port isEqualToString:@"A0"]) {
            return @"Analog";
        }
        if ([port isEqualToString:@"UART0"]) {
            return @"UART";
        }
        if ([port isEqualToString:@"I2C0"]) {
            return @"I2C";
        }
    }
    return @"";
}

@end
