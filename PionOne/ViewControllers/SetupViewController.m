//
//  SetupViewController.m
//  PionOne
//
//  Created by Qxn on 15/10/16.
//  Copyright © 2015年 SeeedStudio. All rights reserved.
//

#import "SetupViewController.h"
#import "TextFieldEffects-Swift.h"
#import "PionOneManager.h"
#import "NSString+Email.h"
#import "MBProgressHUD.h"

@interface SetupViewController () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet HoshiTextField *serverURL;
@property (weak, nonatomic) IBOutlet HoshiTextField *dataServerIP;
@property (nonatomic, strong) MBProgressHUD *HUD;

@end

@implementation SetupViewController
#pragma -mark property
- (MBProgressHUD *)HUD {
    if (_HUD == nil) {
        _HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
        _HUD.dimBackground = YES;
        [self.navigationController.view addSubview:_HUD];
    }
    return _HUD;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.dataServerIP.delegate = self;
    self.dataServerIP.hidden = YES;

    self.serverURL.delegate = self;
    
    self.serverURL.text = [[NSUserDefaults standardUserDefaults] objectForKey:kPionOneOTAServerBaseURL];
    [self.serverURL becomeFirstResponder];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.tintColor = self.navigationItem.rightBarButtonItem.tintColor;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (IBAction)done:(UIBarButtonItem *)sender {
    [self.serverURL resignFirstResponder];
    NSURL *url = [NSURL URLWithString:self.serverURL.text];
    if (url && url.scheme && url.host) {
        [self.HUD show:YES];
        [[PionOneManager sharedInstance] checkBaseURL:url complete:^(BOOL success, NSString *msg) {
            if (success) {
                [[PionOneManager sharedInstance] setRegion:PionOneRegionNameCustom serverURL:self.serverURL.text];
                [self.navigationController popViewControllerAnimated:YES];
            } else {
                [[[UIAlertView alloc] initWithTitle:nil message:@"Please input a valid url" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
            }
            [self.HUD hide:YES];
        }];
    } else {
        [[[UIAlertView alloc] initWithTitle:nil message:@"Please input a valid url" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
    }
}

#pragma -mark UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self done:nil];
    return YES;
}


@end
