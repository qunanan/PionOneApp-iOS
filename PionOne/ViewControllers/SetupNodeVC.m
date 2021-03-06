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
#import "GroveButton.h"
#import "NodeResourcesVC.h"
#import "KHFlatButton.h"
#import "wioLinkViews.h"

@interface SetupNodeVC () <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>
@property (strong, nonatomic) IBOutletCollection(GroveButton) NSArray *groveButtons;
@property (weak, nonatomic) IBOutlet KHFlatButton *apiButton;
@property (weak, nonatomic) IBOutlet UIImageView *setupImage;

@property (nonatomic, strong) MBProgressHUD *HUD;
@property (nonatomic, assign) BOOL isConfigured;
@end

@implementation SetupNodeVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.node.name;
    self.isConfigured = self.node.groves.count? YES:NO;
    self.tableView.delegate = self;
    //config setup image and buttons
    if ([self.node.board containsString:@"Node"]) { //wio node
        [self.setupImage setImage:[UIImage imageNamed:@"wioNode"]];
        for (GroveButton *btn in self.groveButtons) {
            btn.hidden = YES;
            if (btn.tag == 12) {
                [btn setTitle:@"PORT0" forState:UIControlStateNormal];
                btn.hidden = NO;
            }
            if (btn.tag == 22) {
                [btn setTitle:@"PORT1" forState:UIControlStateNormal];
                btn.hidden = NO;
            }
        }
    } else {
        [self.setupImage setImage:[UIImage imageNamed:@"wioLink"]];
    }
    [self refreshGroveButtonConfiguration];

    //add a button
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [[UIColor whiteColor] CGColor]);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [self.apiButton setBackgroundImage:image forState:UIControlStateHighlighted];
    [self.apiButton setTitleColor:[wioLinkViews wioLinkBrown] forState: UIControlStateHighlighted];
    self.apiButton.layer.borderColor = [[UIColor whiteColor] CGColor];
    self.apiButton.layer.borderWidth = 3.0;

    //Init headerView
    UIView *headerView = self.tableView.tableHeaderView;
    [headerView setNeedsLayout];
    [headerView layoutIfNeeded];
    CGRect frame = headerView.frame;
    frame.size.height = 210;
    headerView.frame = frame;
    self.tableView.tableHeaderView = headerView;
    
    
    
    UIView *footerView = self.tableView.tableFooterView;
    [footerView setNeedsLayout];
    [footerView layoutIfNeeded];
    frame = footerView.frame;
    frame.size.height = 143;
    footerView.frame = frame;
    self.tableView.tableFooterView = footerView;
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl setTintColor:[UIColor lightGrayColor]];
    UIFont * font = [UIFont systemFontOfSize:14.0];
    NSDictionary *attributes = @{NSFontAttributeName:font, NSForegroundColorAttributeName : [UIColor lightGrayColor]};
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to retrieve configuration" attributes:attributes];
    self.refreshControl = refreshControl;
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.isMovingFromParentViewController || self.isBeingDismissed) {
        // This view controller is being popped or dismissed
        [self refresh:self.refreshControl];
    }
//
//    [_managedObjectContext performBlock:^{
//        NSError *childError = nil;
//        if (![_managedObjectContext save:&childError]) {
//            NSLog(@"Error saving child");
//        }
//    }];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.node.groves.count == 0 || 1) {
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if( self.refreshControl.isRefreshing )
        [self refresh:nil];
}

