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
#import "NodeResourcesVC.h"
#import "NodeListCell.h"
#import "MGSwipeButton.h"
#import "MGSwipeTableCell.h"
#import "UIViewController+RESideMenu.h"
#import "UIScrollView+EmptyDataSet.h"
#import "wioLinkViews.h"
#import <GoogleMaterialIconFont/GoogleMaterialIconFont-Swift.h>
#import "RESideMenu.h"

@interface NodeListCDTVC() <MBProgressHUDDelegate, MGSwipeTableCellDelegate, UITextFieldDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>
@property (strong, nonatomic) UIAlertController *renameDialog;
@property (strong, nonatomic) Node *configuringNode;
@property (assign, nonatomic) BOOL cellCanBeSelected;
@property (assign, nonatomic) BOOL isReloading;
@property (strong, nonatomic) NSFetchedResultsController *cachedFRC;
@property (atomic, assign) __block BOOL reachable;
@property (nonatomic, strong) UIView *reachableHeaderView;
@end

@implementation NodeListCDTVC

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.tableView.tableFooterView.hidden = self.tableView.isEmptyDataSetVisible;
    
    self.fetchedResultsController.delegate = self;
    [self performFetch];
    self.sideMenuViewController.panGestureEnabled = YES;

}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.sideMenuViewController.panGestureEnabled = NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    [[PionOneManager sharedInstance] scanDriverListWithCompletionHandler:nil];

    self.managedObjectContext = [[PionOneManager sharedInstance] mainMOC];
//    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
//    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:195 green:22 blue:30 alpha:1];
//    self.navigationController.navigationBar.translucent = NO;
    self.cellCanBeSelected = YES;

    self.reachableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 40)];
    UILabel *info = [[UILabel alloc] initWithFrame:self.reachableHeaderView.frame];
    info.text = @"We need network to retrieve the settings from server";
    info.font = [UIFont systemFontOfSize:14];
    info.alpha = 0.9;
    info.textAlignment = NSTextAlignmentCenter;
    info.lineBreakMode = NSLineBreakByCharWrapping;
    info.numberOfLines = 0;
    [self.reachableHeaderView addSubview:info];

    UIView *footerView = self.tableView.tableFooterView;
    [footerView setNeedsLayout];
    [footerView layoutIfNeeded];
    CGRect frame = footerView.frame;
    frame.size.height = 30;
    footerView.frame = frame;
    footerView.backgroundColor = [UIColor clearColor];
    self.tableView.tableFooterView = footerView;
    
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
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to retrieve server settings" attributes:attributes];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
    [self refresh:self.refreshControl];
    
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusNotReachable:
                NSLog(@"No Internet Connection");
                self.reachable = NO;
                break;
            case AFNetworkReachabilityStatusReachableViaWiFi:
                NSLog(@"WIFI");
                self.reachable = YES;
                break;
            case AFNetworkReachabilityStatusReachableViaWWAN:
                NSLog(@"3G");
                self.reachable = YES;
                break;
            default:
                NSLog(@"Unkown network status");
                self.reachable = NO;
                break;
        }
        if (!self.reachable) {
            [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.tableView.tableHeaderView = self.reachableHeaderView;
            } completion:^(BOOL finished) {
                //
            }];
        } else {
            [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.tableView.tableHeaderView = nil;
            } completion:^(BOOL finished) {
                //
            }];
        }
    }];
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];


}

- (void)refresh:(UIRefreshControl *)refreshControl {
    [[PionOneManager sharedInstance] deleteZombieNodeWithCompletionHandler:^(BOOL succes, NSString *msg) {
        [[PionOneManager sharedInstance] getNodeListAndNodeSettingsWithCompletionHandler:^(BOOL success, NSString *msg) {
            [self.refreshControl endRefreshing];
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

- (UIAlertController *)renameDialog {
    __typeof (&*self) __weak weakSelf = self;
    if (_renameDialog == nil) {
        _renameDialog = [UIAlertController alertControllerWithTitle:nil message:[NSString stringWithFormat:@"Rename Wio Link"] preferredStyle:UIAlertControllerStyleAlert];
        [_renameDialog addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:nil]];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self renameNode];
        }];
        okAction.enabled = NO;
        [_renameDialog addAction:okAction];
        [_renameDialog addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = @"Take a name for Wio Link";
            textField.secureTextEntry = NO;
            [textField setReturnKeyType:UIReturnKeyGo];
            textField.delegate = weakSelf;
            [textField addTarget:weakSelf action:@selector(textFieldDidChange) forControlEvents:UIControlEventEditingChanged];
        }];
    }
    return _renameDialog;
}

