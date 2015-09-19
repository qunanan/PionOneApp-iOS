//
//  NodeListCDTVC.m
//  PionOne
//
//  Created by Qxn on 15/9/3.
//  Copyright (c) 2015年 SeeedStudio. All rights reserved.
//

#import "NodeListCDTVC.h"
#import "Node.h"
#import "PionOneManager.h"
#import "MBProgressHUD.h"
#import "SetupNodeVC.h"
#import "NodeDetailTVC.h"

@interface NodeListCDTVC() <MBProgressHUDDelegate>
@property (nonatomic, strong) MBProgressHUD *HUD;
@end

@implementation NodeListCDTVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.managedObjectContext = [[PionOneManager sharedInstance] mainMOC];
    [[PionOneManager sharedInstance] scanDriverListWithCompletionHandler:nil];

    // A little trick for removing the cell separators
    self.tableView.tableFooterView = [UIView new];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refreshControl];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refresh:nil];
}

- (void)refresh:(UIRefreshControl *)refreshControl {
    [[PionOneManager sharedInstance] deleteZombieNodeWithCompletionHandler:^(BOOL succes, NSString *msg) {
        [[PionOneManager sharedInstance] getNodeListWithCompletionHandler:^(BOOL succes, NSString *msg) {
            [refreshControl endRefreshing];
        }];
    }];
}

#pragma -mark Properyies
- (void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    _managedObjectContext = managedObjectContext;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Node"];
    request.predicate = [NSPredicate predicateWithFormat:@"user = %@", [[PionOneManager sharedInstance] user]];
    request.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"online"
                                                            ascending:NO],
                                [[NSSortDescriptor alloc] initWithKey:@"name"
                                                            ascending:YES
                                                             selector:@selector(localizedStandardCompare:)]];
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:managedObjectContext
                                                                          sectionNameKeyPath:@"online"
                                                                                   cacheName:nil];
}

- (MBProgressHUD *)HUD {
    if (_HUD == nil) {
        _HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
        [self.navigationController.view addSubview:_HUD];
    }
    return _HUD;
}


#pragma -mark TableVew Delegate
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NodeCell" forIndexPath:indexPath];
    Node *node = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = node.name;
    cell.detailTextLabel.text = node.online.boolValue? @"Online":@"Offline";
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Node *node = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [self performSegueWithIdentifier:@"ShowNodeDetail" sender:node];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    Node *node = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [self performSegueWithIdentifier:@"ShowNodeSettings" sender:node];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        Node *node = [self.fetchedResultsController objectAtIndexPath:indexPath];
        [self.HUD show:YES];
        [[PionOneManager sharedInstance] removeNode:node completionHandler:^(BOOL succes, NSString *msg) {
            [self.HUD hide:YES];
        }];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *online = [[[self.fetchedResultsController sections] objectAtIndex:section] name];
    if ([online isEqualToString:@"0"]) {
        return @"Offline";
    }
    return @"Online";
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60.0;
}

#pragma -mark Actions
- (IBAction)addNode:(UIBarButtonItem *)sender {
    [self.HUD show:YES];
    [[PionOneManager sharedInstance] cacheCurrentSSID];
    [[PionOneManager sharedInstance] deleteZombieNodeWithCompletionHandler:^(BOOL succes, NSString *msg) {
        [[PionOneManager sharedInstance] createNodeWithName:@"node000" completionHandler:^(BOOL succes, NSString *msg) {
            [self.HUD hide:YES];
            if (succes) {
                [self performSegueWithIdentifier:@"ShowAPconfigVC" sender:nil];
            } else {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                                    message:msg
                                                                   delegate:nil
                                                          cancelButtonTitle:@"Ok"
                                                          otherButtonTitles:nil];
                [alertView show];
            }
        }];
    }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    id dVC = [segue destinationViewController];
    if ([dVC isKindOfClass:[SetupNodeVC class]]) {
        if ([sender isKindOfClass:[Node class]]) {
            [(SetupNodeVC *)dVC setNode:sender];
            [(SetupNodeVC *)dVC setManagedObjectContext:self.managedObjectContext];
            [[(SetupNodeVC *)dVC navigationController] setTitle:[(Node *)sender name]];
        }
    } else if ([dVC isKindOfClass:[NodeDetailTVC class]]) {
        if ([sender isKindOfClass:[Node class]]) {
            [(NodeDetailTVC *)dVC setNode:sender];
        }
    }
}

@end