- (void)refresh:(UIRefreshControl *)refreshControl {
    [[PionOneManager sharedInstance] node:self.node getSettingsWithCompletionHandler:^(BOOL success, NSString *msg) {
        [self.refreshControl endRefreshing];
    }];
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
    [cell.imageView sd_setImageWithURL:url placeholderImage:[UIImage imageNamed:@"placeHolder"]];
    return cell;
}
- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    if ([view isKindOfClass: [UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView* castView = (UITableViewHeaderFooterView*) view;
        castView.contentView.backgroundColor = [wioLinkViews wioLinkBrown];
        [castView.textLabel setTextColor:[UIColor whiteColor]];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 55.0;
}


#pragma -mark private methods
- (void)startOTA {
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;

    self.HUD.detailsLabelText = nil;
    [self.HUD show:YES];
    [[PionOneManager sharedInstance] node:self.node startOTAWithprogressHandler:^(BOOL success, NSString *msg, NSString *ota_msg, NSString *ota_staus) {
        if (success) {
            self.HUD.detailsLabelText = ota_msg;
//            self.HUD.labelText = ota_staus;
            if ([ota_staus isEqualToString:@"done"]) {
                [self.HUD hide:YES];
                [[[UIAlertView alloc] initWithTitle:@"Success!" message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                self.isConfigured = YES;
                self.navigationController.interactivePopGestureRecognizer.enabled = YES;
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
    [self performSegueWithIdentifier:@"ShowDriverDetail" sender:grove.driver];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    [cell setSelected:NO animated:YES];
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

#pragma mark - NSFetchedResultsControllerDelegate
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [super controllerDidChangeContent:controller];
    [self refreshGroveButtonConfiguration];
}

#pragma -mark Actions
- (IBAction)groveButtonPushed:(UIButton *)sender {
    NSString *cntName = sender.titleLabel.text;

    if ([self.node.board containsString:@"Node"]) {
        NSArray *types;
        if ([sender.titleLabel.text isEqualToString:@"PORT0"]) {
            types = @[@"UART",@"I2C",@"GPIO"];
        } else {
            types = @[@"ANALOG",@"I2C",@"GPIO"];
        }
        UIAlertController *selectPortAction = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        [selectPortAction addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        for (NSString *type in types) {
            [selectPortAction addAction:[UIAlertAction actionWithTitle:type style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                NSDictionary *configDic = [[NSDictionary alloc] initWithObjects:@[cntName, type] forKeys:@[CNT_NAME,INTERFACE_TYPE]];
                [self performSegueWithIdentifier:@"ShowSelectGrove" sender:configDic];
            }]];
        }
        [self presentViewController:selectPortAction animated:YES completion:nil];
        return;
    } else {
        NSString *type = [[PionOneManager sharedInstance] interfaceTypeForCntName:cntName];
        NSDictionary *configDic = [[NSDictionary alloc] initWithObjects:@[cntName, type] forKeys:@[CNT_NAME,INTERFACE_TYPE]];
        [self performSegueWithIdentifier:@"ShowSelectGrove" sender:configDic];
    }
}

- (IBAction)updateFirmware:(id)sender {
    UIAlertController *action = [UIAlertController alertControllerWithTitle:nil message:@"It will update this WioLink's firmware and will take about one minute." preferredStyle:UIAlertControllerStyleActionSheet];
    [action addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [action addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self startOTA];
    }]];
    [self presentViewController:action animated:YES completion:nil];
}
- (IBAction)apiButtonPushed:(id)sender {
    if (self.isConfigured) {
        [self performSegueWithIdentifier:@"ShowAPIResourceSegue" sender:nil];
        return;
    }
    [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"You have to update firmware for this device first." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    id dVC = [segue destinationViewController];
    if ([dVC isKindOfClass:[SelectGroveTVC class]]) {
        if ([sender isKindOfClass:[NSDictionary class]]) {
            [(SelectGroveTVC *)dVC setConfigDic:sender];
            [(SelectGroveTVC *)dVC setNode:self.node];
            [(SelectGroveTVC *)dVC setManagedObjectContext:self.managedObjectContext];
        }
    } else if ([dVC isKindOfClass:[DriverDetailVC class]]) {
        if ([sender isKindOfClass:[Driver class]]) {
            [(DriverDetailVC *)dVC setDriver:sender];;
        }
    } else if ([dVC isKindOfClass:[NodeResourcesVC class]]) {
        [(NodeResourcesVC *)dVC setNode:self.node];
    }
}


- (void)refreshGroveButtonConfiguration {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Grove"];
    request.predicate = [NSPredicate predicateWithFormat:@"node = %@", self.node];
    NSError *error;
    NSArray *matches = [self.managedObjectContext executeFetchRequest:request error:&error];
    for (GroveButton *button in self.groveButtons) {
        button.selected = NO;
    }
    for (Grove *grove in matches) {
        for (GroveButton *button in self.groveButtons) {
            if ([button.titleLabel.text isEqualToString: grove.connectorName]) {
                button.selected = YES;
            }
        }
    }
}

@end
