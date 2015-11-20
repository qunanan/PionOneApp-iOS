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
@property (nonatomic, strong) NSMutableArray *i2cDevices;
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
    if ([self.connectorName isEqualToString:@"I2C"]) {
        
        UIView *footerView = self.tableView.tableFooterView;
        [footerView setNeedsLayout];
        [footerView layoutIfNeeded];
        CGRect frame = footerView.frame;
        frame.size.height = 60;
        footerView.frame = frame;
        self.tableView.tableFooterView = footerView;

        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(addGroves)];

        self.tableView.allowsMultipleSelection = YES;
        self.i2cDevices = [[NSMutableArray alloc] init];
    } else {
        self.tableView.tableFooterView = [UIView new];
    }
}

#pragma -mark TableVew Delegate
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GroveDriverCell" forIndexPath:indexPath];
    Driver *driver = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = driver.groveName;
    cell.detailTextLabel.text = driver.interfaceType;
    NSURL *url = [NSURL URLWithString:driver.imageURL];
    [cell.imageView sd_setImageWithURL:url placeholderImage:[UIImage imageNamed:@"placeHolder"]];
    return cell;
}



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Driver *selectDriver = [self.fetchedResultsController objectAtIndexPath:indexPath];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    [cell setSelected:NO animated:YES];

    if (self.tableView.allowsMultipleSelection) {
        if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
            cell.accessoryType = UITableViewCellAccessoryNone;
            [self.i2cDevices removeObject:selectDriver];
        } else {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            [self.i2cDevices addObject:selectDriver];
        }
    } else {
        [self.node addNewGroveWithDriver:selectDriver cntName:self.connectorName];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 55.0;
}


- (void)addGroves {
    [self.node addI2CGrovesWithDrivers:self.i2cDevices cntName:self.connectorName];
    [self.navigationController popViewControllerAnimated:YES];
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
