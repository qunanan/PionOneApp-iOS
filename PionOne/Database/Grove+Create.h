//
//  Grove+Create.h
//  PionOne
//
//  Created by Qxn on 15/9/10.
//  Copyright (c) 2015年 SeeedStudio. All rights reserved.
//

#import "Grove.h"
#import "Driver.h"

@interface Grove (Create)
+ (Grove *)groveForNode:(Node *)node
             WithDriver:(Driver *)driver
              connector:(NSString *)cntName
       inManagedContext:(NSManagedObjectContext *)context;
@end