#pragma -mark EmptyDataSet Datasource
- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView
{
    float scale = 3* 380.0/[UIScreen mainScreen].applicationFrame.size.width;

    UIImage *scaledImage = [UIImage imageWithCGImage:[[UIImage imageNamed:@"emptyList"] CGImage] scale:scale orientation:UIImageOrientationUp];
    return scaledImage;
}
//- (CAAnimation *)imageAnimationForEmptyDataSet:(UIScrollView *)scrollView
//{
//    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath: @"transform"];
//    
//    animation.fromValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
//    animation.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeRotation(M_PI_2, 0.0, 0.0, 1.0)];
//    
//    animation.duration = 1;
//    animation.cumulative = YES;
//    animation.repeatCount = MAXFLOAT;
//    
//    return animation;
//}

//- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView
//{
//    NSString *text = @"Building IoT devices in 5 minutes";
//    
//    NSDictionary *attributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:18.0f],
//                                 NSForegroundColorAttributeName: [UIColor darkGrayColor]};
//    
//    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
//}
//- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView
//{
//    NSString *text = @"Wio Link is a Wi-Fi development board to build connected IoT projects with Grove modules. Simplify your development of IoT devices without requirements of hardware programming or soldering.";
//    
//    NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
//    paragraph.lineBreakMode = NSLineBreakByWordWrapping;
//    paragraph.alignment = NSTextAlignmentCenter;
//    
//    NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:14.0f],
//                                 NSForegroundColorAttributeName: [UIColor lightGrayColor],
//                                 NSParagraphStyleAttributeName: paragraph};
//    
//    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
//}

- (NSAttributedString *)buttonTitleForEmptyDataSet:(UIScrollView *)scrollView forState:(UIControlState)state
{
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:17.0f]};
    
    return [[NSAttributedString alloc] initWithString:@"Tap add button to start" attributes:attributes];
}
- (void)emptyDataSet:(UIScrollView *)scrollView didTapButton:(UIButton *)button {
    [self addNode:nil];
}
//- (UIImage *)buttonImageForEmptyDataSet:(UIScrollView *)scrollView forState:(UIControlState)state
//{
//    return [UIImage imageNamed:@"logo_color"];
//}
- (UIColor *)backgroundColorForEmptyDataSet:(UIScrollView *)scrollView
{
    return [UIColor whiteColor];
}
//- (UIView *)customViewForEmptyDataSet:(UIScrollView *)scrollView
//{
//    UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
//    [activityView startAnimating];
//    return activityView;
//}
//- (CGFloat)verticalOffsetForEmptyDataSet:(UIScrollView *)scrollView
//{
//    return -self.tableView.tableFooterView.frame.size.height;
//}
#pragma -mark EmptyDataSet Delegate
- (BOOL)emptyDataSetShouldDisplay:(UIScrollView *)scrollView
{
    return YES;
}
- (BOOL)emptyDataSetShouldAllowScroll:(UIScrollView *)scrollView
{
    return YES;
}
//- (BOOL) emptyDataSetShouldAllowImageViewAnimate:(UIScrollView *)scrollView
//{
//    return YES;
//}
#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [super controllerDidChangeContent:controller];
    self.tableView.tableFooterView.hidden = self.tableView.isEmptyDataSetVisible;
}

#pragma -mark TableVew Delegate
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NodeListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NodeListTVCell" forIndexPath:indexPath];
    Node *node = [self.fetchedResultsController objectAtIndexPath:indexPath];

    //setup swipe cell delegate
    cell.delegate = self;
    //setup cell properties
    cell.nameLabel.text = node.name;
    if (node.online.boolValue) {
        [cell.onlineIndicator setBackgroundColor:[wioLinkViews wioLinkBlue]];
        cell.onlineLabel.text = @"Online";
        cell.onlineLabel.textColor = [wioLinkViews wioLinkBlue];
    } else {
        [cell.onlineIndicator setBackgroundColor:[wioLinkViews wioLinkRed]];
        cell.onlineLabel.text = @"Offline";
        cell.onlineLabel.textColor = [wioLinkViews wioLinkRed];
    }
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"connectorName" ascending:YES];
    cell.groves = [node.groves sortedArrayUsingDescriptors:@[descriptor]];
    return cell;
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


