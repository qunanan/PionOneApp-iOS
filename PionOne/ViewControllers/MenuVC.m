
//
//  MenuVC.m
//  PionOne
//
//  Created by Qxn on 15/9/4.
//  Copyright (c) 2015年 SeeedStudio. All rights reserved.
//

#import "MenuVC.h"
#import "RESideMenu.h"
#import "PionOneManager.h"
#import "MBProgressHUD.h"
#import "NodeListCDTVC.h"
#import "wioLinkViews.h"

@interface MenuVC () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (strong, nonatomic) NSArray *menuList;
@property (strong, nonatomic) UIAlertController *changePasswordDialog;
//@property (strong, nonatomic) UIAlertController *shareDialog;
@property (nonatomic, strong) MBProgressHUD *HUD;

@end
@implementation MenuVC

- (NSArray *)menuList {
    if (_menuList == nil) {
        NSDictionary *menu1 = [NSDictionary dictionaryWithObjects:@[@"Groves",
                                                                    @"iconGrove",
                                                                    @"ShowDriverList"]
                                                          forKeys:@[kTitle,kIcon,kControllerID]];
        NSDictionary *menu2 = [NSDictionary dictionaryWithObjects:@[@"Password",
                                                                    @"iconAccount",
                                                                    @"ShowChangePassword"]
                                                          forKeys:@[kTitle,kIcon,kControllerID]];
        NSDictionary *menu3 = [NSDictionary dictionaryWithObjects:@[@"About",
                                                                    @"iconInfo",
                                                                    @"ShowAboutViewController"]
                                                          forKeys:@[kTitle,kIcon,kControllerID]];
        NSDictionary *menu4 = [NSDictionary dictionaryWithObjects:@[@"Share",
                                                                    @"iconShare",
                                                                    @"ShowShare"]
                                                          forKeys:@[kTitle,kIcon,kControllerID]];
        _menuList = [[NSArray alloc] initWithObjects:menu1, menu2, menu3, menu4, nil];
    }
    return _menuList;
}

- (UIAlertController *)changePasswordDialog {
    __typeof (&*self) __weak weakSelf = self;
    if (_changePasswordDialog == nil) {
        _changePasswordDialog = [UIAlertController alertControllerWithTitle:nil message:@"Change Your Password" preferredStyle:UIAlertControllerStyleAlert];
        [_changePasswordDialog addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:nil]];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self changePassword];
        }];
        okAction.enabled = NO;
        [_changePasswordDialog addAction:okAction];
        [_changePasswordDialog addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = @"New password";
            textField.secureTextEntry = YES;
            [textField setReturnKeyType:UIReturnKeyNext];
        }];
        [_changePasswordDialog addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = @"Confirm password";
            textField.secureTextEntry = YES;
            [textField setReturnKeyType:UIReturnKeyNext];
            textField.delegate = weakSelf;
            [textField addTarget:weakSelf action:@selector(textFieldDidChange) forControlEvents:UIControlEventEditingChanged];
        }];
    }
    return _changePasswordDialog;
}

- (MBProgressHUD *)HUD {
    if (_HUD == nil) {
        UITableViewController *controller = (UITableViewController *)self.sideMenuViewController.contentViewController;
        NSArray *controllers = [controller childViewControllers];
        NodeListCDTVC *nodeListVC = [controllers firstObject];;
        _HUD = nodeListVC.HUD;
    }
    return _HUD;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    NSString * version = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
    NSString * build = [[NSBundle mainBundle] objectForInfoDictionaryKey: (NSString *)kCFBundleVersionKey];
    NSString * versionBuild = [NSString stringWithFormat: @"v%@", version];
    
    if (![version isEqualToString: build]) {
        versionBuild = [NSString stringWithFormat: @"%@(%@)", versionBuild, build];
    }
    
    self.versionLabel.text = versionBuild;
}

- (IBAction)logout {
    NSString *email = [[NSUserDefaults standardUserDefaults] objectForKey:kPionOneUserEmail];
    UIAlertController *logoutAction = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Logged in as %@", email] message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [logoutAction addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [logoutAction addAction:[UIAlertAction actionWithTitle:@"Log Out" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [[PionOneManager sharedInstance] logout];
        UIWindow *window = [[[UIApplication sharedApplication] windows] firstObject];
        [UIView transitionWithView:window
                          duration:0.5
                           options:UIViewAnimationOptionTransitionFlipFromRight
                        animations:^{ window.rootViewController = [window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"WelcomeVC"]; }
                        completion:nil];
    }]];
    [self presentViewController:logoutAction animated:YES completion:nil];
}

