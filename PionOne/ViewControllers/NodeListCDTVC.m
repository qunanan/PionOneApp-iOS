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
#import "SetupNodeVC.h"
#import "NodeDetailTVC.h"
#import "NodeListCell.h"
#import "MGSwipeButton.h"
#import "MGSwipeTableCell.h"
#import <GoogleMaterialIconFont/GoogleMaterialIconFont-Swift.h>
#import "UIViewController+RESideMenu.h"

@interface NodeListCDTVC() <MBProgressHUDDelegate, MGSwipeTableCellDelegate, UITextFieldDelegate>
@property (strong, nonatomic) UIAlertController *renameDialog;
@property (strong, nonatomic) Node *configuringNode;
@property (assign, nonatomic) BOOL cellCanBeSelected;
@property (assign, nonatomic) BOOL isReloading;
@property (strong, nonatomic) NSFetchedResultsController *cachedFRC;

@end

@implementation NodeListCDTVC

- (UIAlertController *)renameDialog {
    __typeof (&*self) __weak weakSelf = self;
    if (_renameDialog == nil) {
        _renameDialog = [UIAlertController alertControllerWithTitle:nil message:[NSString stringWithFormat:@"Rename Pion One"] preferredStyle:UIAlertControllerStyleAlert];
        [_renameDialog addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:nil]];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self renameNode];
        }];
        okAction.enabled = NO;
        [_renameDialog addAction:okAction];
        [_renameDialog addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = @"Take a name for Pion One";
            textField.secureTextEntry = NO;
            [textField setReturnKeyType:UIReturnKeyGo];
            textField.delegate = weakSelf;
            [textField addTarget:weakSelf action:@selector(textFieldDidChange) forControlEvents:UIControlEventEditingChanged];
        }];
    }
    return _renameDialog;
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.fetchedResultsController.delegate = self;
    [self performFetch];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.managedObjectContext = [[PionOneManager sharedInstance] mainMOC];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.cellCanBeSelected = YES;

    // A little trick for removing the cell separators
    self.tableView.tableFooterView = [UIView new];
    
    //init left bar button
    CGRect barIconRect = CGRectMake(0, 0, 28, 28);
    UIButton *leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [leftButton setFrame:barIconRect];
    [leftButton setTitle:[NSString materialIcon:MaterialIconFontMenu] forState:UIControlStateNormal];
    [leftButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [leftButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    leftButton.titleLabel.font = [UIFont materialIconOfSize:28];
    [leftButton addTarget:self action:@selector(presentLeftMenuViewController:)forControlEvents:UIControlEventTouchUpInside];
    //Init right bar botton
    UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [rightButton setFrame:barIconRect];
    [rightButton setTitle:[NSString materialIcon:MaterialIconFontAdd] forState:UIControlStateNormal];
    [rightButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [rightButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    rightButton.titleLabel.font = [UIFont materialIconOfSize:28];
    [rightButton addTarget:self action:@selector(addNode:)forControlEvents:UIControlEventTouchUpInside];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:rightButton];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:leftButton];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];

    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    UIFont * font = [UIFont systemFontOfSize:14.0];
    NSDictionary *attributes = @{NSFontAttributeName:font, NSForegroundColorAttributeName : [UIColor blackColor]};
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to refresh" attributes:attributes];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
    [self refresh:self.refreshControl];
}

- (void)refresh:(UIRefreshControl *)refreshControl {
    [[PionOneManager sharedInstance] deleteZombieNodeWithCompletionHandler:^(BOOL succes, NSString *msg) {
        [[PionOneManager sharedInstance] getNodeListAndNodeSettingsWithCompletionHandler:^(BOOL success, NSString *msg) {
            [self.refreshControl endRefreshing];
            [self.tableView reloadData];
        }];
    }];
}
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [super controllerDidChangeContent:controller];
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
    NodeListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NodeListTVCell" forIndexPath:indexPath];
    Node *node = [self.fetchedResultsController objectAtIndexPath:indexPath];

    NSLog(@"%@", cell.contentView.subviews);

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
    return cell;
}



