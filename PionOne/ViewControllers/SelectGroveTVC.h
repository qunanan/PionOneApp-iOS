//
//  SelectGroveTVC.h
//  PionOne
//
//  Created by Qxn on 15/9/10.
//  Copyright (c) 2015年 SeeedStudio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreDataTableViewController.h"
#import "PionOneManager.h"

@interface SelectGroveTVC : CoreDataTableViewController
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSString *connectorName;
@property (nonatomic, strong) Node *node;
@end
