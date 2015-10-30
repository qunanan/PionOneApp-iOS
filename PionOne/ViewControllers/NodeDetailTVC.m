//
//  NodeDetailTVC.m
//  PionOne
//
//  Created by Qxn on 15/9/13.
//  Copyright © 2015年 SeeedStudio. All rights reserved.
//

#import "NodeDetailTVC.h"
#import <RETableViewManager/RETableViewManager.h>
#import "PionOneManager.h"
#import "NodeResourcesVC.h"
#import "MultilineTextItem.h"
#import "NodeAPI.h"
#import "ListImageItem.h"
#import "UIImage+MDQRCode.h"


@interface NodeDetailTVC ()
@property (nonatomic, strong) RETableViewManager *tvManager;
@property (nonatomic, strong) RETextItem *nameItem;
@property (nonatomic, strong) NSMutableArray *nodeAPIs;
@end
@implementation NodeDetailTVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    __typeof (&*self) __weak weakSelf = self;
    self.tvManager = [[RETableViewManager alloc] initWithTableView:self.tableView];
    self.tvManager[@"MultilineTextItem"] = @"MultilineTextCell";
    self.tvManager[@"ListImageItem"] = @"ListImageCell"; // which is the same as [self.manager registerClass:@"ListImageItem" forCellWithReuseIdentifier:@"ListImageCell"];

    RETableViewSection *section = [RETableViewSection section];
    section.footerTitle = @" ";
    [self.tvManager addSection:section];
    [section addItem:[NSString stringWithFormat:@"Name    %@", self.node.name]];
    
    section = [RETableViewSection sectionWithHeaderTitle:@"Recources"];
    section.footerTitle = @" ";
    [self.tvManager addSection:section];
    RETableViewItem *item = [RETableViewItem itemWithTitle:@"Web Page" accessoryType:UITableViewCellAccessoryNone selectionHandler:^(RETableViewItem *item) {
        [item deselectRowAnimated:YES]; // same as [weakSelf.tableView deselectRowAtIndexPath:item.indexPath animated:YES];
    }];
    item.style = UITableViewCellStyleSubtitle;
    item.detailLabelText = @"Long tap to copy the url";
    item.cellHeight = 55.0;
    MultilineTextItem *urlItem = [MultilineTextItem itemWithTitle:self.node.apiURL];
    urlItem.copyHandler = ^(id item){
        [UIPasteboard generalPasteboard].string = self.node.apiURL;
    };
    UIImage *qrImage = [UIImage mdQRCodeForString:self.node.apiURL size:100];
    ListImageItem *imageItem = [ListImageItem itemWithImage:qrImage];
    imageItem.copyHandler = ^(id item){
        [UIPasteboard generalPasteboard].string = self.node.apiURL;
    };
    imageItem.selectionHandler = ^(ListImageItem *item) {
        [item deselectRowAnimated:YES]; // same as [weakSelf.tableView deselectRowAtIndexPath:item.indexPath animated:YES];
    };
    
    [section addItem:item];
    [section addItem:urlItem];
    [section addItem:imageItem];
    
    
    [[PionOneManager sharedInstance] getAPIsForNode:self.node completion:^(BOOL success, NSString *msg, NSArray *apis) {
        if (success) {
            self.nodeAPIs = [NSMutableArray arrayWithArray:apis];
            [self setupNodeAPIs:nil];
        }
    }];

}

- (void)setupNodeAPIs:(NSArray *)apis {
    for (NodeAPI *api in self.nodeAPIs) {
        RETableViewSection *apiSection = [RETableViewSection sectionWithHeaderTitle:@" "];
        apiSection.headerHeight = 20.0;
        if ([api isEqual:self.nodeAPIs.firstObject]) {
            apiSection.headerTitle = @"API TEST";
            apiSection.headerHeight = 40.0;
        }
        MultilineTextItem *urlItem = [MultilineTextItem itemWithTitle:api.url];
        urlItem.copyHandler = ^(id item){
            [UIPasteboard generalPasteboard].string = api.url;
        };
        [apiSection addItem:urlItem];
        [apiSection addItem:@"Arguments:"];
        if ([api.type isEqualToString:@"Event"]) {
            break;
        }
        for (NodeAPIArg *arg in api.args) {
            RETextItem *argItem =[RETextItem itemWithTitle:[@"  " stringByAppendingString:arg.name] value:nil placeholder:arg.type];
            arg.value = argItem.value;
            arg.boundItem = argItem;
            argItem.onEndEditing = ^(RETextItem *item) {
                arg.value = item.value;
            };
            [apiSection addItem:argItem];
        }
        RETableViewItem *buttonItem = [RETableViewItem itemWithTitle:api.type accessoryType:UITableViewCellAccessoryNone selectionHandler:^(RETableViewItem *item) {
            [api callAPIWhitCompletionHandler:^(BOOL success) {
                if (success) {
                    [apiSection reloadSectionWithAnimation:UITableViewRowAnimationAutomatic];
                } else {
                }
                [item deselectRowAnimated:YES];
            }];
        }];
        buttonItem.textAlignment = NSTextAlignmentCenter;
        [apiSection addItem:buttonItem];
        [self.tvManager addSection:apiSection];
        [self.tableView reloadData];
    }
}

- (void)changeNodeName:(RETextItem *)item {
    if ([item.value isEqualToString:self.node.name]) {
        return;
    }
    if ([item.value isEqualToString:@""]) {
        item.value = self.node.name;
        [self.tableView reloadData];
        return;
    }
    [[PionOneManager sharedInstance] renameNode:self.node withName:item.value completionHandler:nil];
}

@end
