//
//  RetrievePasswordVC.m
//  PionOne
//
//  Created by Qxn on 15/9/4.
//  Copyright (c) 2015年 SeeedStudio. All rights reserved.
//

#import "RetrievePasswordVC.h"
#import "PionOneManager.h"
#import "TextFieldEffects-Swift.h"
#import "MBProgressHUD.h"

@interface RetrievePasswordVC() <UITextFieldDelegate>
@property (nonatomic, strong) MBProgressHUD *HUD;
@property (weak, nonatomic) IBOutlet HoshiTextField *emailTextField;
@end
@implementation RetrievePasswordVC

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.emailTextField.delegate = self;
    [self.emailTextField becomeFirstResponder];
}

#pragma -mark Properyies
- (MBProgressHUD *)HUD {
    if (_HUD == nil) {
        _HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
        [self.navigationController.view addSubview:_HUD];
    }
    return _HUD;
}

- (IBAction)done:(UIBarButtonItem *)sender {
    [self.emailTextField resignFirstResponder];
    [self.HUD show:YES];
    [[PionOneManager sharedInstance] retrievePwdForAccount:self.emailTextField.text completionHandler:^(BOOL succes, NSString *msg) {
        [self.HUD hide:YES];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                            message:msg
                                                           delegate:nil
                                                  cancelButtonTitle:@"Ok"
                                                  otherButtonTitles:nil];
        [alertView show];
        if (!succes) {
            [self.emailTextField becomeFirstResponder];
        }
    }];
}

#pragma mark -  TextFielDelegate methods
// when user tap Enter or Return
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.emailTextField) {
        [self done:nil];
    }
    return YES;
}

@end
