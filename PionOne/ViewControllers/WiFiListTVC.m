//
//  WiFiListTVC.m
//  Wio Link
//
//  Created by Qxn on 15/12/11.
//  Copyright © 2015年 SeeedStudio. All rights reserved.
//

#import "WiFiListTVC.h"
#import "PionOneManager.h"

@interface WiFiListTVC ()
@property (nonatomic, strong) NSMutableArray *wifiList;
@property (nonatomic, strong) UIActivityIndicatorView *refreshIndicator;
@end

@implementation WiFiListTVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.tableFooterView = [UIView new];
    
    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = YES;
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self refresh];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    } else {
        return self.wifiList.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"wifiListCell" forIndexPath:indexPath];
    
    if (indexPath.section == 0) {
        cell.textLabel.text = [[PionOneManager sharedInstance] cachedSSID];
    } else {
        cell.textLabel.text = [self.wifiList objectAtIndex:indexPath.row];
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    [[PionOneManager sharedInstance] setCachedSSID:cell.textLabel.text];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.navigationController popViewControllerAnimated:YES];
    if (self.presentingVC) {
        [self.presentingVC showDialog];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"CONNECTED NETWORK";
    } else {
        return @"CHOUSE ANOTHER NETWORK...";
    }
    return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 40)];
    headerView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 15, tableView.bounds.size.width - 10, 20)];
    [headerView addSubview:label];
    if (section == 0) {
        label.text = @"CONNECTED NETWORK";
        label.font = [UIFont systemFontOfSize:14];
        label.textColor = [UIColor darkGrayColor];
    } else {
        label.text = @"CHOUSE ANOTHER NETWORK..";
        label.font = [UIFont systemFontOfSize:14];
        label.textColor = [UIColor darkGrayColor];
        UIActivityIndicatorView *refreshIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        refreshIndicator.hidesWhenStopped = YES;
        refreshIndicator.center = CGPointMake(self.tableView.frame.size.width - 30, 20);
        [headerView addSubview:refreshIndicator];
        self.refreshIndicator = refreshIndicator;
    }
    headerView.layer.shadowOffset = CGSizeMake(0, 0);
    headerView.layer.shadowColor = [[UIColor blackColor] CGColor];
    headerView.layer.shadowRadius = .5;
    headerView.layer.shadowOpacity = .25;
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 40;
}



- (IBAction)refresh {
    [self.refreshIndicator startAnimating];
    [[PionOneManager sharedInstance] getWiFiListWithCompletionHandler:^(BOOL success, NSString *msg) {
        if (success) {
            NSArray *wifiList = [[msg componentsSeparatedByString:@"\r\n"] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
            self.wifiList = [NSMutableArray arrayWithArray:wifiList];
            NSMutableArray *discardedItems = [NSMutableArray array];
            for (NSString *ssid in wifiList) {
                if (ssid.length == 0) {
                    [discardedItems addObject:ssid];
                }
            }
            [self.wifiList removeObjectsInArray:discardedItems];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
        } else {
            
        }
        [self.refreshIndicator stopAnimating];
    }];
}
@end
