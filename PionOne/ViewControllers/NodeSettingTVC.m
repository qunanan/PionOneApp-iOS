//
//  NodeSettingTVC.m
//  Wio Link
//
//  Created by Qxn on 15/12/21.
//  Copyright © 2015年 SeeedStudio. All rights reserved.
//

#import "NodeSettingTVC.h"
#import <RETableViewManager/RETableViewManager.h>
#import "PionOneManager.h"
#import "MBProgressHUD.h"
#import "NSString+Email.h"

#define mSTR_RENAME_WIO_LINK @"Rename Wio Device"
#define mSTR_CHANGE_DATA_SERVER @"Change Exchange Server"
#define mSTR_TAKE_A_NAME_FOR_WIO_LINK @"Take a name for Wio Device"
#define mSTR_YOUR_DATA_SERVER_URL @"Your Exchange server URL"

@interface NodeSettingTVC () <UITextFieldDelegate>
@property (nonatomic, strong) RETableViewManager *tvManager;
@property (nonatomic, strong) RETableViewItem *nameItem;
@property (nonatomic, strong) RETableViewItem *serverURLItem;
@property (strong, nonatomic) UIAlertController *textInputDialog;
@property (nonatomic, strong) MBProgressHUD *HUD;

@end

@implementation NodeSettingTVC

- (UIAlertController *)textInputDialog {
    __typeof (&*self) __weak weakSelf = self;
    if (_textInputDialog == nil) {
        _textInputDialog = [UIAlertController alertControllerWithTitle:@"Title" message:nil preferredStyle:UIAlertControllerStyleAlert];
        [_textInputDialog addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:nil]];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self okButtonPushed];
        }];
        okAction.enabled = NO;
        [_textInputDialog addAction:okAction];
        [_textInputDialog addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = @"Place Holder";
            textField.secureTextEntry = NO;
            [textField setReturnKeyType:UIReturnKeyGo];
            textField.delegate = weakSelf;
            [textField addTarget:weakSelf action:@selector(textFieldDidChange) forControlEvents:UIControlEventEditingChanged];
        }];
    }
    return _textInputDialog;
}
- (MBProgressHUD *)HUD {
    if (_HUD == nil) {
        _HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
        [self.navigationController.view addSubview:_HUD];
    }
    return _HUD;
}

- (RETableViewItem *)serverURLItem {
    if (_serverURLItem == nil) {
        _serverURLItem = [RETableViewItem itemWithTitle:@"Exchange Server URL" accessoryType:UITableViewCellAccessoryDisclosureIndicator selectionHandler:^(RETableViewItem *item) {
            [item deselectRowAnimated:YES];
            self.textInputDialog.title = mSTR_CHANGE_DATA_SERVER;
            NSString *defaultURLStr = [[NSUserDefaults standardUserDefaults] valueForKey:kPionOneDataServerBaseURL];
            [[self.textInputDialog.textFields objectAtIndex:0] setPlaceholder:mSTR_YOUR_DATA_SERVER_URL];
            [[self.textInputDialog.textFields objectAtIndex:0] setText:self.node.dataServerURL? self.node.dataServerURL:defaultURLStr];
            [[self.textInputDialog.actions objectAtIndex:1] setEnabled:NO];
            [self presentViewController:self.textInputDialog animated:YES completion:nil];
        }];
        _serverURLItem.style = UITableViewCellStyleValue1;

    }
    return _serverURLItem;
}
                         
- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.tableFooterView = [UIView new];
    
