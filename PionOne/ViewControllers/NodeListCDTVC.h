//
//  NodeListCDTVC.h
//  PionOne
//
//  Created by Qxn on 15/9/3.
//  Copyright (c) 2015年 SeeedStudio. All rights reserved.
//

#import "CoreDataTableViewController.h"
#import "MBProgressHUD.h"

@interface NodeListCDTVC : CoreDataTableViewController
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) MBProgressHUD *HUD;

@end
