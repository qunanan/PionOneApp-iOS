//
//  SetupNodeVC.h
//  PionOne
//
//  Created by Qxn on 15/9/10.
//  Copyright (c) 2015年 SeeedStudio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PionOneManager.h"
#import "CoreDataTableViewController.h"

@interface SetupNodeVC : CoreDataTableViewController

@property (nonatomic, strong) Node *node;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;


@end