- (IBAction)showDriverList {
    UITableViewController *controller = (UITableViewController *)self.sideMenuViewController.contentViewController;
    NSArray *controllers = [controller childViewControllers];
    UIViewController *nodeListVC = [controllers firstObject];;
    [nodeListVC performSegueWithIdentifier:@"ShowDriverList" sender:nil];
    [self.sideMenuViewController hideMenuViewController];
}

- (void)showChangePassword {
    
}
- (void)changePassword {
    UITextField *textField1 = [_changePasswordDialog.textFields objectAtIndex:0];
    UITextField *textField2 = [_changePasswordDialog.textFields objectAtIndex:1];
    if (![textField1.text isEqualToString:textField2.text]) {
        [[[UIAlertView alloc] initWithTitle:@"Error" message:@"The password confirmation is not match your new password." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
        return;
    }
    [self.HUD show:YES];
    [[PionOneManager sharedInstance] changePasswordWithNewPassword:textField1.text completionHandler:^(BOOL success, NSString *msg) {
        if (!success) {
            [[[UIAlertView alloc] initWithTitle:@"Info" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
        }
        [self.HUD hide:YES];
    }];
}
- (void)share {
    
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MenuButtonCell" forIndexPath:indexPath];
    UIImageView *icon = [cell.contentView viewWithTag:21];
    UILabel *name = [cell.contentView viewWithTag:22];
    if (indexPath.section == 0) {
        NSDictionary *menu = [self.menuList objectAtIndex:indexPath.row];
        name.text = [menu objectForKey:kTitle];
        icon.image = [UIImage imageNamed:[menu objectForKey:kIcon]];
    } else {
        name.text = @"Logout";
        icon.image = [UIImage imageNamed:@"iconLogout"];
    }
    [cell setSelected:NO];
    UIView *bgColorView = [[UIView alloc] init];
    bgColorView.backgroundColor = [wioLinkViews wioLinkBlue];
    [cell setSelectedBackgroundView:bgColorView];
    return cell;
}

- (void)tableView:tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        NSDictionary *menu = [self.menuList objectAtIndex:indexPath.row];
        NSString *vcID = [menu objectForKey:kControllerID];
        if ([vcID isEqualToString:@"ShowChangePassword"]) {
            for (UITextField *tf in self.changePasswordDialog.textFields) {
                tf.text = nil;
            }
            [self presentViewController:self.changePasswordDialog animated:YES completion:nil];;
        } else if ([vcID isEqualToString:@"ShowShare"]) {
            UIImage *shareImage = [UIImage imageNamed:@"shareImage"];
            [self shareText:@"Wio Link - 3 Step. 5 Minutes. Build Your Own IoT Applications!" andImage:shareImage andUrl:[NSURL URLWithString:@"http://iot.seeed.cc"]];
           // [self presentViewController:self.shareDialog animated:YES completion:nil];;
        } else {
            UINavigationController *controller = (UINavigationController *)self.sideMenuViewController.contentViewController;
            NSArray *controllers = [controller childViewControllers];
            UIViewController *nodeListVC = [controllers firstObject];;
            [nodeListVC performSegueWithIdentifier:vcID sender:nil];
        }
    } else {
        [self logout];
    }
    [[tableView cellForRowAtIndexPath:indexPath] setSelected:NO animated:YES];
    [self.sideMenuViewController hideMenuViewController];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *footerview = [UIView new];
    footerview.hidden = YES;
    return footerview;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return self.menuList.count;
            break;
        case 1:
            return 1;
        default:
            break;
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 80;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return [UIScreen mainScreen].applicationFrame.size.height - 80*2 - 80*self.menuList.count;
            break;
        case 1:
            return 10;
        default:
            break;
    }
    return 10;
}

#pragma mark -  TextFielDelegate methods
// when user tap Enter or Return
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField.text.length == 0) {
        return NO;
    }
    [self changePassword];
    [self.changePasswordDialog dismissViewControllerAnimated:YES completion:nil];
    return YES;
}
- (void)textFieldDidChange {
    UITextField *textField1 = [_changePasswordDialog.textFields objectAtIndex:0];
    UITextField *textField2 = [_changePasswordDialog.textFields objectAtIndex:1];
    if (textField1.text.length < 4 || textField2.text.length < 4 ) {
        [_changePasswordDialog.actions objectAtIndex:1].enabled = NO;
    } else {
        [_changePasswordDialog.actions objectAtIndex:1].enabled = YES;
    }
}

- (void)shareText:(NSString *)text andImage:(UIImage *)image andUrl:(NSURL *)url
{
    NSMutableArray *sharingItems = [NSMutableArray new];
    
    if (text) {
        [sharingItems addObject:text];
    }
    if (image) {
        [sharingItems addObject:image];
    }
    if (url) {
        [sharingItems addObject:url];
    }
    
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:sharingItems applicationActivities:nil];
    [self presentViewController:activityController animated:YES completion:nil];
}

@end