//    __typeof (&*self) __weak weakSelf = self;
    self.tvManager = [[RETableViewManager alloc] initWithTableView:self.tableView];
    
    RETableViewSection *section = [RETableViewSection section];
    section.headerTitle = @"";
    section.headerHeight = 20.0;
    section.footerTitle = @"";
    [self.tvManager addSection:section];
    self.nameItem = [[RETableViewItem alloc] initWithTitle:@"Name" accessoryType:UITableViewCellAccessoryDisclosureIndicator selectionHandler:^(RETableViewItem *item) {
        self.textInputDialog.title = mSTR_RENAME_WIO_LINK;
        [[self.textInputDialog.textFields objectAtIndex:0] setPlaceholder:mSTR_TAKE_A_NAME_FOR_WIO_LINK];
        [[self.textInputDialog.textFields objectAtIndex:0] setText:nil];
        [[self.textInputDialog.actions objectAtIndex:1] setEnabled:NO];
        [self presentViewController:self.textInputDialog animated:YES completion:nil];
        [item deselectRowAnimated:YES];
    }];
    self.nameItem.detailLabelText = self.node.name;
    self.nameItem.style = UITableViewCellStyleValue1;
    [section addItem:self.nameItem];

    RETableViewSection *section2 = [RETableViewSection section];
    section2.headerTitle = @"";
    section2.headerHeight = 20.0;
    NSString *defaultServerURL = [[NSUserDefaults standardUserDefaults] valueForKey:kPionOneDataServerBaseURL];
    NSURL *dsURL = [NSURL URLWithString:defaultServerURL];
    BOOL dataServerChanged = self.node.dataServerURL != nil && ![self.node.dataServerURL isEqualToString:defaultServerURL];


    REBoolItem *dataServerSwitchItem = [REBoolItem itemWithTitle:@"Use Custom Exchange Server" value:dataServerChanged switchValueChangeHandler:^(REBoolItem *item) {
        if (item.value) {
            self.serverURLItem.detailLabelText = [[NSUserDefaults standardUserDefaults] valueForKey:kPionOneDataServerBaseURL];
            self.serverURLItem.style = UITableViewCellStyleValue1;
            [section2 addItem:self.serverURLItem];
            [section2 reloadSectionWithAnimation:UITableViewRowAnimationFade];
        } else {
            [self.HUD show:YES];
            NSString *dataIPStr = [[PionOneManager sharedInstance] lookupIPAddressForHostName:dsURL.host];
            [[PionOneManager sharedInstance] node:self.node setDataServerIP:dataIPStr url:defaultServerURL WithCompletionHandler:^(BOOL success, NSString *msg) {
                [self.HUD hide:YES];
                [section2 removeLastItem];
                if (!success) {
                    [self showAlertMsg:msg];
                } else {
                    self.node.dataServerURL = defaultServerURL;
                }
                [section2 reloadSectionWithAnimation:UITableViewRowAnimationFade];
            }];
        }
    }];
    [section2 addItem:dataServerSwitchItem];

    if (dataServerChanged) {
        self.serverURLItem.detailLabelText = self.node.dataServerURL;
        [section2 addItem:self.serverURLItem];
    } else {
        self.serverURLItem.detailLabelText = [[NSUserDefaults standardUserDefaults] valueForKey:kPionOneDataServerIPAddress];
    }

    [self.tvManager addSection:section2];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)renameNode {
    NSString *name = [[_textInputDialog.textFields objectAtIndex:0] text];
    [self.HUD show:YES];
    [[PionOneManager sharedInstance] renameNode:self.node withName:name completionHandler:^(BOOL success, NSString *msg) {
        [self.HUD hide:YES];
        if (success) {
            self.nameItem.detailLabelText = name;
            [self.tableView reloadData];
        } else {
            [self showAlertMsg:msg];
        }
    }];
}

- (void)changeDataServer {
    NSString *urlStr = [[_textInputDialog.textFields objectAtIndex:0] text];
    if ([urlStr isUrl]) {
        NSURL *url = [NSURL URLWithString:urlStr];
        NSString *ip = [[PionOneManager sharedInstance] lookupIPAddressForHostName:url.host];
        if ([ip isIp] || [urlStr isUrl]) {
            [self.HUD show:YES];
            [[PionOneManager sharedInstance] node:self.node setDataServerIP:ip url:urlStr WithCompletionHandler:^(BOOL success, NSString *msg) {
                [self.HUD hide:YES];
                if (success) {
                    self.node.dataServerURL = urlStr;
                    self.serverURLItem.detailLabelText = urlStr;
                    [self.tableView reloadData];
                } else {
                    [self showAlertMsg:msg];
                }
            }];
        } else {
            [self showAlertMsg:@"Bad Server URL"];
        }
    } else {
        [self showAlertMsg:@"Bad Server URL"];
    }
}

- (void)okButtonPushed {
    if ([_textInputDialog.title isEqualToString:mSTR_RENAME_WIO_LINK]) {
        [self renameNode];
    } else if ([_textInputDialog.title isEqualToString:mSTR_CHANGE_DATA_SERVER]) {
        [self changeDataServer];
    }
}
#pragma mark -  TextFielDelegate methods
// when user tap Enter or Return
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField.text.length == 0) {
        return NO;
    }
    [self okButtonPushed];
    [self.textInputDialog dismissViewControllerAnimated:YES completion:nil];
    return YES;
}
- (void)textFieldDidChange {
    UITextField *textField = [_textInputDialog.textFields objectAtIndex:0];
    if (textField.text.length == 0) {
        [_textInputDialog.actions objectAtIndex:1].enabled = NO;
    } else {
        [_textInputDialog.actions objectAtIndex:1].enabled = YES;
    }
}

- (void)showAlertMsg:(NSString *)msg {
    UIAlertView *alart = [[UIAlertView alloc] initWithTitle:@"Failed"
                                                    message:msg delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    alart.opaque = NO;
    [alart show];
}

@end
