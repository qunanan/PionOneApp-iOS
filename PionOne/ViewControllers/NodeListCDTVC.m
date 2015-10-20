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
#import "NodeListCell.h"
#import "MGSwipeButton.h"
#import "MGSwipeTableCell.h"


@interface NodeListCDTVC() <MBProgressHUDDelegate, MGSwipeTableCellDelegate>
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
    [self refresh:nil];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)refresh:(UIRefreshControl *)refreshControl {
    [[PionOneManager sharedInstance] deleteZombieNodeWithCompletionHandler:^(BOOL succes, NSString *msg) {
        [[PionOneManager sharedInstance] getNodeListWithCompletionHandler:^(BOOL succes, NSString *msg) {
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Node"];
            
            NSError *error;
            NSArray *matches = [self.managedObjectContext executeFetchRequest:request error:&error];
            
            for (Node *node in matches) {
                NSLog(@"node name:%@",node.name);
                [[PionOneManager sharedInstance] node:node getSettingsWithCompletionHandler:nil];
            }
            [refreshControl endRefreshing];
        }];
    }];
    if(refreshControl) {
        [[PionOneManager sharedInstance] saveContext];
    }
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
                                                                          sectionNameKeyPath:nil //@"online"
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
    NodeListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PionOneCell" forIndexPath:indexPath];
    Node *node = [self.fetchedResultsController objectAtIndexPath:indexPath];
    //setup swipe cell delegate
    cell.delegate = self;
    
    
    //setup cell properties
    cell.nameLabel.text = node.name;
    if (node.online.boolValue) {
        [cell.onlineIndicator setBackgroundColor:[UIColor greenColor]];
    } else {
        [cell.onlineIndicator setBackgroundColor:[UIColor redColor]];
    }
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"connectorName" ascending:YES];
    cell.groves = [node.groves sortedArrayUsingDescriptors:@[descriptor]];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.timeStyle = NSDateFormatterNoStyle;
    formatter.dateStyle = NSDateFormatterMediumStyle;
    cell.timeLabel.text = [formatter stringFromDate:node.date];
    return cell;
}

- (NSArray *)swipeTableCell:(NodeListCell *)cell swipeButtonsForDirection:(MGSwipeDirection)direction swipeSettings:(MGSwipeSettings *)swipeSettings expansionSettings:(MGSwipeExpansionSettings *)expansionSettings {
    
    
    swipeSettings.transition = MGSwipeTransitionStatic;
    if (direction == MGSwipeDirectionLeftToRight) {
        expansionSettings.buttonIndex = 0;
        expansionSettings.fillOnTrigger = NO;
        NSIndexPath * path = [self.tableView indexPathForCell:cell];
        Node *node = [self.fetchedResultsController objectAtIndexPath:path];
        UIColor *buttonColor = node.online.boolValue? [UIColor greenColor] : [UIColor redColor];
        return [self createLeftButtons:3 withColor:buttonColor];
    } else {
        return nil;
    }
}

- (BOOL)swipeTableCell:(MGSwipeTableCell *)cell tappedButtonAtIndex:(NSInteger)index direction:(MGSwipeDirection)direction fromExpansion:(BOOL)fromExpansion {
    NSLog(@"Delegate: button tapped, %@ position, index %d, from Expansion: %@",
          direction == MGSwipeDirectionLeftToRight ? @"left" : @"right", (int)index, fromExpansion ? @"YES" : @"NO");
    NSIndexPath * path = [self.tableView indexPathForCell:cell];
    Node *node = [self.fetchedResultsController objectAtIndexPath:path];

    if (direction == MGSwipeDirectionLeftToRight && index == 0) {
        [self performSegueWithIdentifier:@"ShowNodeDetail" sender:node];
    }
    if (direction == MGSwipeDirectionLeftToRight && index == 2) {
        //delete button
        [self.HUD show:YES];
        [[PionOneManager sharedInstance] removeNode:node completionHandler:^(BOOL succes, NSString *msg) {
            [self.HUD hide:YES];
        }];
        return NO; //Don't autohide to improve delete expansion animation
    }
    
    return YES;

}

-(NSArray *) createLeftButtons: (int) number withColor:(UIColor *)color
{
    NSMutableArray * result = [NSMutableArray array];
    UIColor * colors[3] = {color,color,color};
//    {[UIColor greenColor],
//        [UIColor colorWithRed:0 green:0x99/255.0 blue:0xcc/255.0 alpha:1.0],
//        [UIColor redColor]};
//    UIImage * icons[3] = {[UIImage imageNamed:@"check.png"], [UIImage imageNamed:@"fav.png"], [UIImage imageNamed:@"menu.png"]};
    NSString* titles[3] = {@"Detail", @"Rename", @"Delete"};
    for (int i = 0; i < number; ++i)
    {
//        MGSwipeButton * button = [MGSwipeButton buttonWithTitle:@"" icon:icons[i] backgroundColor:colors[i] padding:15 callback:^BOOL(MGSwipeTableCell * sender){
//            NSLog(@"Convenience callback received (left).");
//            return YES;
//        }];
        MGSwipeButton * button = [MGSwipeButton buttonWithTitle:titles[i] backgroundColor:colors[i] callback:^BOOL(MGSwipeTableCell * sender){
            NSLog(@"Convenience callback received (left).");
            BOOL autoHide = i != 2;
            return autoHide; //Don't autohide in delete button to improve delete expansion animation
        }];
        [result addObject:button];
    }
    return result;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Node *node = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [self performSegueWithIdentifier:@"ShowNodeSettings" sender:node];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    Node *node = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [self performSegueWithIdentifier:@"ShowNodeDetail" sender:node];
}

//- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
//    return YES;
//}

// Override to support editing the table view.
//- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
//    if (editingStyle == UITableViewCellEditingStyleDelete) {
//        // Delete the row from the data source
//        Node *node = [self.fetchedResultsController objectAtIndexPath:indexPath];
//        [self.HUD show:YES];
//        [[PionOneManager sharedInstance] removeNode:node completionHandler:^(BOOL succes, NSString *msg) {
//            [self.HUD hide:YES];
//        }];
//    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
//        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
//    }
//}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
//    NSString *online = [[[self.fetchedResultsController sections] objectAtIndex:section] name];
//    if ([online isEqualToString:@"0"]) {
//        return @"Offline";
//    }
//    return @"Online";
    return [[[self.fetchedResultsController sections] objectAtIndex:section] name];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 100.0;
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
