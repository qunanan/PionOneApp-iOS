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

#define mSTR_RENAME_WIO_LINK @"Rename Wio Link"
#define mSTR_CHANGE_DATA_SERVER @"Change Data Server"
#define mSTR_TAKE_A_NAME_FOR_WIO_LINK @"Take a name for Wio Link"
#define mSTR_YOUR_DATA_SERVER_IP @"Your data server IP"

@interface NodeSettingTVC () <UITextFieldDelegate>
@property (nonatomic, strong) RETableViewManager *tvManager;
@property (nonatomic, strong) RETableViewItem *nameItem;
@property (nonatomic, strong) RETableViewItem *serverIPItem;
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

- (RETableViewItem *)serverIPItem {
    if (_serverIPItem == nil) {
        _serverIPItem = [RETableViewItem itemWithTitle:@"Data Server IP" accessoryType:UITableViewCellAccessoryDisclosureIndicator selectionHandler:^(RETableViewItem *item) {
            [item deselectRowAnimated:YES];
            self.textInputDialog.title = mSTR_CHANGE_DATA_SERVER;
            [[self.textInputDialog.textFields objectAtIndex:0] setPlaceholder:mSTR_YOUR_DATA_SERVER_IP];
            [[self.textInputDialog.textFields objectAtIndex:0] setText:nil];
            [[self.textInputDialog.actions objectAtIndex:1] setEnabled:NO];
            [self presentViewController:self.textInputDialog animated:YES completion:nil];
        }];
        _serverIPItem.style = UITableViewCellStyleValue1;

    }
    return _serverIPItem;
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
    NSString *defaultServerIP = [[NSUserDefaults standardUserDefaults] valueForKey:kPionOneDataServerIPAddress];

    BOOL dataServerChanged = self.node.dataServerIP != nil && ![self.node.dataServerIP isEqualToString:defaultServerIP];


    REBoolItem *dataServerSwitchItem = [REBoolItem itemWithTitle:@"Use Custom Data Server" value:dataServerChanged switchValueChangeHandler:^(REBoolItem *item) {
        if (item.value) {
            self.serverIPItem.detailLabelText = [[NSUserDefaults standardUserDefaults] valueForKey:kPionOneDataServerIPAddress];
            self.serverIPItem.style = UITableViewCellStyleValue1;
            [section2 addItem:self.serverIPItem];
            [section2 reloadSectionWithAnimation:UITableViewRowAnimationFade];
        } else {
            [self.HUD show:YES];
            [[PionOneManager sharedInstance] node:self.node setDataServerIP:defaultServerIP WithCompletionHandler:^(BOOL success, NSString *msg) {
                [self.HUD hide:YES];
                [section2 removeLastItem];
                if (!success) {
                    [self showAlertMsg:msg];
                }
                [section2 reloadSectionWithAnimation:UITableViewRowAnimationFade];
            }];
        }
    }];
    [section2 addItem:dataServerSwitchItem];

    if (dataServerChanged) {
        self.serverIPItem.detailLabelText = self.node.dataServerIP;
        [section2 addItem:self.serverIPItem];
    } else {
        self.serverIPItem.detailLabelText = [[NSUserDefaults standardUserDefaults] valueForKey:kPionOneDataServerIPAddress];
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
    NSString *ip = [[_textInputDialog.textFields objectAtIndex:0] text];
    if ([ip isIp]) {
        [self.HUD show:YES];
        [[PionOneManager sharedInstance] node:self.node setDataServerIP:ip WithCompletionHandler:^(BOOL success, NSString *msg) {
            [self.HUD hide:YES];
            if (success) {
                self.serverIPItem.detailLabelText = ip;
                [self.tableView reloadData];
            } else {
                [self showAlertMsg:msg];
            }
        }];
    } else {
        [self showAlertMsg:@"Bad IP address"];
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
