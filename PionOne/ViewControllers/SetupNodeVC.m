//
//  SetupNodeVC.m
//  PionOne
//
//  Created by Qxn on 15/9/10.
//  Copyright (c) 2015年 SeeedStudio. All rights reserved.
//

#import "SetupNodeVC.h"
#import "DriverDetailVC.h"
#import "SelectGroveTVC.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "MBProgressHUD.h"


@interface SetupNodeVC () <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) MBProgressHUD *HUD;
@property NSMutableIndexSet *deletedSections, *insertedSections;
@end

@implementation SetupNodeVC
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.node.name;
    self.tableView.delegate = self;
    self.fetchedResultsController.delegate = self;
    
    [[PionOneManager sharedInstance] node:self.node getSettingsWithCompletionHandler:nil];
}


#pragma -mark Properyies
- (void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    _managedObjectContext = managedObjectContext;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Grove"];
    request.predicate = [NSPredicate predicateWithFormat:@"node = %@", self.node];
    request.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"connectorName"
                                                            ascending:YES
                                                             selector:@selector(localizedStandardCompare:)],
                                [[NSSortDescriptor alloc] initWithKey:@"instanceName"
                                                            ascending:YES
                                                             selector:@selector(localizedStandardCompare:)]];
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:managedObjectContext
                                                                          sectionNameKeyPath:@"connectorName"
                                                                                   cacheName:nil];
}
- (MBProgressHUD *)HUD {
    if (_HUD == nil) {
        _HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
        [self.navigationController.view addSubview:_HUD];
        _HUD.dimBackground = YES;
    }
    return _HUD;
}


#pragma -mark TableVew Delegate
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GroveDriverCell" forIndexPath:indexPath];
    Grove *grove = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = grove.driver.groveName;
    cell.detailTextLabel.text = grove.driver.interfaceType;
    NSURL *url = [NSURL URLWithString:grove.driver.imageURL];
    [cell.imageView sd_setImageWithURL:url placeholderImage:[UIImage imageNamed:@"About"]];
    return cell;
}



//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
//    [self performSegueWithIdentifier:@"ShowSelectGrove" sender:cell.imageView.image];
//}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 55.0;
}


#pragma mark - Fetching

