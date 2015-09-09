//
//  DriverListCDTVC.m
//  PionOne
//
//  Created by Qxn on 15/9/4.
//  Copyright (c) 2015年 SeeedStudio. All rights reserved.
//

#import "DriverListCDTVC.h"
#import "Driver.h"
#import "PionOneManager.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "DriverDetailVC.h"

@implementation DriverListCDTVC
- (void)viewDidLoad {
    [super viewDidLoad];
    self.managedObjectContext = [[PionOneManager sharedInstance] managedObjectContext];
    // A little trick for removing the cell separators
    self.tableView.tableFooterView = [UIView new];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refreshControl];
}

- (void)refresh:(UIRefreshControl *)refreshControl {
    [[PionOneManager sharedInstance] scanDriverListWithCompletionHandler:^(BOOL succes, NSString *msg) {
        [refreshControl endRefreshing];
    }];
}

#pragma -mark Properyies
- (void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    _managedObjectContext = managedObjectContext;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Driver"];
    request.predicate = nil;
    request.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"interfaceType"
                                                            ascending:YES
                                                           selector:@selector(localizedStandardCompare:)],
                                [[NSSortDescriptor alloc] initWithKey:@"groveName"
                                                            ascending:YES
                                                             selector:@selector(localizedStandardCompare:)]];
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:managedObjectContext
                                                                          sectionNameKeyPath:@"interfaceType"
                                                                                   cacheName:@"DriverList"];
}



#pragma -mark TableVew Delegate
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GroveDriverCell" forIndexPath:indexPath];
    Driver *driver = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = driver.groveName;
    cell.detailTextLabel.text = driver.interfaceType;
    NSURL *url = [NSURL URLWithString:driver.imageURL];
    [cell.imageView sd_setImageWithURL:url placeholderImage:[UIImage imageNamed:@"About"]];
    return cell;
}



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    [self performSegueWithIdentifier:@"ShowDriverDetail" sender:cell.imageView.image];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 55.0;
}
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    id dVC = [segue destinationViewController];
    if ([dVC isKindOfClass:[DriverDetailVC class]]) {
        if ([sender isKindOfClass:[UIImage class]]) {
            [(DriverDetailVC *)dVC setDriverImage:sender];;
         }
    }
}

@end
