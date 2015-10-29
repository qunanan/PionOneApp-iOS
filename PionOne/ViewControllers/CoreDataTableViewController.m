//
//  CoreDataTableViewController.m
//
//  Created for Stanford CS193p Fall 2013.
//  Copyright 2013 Stanford University. All rights reserved.
//

#import "CoreDataTableViewController.h"

@interface CoreDataTableViewController ()
@property NSMutableIndexSet *deletedSections, *insertedSections;
@property (nonatomic, strong) NSString *theSectionKey;
@property BOOL changedSection;
@end


@implementation CoreDataTableViewController

- (void)setTheSectionKey:(NSString *)theSectionKey {
    if(theSectionKey != _theSectionKey) {
        self.changedSection = YES;
    }
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

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    //return [self.fetchedResultsController sectionIndexTitles];
    return nil;
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
    if (self.refreshControl) {
        [self.refreshControl beginRefreshing];
    }
}

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
		   atIndex:(NSUInteger)sectionIndex
	 forChangeType:(NSFetchedResultsChangeType)type
{
    self.changedSection = YES;
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeUpdate:
        case NSFetchedResultsChangeMove:
            break;

    }
}


- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
	   atIndexPath:(NSIndexPath *)indexPath
	 forChangeType:(NSFetchedResultsChangeType)type
	  newIndexPath:(NSIndexPath *)newIndexPath
{
    if ( (NSFetchedResultsChangeUpdate == type) && ([self changedSection]) ) {
        [self  setChangedSection:NO];
        type = NSFetchedResultsChangeMove;
        newIndexPath = indexPath;
    }

    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeMove:
                [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
    if (self.refreshControl) {
        [self.refreshControl endRefreshing];
    }
}



//////////////////////////////////////////////////////////////////////////////////////////////////////////////


// ...

//- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
//    [self.tableView beginUpdates];
//    
//    self.deletedSections = [[NSMutableIndexSet alloc] init];
//    self.insertedSections = [[NSMutableIndexSet alloc] init];
//}
//
//- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
//    [self.tableView endUpdates];
//}
//
//- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
//    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:sectionIndex];
//    
//    switch(type) {
//        case NSFetchedResultsChangeDelete:
//            [self.tableView deleteSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
//            [self.deletedSections addIndexes:indexSet];
//            break;
//            
//        case NSFetchedResultsChangeInsert:
//            [self.tableView insertSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
//            [self.insertedSections addIndexes:indexSet];
//            break;
//            
//        default:
//            break;
//    }
//}
//
//- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
//    switch(type) {
//        case NSFetchedResultsChangeDelete:
//            [self.tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationFade];
//            break;
//            
//        case NSFetchedResultsChangeInsert:
//            [self.tableView insertRowsAtIndexPaths:@[ newIndexPath ] withRowAnimation:UITableViewRowAnimationFade];
//            break;
//            
//        case NSFetchedResultsChangeMove:
//            // iOS 9.0b5 sends the same index path twice instead of delete
//            if(![indexPath isEqual:newIndexPath]) {
//                [self.tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationFade];
//                [self.tableView insertRowsAtIndexPaths:@[ newIndexPath ] withRowAnimation:UITableViewRowAnimationFade];
//            }
//            else if([self.insertedSections containsIndex:indexPath.section]) {
//                // iOS 9.0b5 bug: Moving first item from section 0 (which becomes section 1 later) to section 0
//                // Really the only way is to delete and insert the same index path...
//                [self.tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationFade];
//                [self.tableView insertRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationFade];
//            }
//            else if([self.deletedSections containsIndex:indexPath.section]) {
//                // iOS 9.0b5 bug: same index path reported after section was removed
//                // we can ignore item deletion here because the whole section was removed anyway
//                [self.tableView insertRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationFade];
//            } else {
//                [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
//                                      withRowAnimation:UITableViewRowAnimationFade];
//                [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
//                                      withRowAnimation:UITableViewRowAnimationFade];
//                break;
//            }
//            
//            break;
//            
//        case NSFetchedResultsChangeUpdate:
//            // On iOS 9.0b5 NSFetchedResultsController may not even contain such indexPath anymore
//            // when removing last item from section.
//            if(![self.deletedSections containsIndex:indexPath.section] && ![self.insertedSections containsIndex:indexPath.section]) {
//                // iOS 9.0b5 sends update before delete therefore we cannot use reload
//                // this will never work correctly but at least no crash.
//                [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
//            }
//            
//            break;
//    }
//}
////
////- (void)configureCell:(id)cell forRowAtIndexPath:(NSIndexPath*)indexPath
////{
////    id object = [[self fetchedResultsController] objectAtIndexPath:indexPath];
////    
////    // Populate cell from the NSManagedObject instance
////}

@end