- (NSArray *)swipeTableCell:(NodeListCell *)cell swipeButtonsForDirection:(MGSwipeDirection)direction swipeSettings:(MGSwipeSettings *)swipeSettings expansionSettings:(MGSwipeExpansionSettings *)expansionSettings {
    
    swipeSettings.transition = MGSwipeTransitionStatic;
    if (direction == MGSwipeDirectionRightToLeft) {
        NSIndexPath * path = [self.tableView indexPathForCell:cell];
        Node *node = [self.fetchedResultsController objectAtIndexPath:path];
        UIColor *buttonColor = node.online.boolValue? [UIColor greenColor] : [UIColor redColor];
        return [self createRightButtons:3 withColor:buttonColor];
    } else {
//        expansionSettings.buttonIndex = 0;
//        expansionSettings.fillOnTrigger = YES;
//        NSIndexPath * path = [self.tableView indexPathForCell:cell];
//        Node *node = [self.fetchedResultsController objectAtIndexPath:path];
//        UIColor *buttonColor = node.online.boolValue? [UIColor greenColor] : [UIColor redColor];
//        return [self createLeftButtons:1 withColor:buttonColor];
        return nil;
    }
}

- (void)swipeTableCell:(MGSwipeTableCell *)cell didChangeSwipeState:(MGSwipeState)state gestureIsActive:(BOOL)gestureIsActive {
    if (state == MGSwipeStateSwipingRightToLeft) {
        self.cellCanBeSelected = NO;
    } else if (state == MGSwipeStateSwipingLeftToRight) {
        self.cellCanBeSelected = NO;
    } else if (state == MGSwipeStateNone) {
        self.cellCanBeSelected = YES;
    }
}

- (BOOL)swipeTableCell:(MGSwipeTableCell *)cell canSwipe:(MGSwipeDirection)direction fromPoint:(CGPoint)point {
    return self.cellCanBeSelected;
}

- (BOOL)swipeTableCell:(MGSwipeTableCell *)cell tappedButtonAtIndex:(NSInteger)index direction:(MGSwipeDirection)direction fromExpansion:(BOOL)fromExpansion {
    NSLog(@"Delegate: button tapped, %@ position, index %d, from Expansion: %@",
          direction == MGSwipeDirectionLeftToRight ? @"left" : @"right", (int)index, fromExpansion ? @"YES" : @"NO");
    NSIndexPath * path = [self.tableView indexPathForCell:cell];
    Node *node = [self.fetchedResultsController objectAtIndexPath:path];

    if (direction == MGSwipeDirectionRightToLeft && index == 0) {
        [self performSegueWithIdentifier:@"ShowNodeDetail" sender:node];
    } else if (direction == MGSwipeDirectionRightToLeft && index == 1) {
        self.configuringNode = node;
        [[self.renameDialog.textFields objectAtIndex:0] setText:nil];
        [[self.renameDialog.actions objectAtIndex:1] setEnabled:NO];
        [self presentViewController:self.renameDialog animated:YES completion:nil];
    } else if (direction == MGSwipeDirectionRightToLeft && index == 2) {
        //delete button
        [self.HUD show:YES];
        [[PionOneManager sharedInstance] removeNode:node completionHandler:^(BOOL succes, NSString *msg) {
            [self.HUD hide:YES];
        }];
        return NO; //Don't autohide to improve delete expansion animation
    }
    
    return YES;

}

-(NSArray *) createRightButtons: (int) number withColor:(UIColor *)color
{
    NSMutableArray * result = [NSMutableArray array];
    UIColor * colors[3] = {color, color, color};
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
            NSLog(@"Convenience callback received (Right).");
            BOOL autoHide = i != 2;
            return autoHide; //Don't autohide in delete button to improve delete expansion animation
        }];
        [button setFrame:CGRectMake(0, 0, 80, 80)];
        [button setTitleColor:[UIColor darkGrayColor] forState:UIControlStateHighlighted];
        button.titleLabel.font = [UIFont systemFontOfSize:16];