- (void)performFetch
{
    if (self.fetchedResultsController) {
        if (self.fetchedResultsController.fetchRequest.predicate) {
            if (self.debug) NSLog(@"[%@ %@] fetching %@ with predicate: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), self.fetchedResultsController.fetchRequest.entityName, self.fetchedResultsController.fetchRequest.predicate);
        } else {
            if (self.debug) NSLog(@"[%@ %@] fetching all %@ (i.e., no predicate)", NSStringFromClass([self class]), NSStringFromSelector(_cmd), self.fetchedResultsController.fetchRequest.entityName);
        }
        NSError *error;
        BOOL success = [self.fetchedResultsController performFetch:&error];
        if (!success) NSLog(@"[%@ %@] performFetch: failed", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
        if (error) NSLog(@"[%@ %@] %@ (%@)", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [error localizedDescription], [error localizedFailureReason]);
    } else {
        if (self.debug) NSLog(@"[%@ %@] no NSFetchedResultsController (yet?)", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    }
    [self.tableView reloadData];
}

- (void)setFetchedResultsController:(NSFetchedResultsController *)newfrc
{
    NSFetchedResultsController *oldfrc = _fetchedResultsController;
    if (newfrc != oldfrc) {
        _fetchedResultsController = newfrc;
        newfrc.delegate = self;
        if ((!self.title || [self.title isEqualToString:oldfrc.fetchRequest.entity.name]) && (!self.navigationController || !self.navigationItem.title)) {
            self.title = newfrc.fetchRequest.entity.name;
        }
        if (newfrc) {
            if (self.debug) NSLog(@"[%@ %@] %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), oldfrc ? @"updated" : @"set");
            [self performFetch];
        } else {
            if (self.debug) NSLog(@"[%@ %@] reset to nil", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
            [self.tableView reloadData];
        }
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger sections = [[self.fetchedResultsController sections] count];
    return sections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rows = 0;
    if ([[self.fetchedResultsController sections] count] > 0) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
        rows = [sectionInfo numberOfObjects];
    }
    return rows;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [[[self.fetchedResultsController sections] objectAtIndex:section] name];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return [self.fetchedResultsController sectionForSectionIndexTitle:title atIndex:index];
}

//- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
//{
//    return [self.fetchedResultsController sectionIndexTitles];
//}

#pragma mark - NSFetchedResultsControllerDelegate
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
    
    self.deletedSections = [[NSMutableIndexSet alloc] init];
    self.insertedSections = [[NSMutableIndexSet alloc] init];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:sectionIndex];
    
    switch(type) {
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
            [self.deletedSections addIndexes:indexSet];
            break;
            
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
            [self.insertedSections addIndexes:indexSet];
            break;
            
        default:
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    switch(type) {
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:@[ newIndexPath ] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeMove:
            // iOS 9.0b5 sends the same index path twice instead of delete
            if(![indexPath isEqual:newIndexPath]) {
                [self.tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView insertRowsAtIndexPaths:@[ newIndexPath ] withRowAnimation:UITableViewRowAnimationFade];
            }
            else if([self.insertedSections containsIndex:indexPath.section]) {
                // iOS 9.0b5 bug: Moving first item from section 0 (which becomes section 1 later) to section 0
                // Really the only way is to delete and insert the same index path...
                [self.tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView insertRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationFade];
            }
            else if([self.deletedSections containsIndex:indexPath.section]) {
                // iOS 9.0b5 bug: same index path reported after section was removed
                // we can ignore item deletion here because the whole section was removed anyway
                [self.tableView insertRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationFade];
            } else {
                [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                 withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                                 withRowAnimation:UITableViewRowAnimationFade];
                break;
            }
            
            break;
            
        case NSFetchedResultsChangeUpdate:
            // On iOS 9.0b5 NSFetchedResultsController may not even contain such indexPath anymore
            // when removing last item from section.
            if(![self.deletedSections containsIndex:indexPath.section] && ![self.insertedSections containsIndex:indexPath.section]) {
                // iOS 9.0b5 sends update before delete therefore we cannot use reload
                // this will never work correctly but at least no crash.
                [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            }
            
            break;
    }
}

#pragma -mark private methods
- (void)startOTA {
    self.HUD.labelText = @"Preparing...";
    self.HUD.detailsLabelText = nil;
    [self.HUD show:YES];
    [[PionOneManager sharedInstance] node:self.node startOTAWithprogressHandler:^(BOOL success, NSString *msg, NSString *ota_msg, NSString *ota_staus) {
        if (success) {
            self.HUD.detailsLabelText = ota_msg;
            self.HUD.labelText = ota_staus;
            if ([ota_staus isEqualToString:@"done"]) {
                [self.HUD hide:YES];
                [[[UIAlertView alloc] initWithTitle:@"Success!" message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            }
            if ([ota_staus isEqualToString:@"error"]) {
                [self.HUD hide:YES];
                [[[UIAlertView alloc] initWithTitle:@"Error" message:ota_msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            }
        } else {
            [self.HUD hide:YES];
            [[[UIAlertView alloc] initWithTitle:@"Error!" message:msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }
//        NSLog(@"%@",msg);
//        NSLog(@"%@",ota_msg);
//        NSLog(@"%@",ota_staus);
    }];
}

#pragma -mark UIAlertView delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [self startOTA];
    }
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Grove *grove = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [self performSegueWithIdentifier:@"ShowSelectGrove" sender:grove.connectorName];
}
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        Grove *grove = [self.fetchedResultsController objectAtIndexPath:indexPath];
        [self.node removeGrovesObject:grove];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
}

#pragma -mark Actions
- (IBAction)groveButtonPushed:(UIButton *)sender {
    [self performSegueWithIdentifier:@"ShowSelectGrove" sender:sender.titleLabel.text];
}
- (IBAction)ota:(id)sender {
    [[[UIAlertView alloc] initWithTitle:@"Are you sure?"
                               message:@"It will reset the node settings."
                              delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK",nil] show];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    id dVC = [segue destinationViewController];
    if ([dVC isKindOfClass:[SelectGroveTVC class]]) {
        if ([sender isKindOfClass:[NSString class]]) {
            [(SelectGroveTVC *)dVC setConnectorName:sender];
            [(SelectGroveTVC *)dVC setManagedObjectContext:self.managedObjectContext];
            [(SelectGroveTVC *)dVC setNode:self.node];
        }
    }
}

@end
