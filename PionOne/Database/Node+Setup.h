//
//  Node+Setup.h
//  PionOne
//
//  Created by Qxn on 15/9/3.
//  Copyright (c) 2015年 SeeedStudio. All rights reserved.
//

#import "Node.h"
#import "Driver+Create.h"

#define NODE_SN @"node_sn"
#define NODE_NAME   @"name"
#define NODE_KEY    @"node_key"
#define NODE_ONLINE_STATUS  @"online"
#define NODE_DATA_SERVER_URL @"dataxserver"
#define NODE_BOARD @"board"


@interface Node (Setup)
+ (Node *)nodeWithServerInfo:(NSDictionary *)nodeDictionary
      inManagedObjectContext:(NSManagedObjectContext*)context;
- (void)addNewGroveWithDriver:(Driver *)driver cntName:(NSString *)cntName;
- (void)addI2CGrovesWithDrivers:(NSArray *)drivers cntName:(NSString *)cntName;

- (void)refreshNodeSettingsWithArray:(NSArray *)settingsArray;
- (void)refreshNodeSettingsWithJson:(NSDictionary *)json;

- (NSDictionary *)configJson;

- (NSString *)apiURL;
@end
