//
//  User+Create.h
//  WiFi IoT Node
//
//  Created by Qxn on 15/8/30.
//  Copyright (c) 2015年 SeeedStudio. All rights reserved.
//

#import "User.h"

@interface User (Create)

+ (User *)userWithInfo:(NSDictionary *)dic inManagedObjectContext:(NSManagedObjectContext *)context;
- (void)refreshNodeListWithArry:(NSArray *)arry;
@end