#pragma -mark SwipTableCell Delegate
- (NSArray *)swipeTableCell:(NodeListCell *)cell swipeButtonsForDirection:(MGSwipeDirection)direction swipeSettings:(MGSwipeSettings *)swipeSettings expansionSettings:(MGSwipeExpansionSettings *)expansionSettings {
    
    swipeSettings.transition = MGSwipeTransitionStatic;
    if (direction == MGSwipeDirectionRightToLeft) {
        NSIndexPath * path = [self.tableView indexPathForCell:cell];
//        Node *node = [self.fetchedResultsController objectAtIndexPath:path];
        NodeListCell *cell = [self.tableView cellForRowAtIndexPath:path];
        UIColor *buttonColor = cell.onlineIndicator.backgroundColor;
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
        if (node.groves.count > 0) {
            [self performSegueWithIdentifier:@"ShowNodeAPI" sender:node];
        } else {
            [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"You have to update firmware for this device first." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
        }
    } else if (direction == MGSwipeDirectionRightToLeft && index == 1) {
        self.configuringNode = node;
        [[self.renameDialog.textFields objectAtIndex:0] setText:nil];
        [[self.renameDialog.actions objectAtIndex:1] setEnabled:NO];
        [self presentViewController:self.renameDialog animated:YES completion:nil];
    } else if (direction == MGSwipeDirectionRightToLeft && index == 2) {
        //delete button
        UIAlertController *removeAlert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        [removeAlert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [removeAlert addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [self.HUD show:YES];
            [[PionOneManager sharedInstance] removeNode:node completionHandler:^(BOOL succes, NSString *msg) {
                [self.HUD hide:YES];
            }];
        }]];
        [self presentViewController:removeAlert animated:YES completion:nil];
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
    NSString* titles[3] = {@"API", @"Rename", @"Delete"};
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

#pragma -mark Actions
- (IBAction)addNode:(UIBarButtonItem *)sender {
//    if (1) {
//        [self performSegueWithIdentifier:@"ShowAPconfigVC" sender:nil];
//        return;
//    }
    [self.HUD show:YES];
    [[PionOneManager sharedInstance] rebootPionOne];
    [[PionOneManager sharedInstance] deleteZombieNodeWithCompletionHandler:^(BOOL succes, NSString *msg) {
        [[PionOneManager sharedInstance] createNodeWithName:@"node000" completionHandler:^(BOOL succes, NSString *msg) {
            [self.HUD hide:YES];
            if (succes) {
                [[PionOneManager sharedInstance] cacheCurrentSSID];
                if ([[PionOneManager sharedInstance] cachedSSID] &&
                    ![[[PionOneManager sharedInstance] cachedSSID] containsString:@"PionOne_"] &&
                    ![[[PionOneManager sharedInstance] cachedSSID] containsString:@"WioLink_"])
                {
                    [self performSegueWithIdentifier:@"ShowAPconfigVC" sender:nil];
                } else {
                    msg = @"Please make sure that your phone is connected to an available wifi network.";
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"No"
                                                                        message:msg
                                                                       delegate:nil
                                                              cancelButtonTitle:@"Ok"
                                                              otherButtonTitles:nil];
                    [alertView show];
                }
            } else {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Sorry"
                                                                    message:@"We had a problem doing this for you, please check your wifi network and try again."
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
    self.fetchedResultsController.delegate = nil;
    id dVC = [segue destinationViewController];
    if ([dVC isKindOfClass:[SetupNodeVC class]]) {
        if ([sender isKindOfClass:[Node class]]) {
            [(SetupNodeVC *)dVC setNode:sender];
            [(SetupNodeVC *)dVC setManagedObjectContext:self.managedObjectContext];
            [[(SetupNodeVC *)dVC navigationController] setTitle:[(Node *)sender name]];
        }
    } else if ([dVC isKindOfClass:[NodeResourcesVC class]]) {
        if ([sender isKindOfClass:[Node class]]) {
            [(NodeResourcesVC *)dVC setNode:sender];
        }
    }
}


@end
