//
//  SelectGroveTVC.m
//  PionOne
//
//  Created by Qxn on 15/9/10.
//  Copyright (c) 2015年 SeeedStudio. All rights reserved.
//

#import "SelectGroveTVC.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "DriverDetailVC.h"
#import "Grove+Create.h"

@interface SelectGroveTVC ()
@property (nonatomic, strong) NSString *interfaceType;
@end

@implementation SelectGroveTVC

#pragma -mark Properties
- (NSString *)interfaceType {
    if (_connectorName == nil) {
        return nil;
    }
    _interfaceType = [[PionOneManager sharedInstance] interfaceTypeForCntName:_connectorName];
    return _interfaceType;
}

- (void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    _managedObjectContext = managedObjectContext;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Driver"];
    request.predicate = [NSPredicate predicateWithFormat:@"interfaceType = %@", self.interfaceType];
    request.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"groveName"
                                                            ascending:YES
                                                             selector:@selector(localizedStandardCompare:)]];
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:managedObjectContext
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = self.connectorName;
}

#pragma -mark TableVew Delegate
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GroveDriverCell" forIndexPath:indexPath];
    Driver *driver = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = driver.groveName;
    cell.detailTextLabel.text = driver.interfaceType;
    NSURL *url = [NSURL URLWithString:driver.imageURL];
    [cell.imageView sd_setImageWithURL:url placeholderImage:[UIImage imageNamed:@"ic_extension_36pt"]];
    return cell;
}



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Driver *selectDriver = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [Grove groveForNode:self.node WithDriver:selectDriver connector:self.connectorName inManagedContext:self.managedObjectContext];
    [self.navigationController popViewControllerAnimated:YES];
//    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
//    [self performSegueWithIdentifier:@"ShowDriverDetail" sender:cell.imageView.image];
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