//        if (i == 2) {
//            [button setTitle:[NSString materialIcon:MaterialIconFontDelete] forState:UIControlStateNormal];
//            button.titleLabel.font = [UIFont materialIconOfSize:16];
//        }
        [result addObject:button];
    }
    return result;
}
-(NSArray *) createLeftButtons: (int) number withColor:(UIColor *)color
{
    NSMutableArray * result = [NSMutableArray array];
    UIColor * colors[1] =  {color};
    //    UIImage * icons[3] = {[UIImage imageNamed:@"check.png"], [UIImage imageNamed:@"fav.png"], [UIImage imageNamed:@"menu.png"]};
    NSString* titles[1] = {@"Favorit"};
    for (int i = 0; i < number; ++i)
    {
        //        MGSwipeButton * button = [MGSwipeButton buttonWithTitle:@"" icon:icons[i] backgroundColor:colors[i] padding:15 callback:^BOOL(MGSwipeTableCell * sender){
        //            NSLog(@"Convenience callback received (left).");
        //            return YES;
        //        }];
        MGSwipeButton * button = [MGSwipeButton buttonWithTitle:titles[i] backgroundColor:colors[i] callback:^BOOL(MGSwipeTableCell * sender){
            NSLog(@"Convenience callback received (left).");
            BOOL autoHide = YES;
            return autoHide; //Don't autohide in delete button to improve delete expansion animation
        }];
        float width = ([UIScreen mainScreen].applicationFrame.size.width - 80) / 3;
        [button setFrame:CGRectMake(0, 0, width, 100.0)];
        [button setTitleColor:[UIColor darkGrayColor] forState:UIControlStateHighlighted];
        button.titleLabel.font = [UIFont systemFontOfSize:16];
        [result addObject:button];
    }
    return result;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.cellCanBeSelected;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Node *node = [self.fetchedResultsController objectAtIndexPath:indexPath];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if (self.cellCanBeSelected == NO) {
        [cell setSelected:NO animated:NO];
        return;
    }
    [self performSegueWithIdentifier:@"ShowNodeSettings" sender:node];
    [cell setSelected:NO animated:YES];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    Node *node = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [self performSegueWithIdentifier:@"ShowNodeDetail" sender:node];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
//    NSString *online = [[[self.fetchedResultsController sections] objectAtIndex:section] name];
//    if ([online isEqualToString:@"0"]) {
//        return @"Offline";
//    }
//    return @"Online";
    return [[[self.fetchedResultsController sections] objectAtIndex:section] name];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 80;
}

#pragma -mark Actions
- (IBAction)addNode:(UIBarButtonItem *)sender {
    [self.HUD show:YES];
    [[PionOneManager sharedInstance] rebootPionOne];
    [[PionOneManager sharedInstance] deleteZombieNodeWithCompletionHandler:^(BOOL succes, NSString *msg) {
        [[PionOneManager sharedInstance] createNodeWithName:@"node000" completionHandler:^(BOOL succes, NSString *msg) {
            [self.HUD hide:YES];
            if (succes) {
                [[PionOneManager sharedInstance] cacheCurrentSSID];
                if ([[PionOneManager sharedInstance] cachedSSID]) {
                    [self performSegueWithIdentifier:@"ShowAPconfigVC" sender:nil];
                } else {
                   msg = @"Do Not Get A WiFi Network!";
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                                        message:msg
                                                                       delegate:nil
                                                              cancelButtonTitle:@"Ok"
                                                              otherButtonTitles:nil];
                    [alertView show];
                }
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

- (void)renameNode {
    NSString *name = [[_renameDialog.textFields objectAtIndex:0] text];
    [self.HUD show:YES];
    [[PionOneManager sharedInstance] renameNode:self.configuringNode withName:name completionHandler:^(BOOL success, NSString *msg) {
        [self.HUD hide:YES];;
    }];
}


#pragma mark -  TextFielDelegate methods
// when user tap Enter or Return
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField.text.length == 0) {
        return NO;
    }
    [self renameNode];
    [self.renameDialog dismissViewControllerAnimated:YES completion:nil];
    return YES;
}
- (void)textFieldDidChange {
    UITextField *textField = [_renameDialog.textFields objectAtIndex:0];
    if (textField.text.length == 0) {
        [_renameDialog.actions objectAtIndex:1].enabled = NO;
    } else {
        [_renameDialog.actions objectAtIndex:1].enabled = YES;
    }
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    id dVC = [segue destinationViewController];
    if ([dVC isKindOfClass:[SetupNodeVC class]]) {
        if ([sender isKindOfClass:[Node class]]) {
            [(SetupNodeVC *)dVC setNode:sender];
            [(SetupNodeVC *)dVC setManagedObjectContext:self.managedObjectContext];
            [[(SetupNodeVC *)dVC navigationController] setTitle:[(Node *)sender name]];
            self.fetchedResultsController.delegate = nil;
        }
    } else if ([dVC isKindOfClass:[NodeDetailTVC class]]) {
        if ([sender isKindOfClass:[Node class]]) {
            [(NodeDetailTVC *)dVC setNode:sender];
        }
    }
}


@end
