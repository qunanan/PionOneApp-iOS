//
//  WiFiPasswordVC.m
//  PionOne
//
//  Created by Qxn on 15/9/5.
//  Copyright (c) 2015年 SeeedStudio. All rights reserved.
//

#import "WiFiPasswordVC.h"
#import "PionOneManager.h"
#import "TextFieldEffects-Swift.h"

@interface WiFiPasswordVC () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UILabel *ssidLabel;
@property (weak, nonatomic) IBOutlet HoshiTextField *passwordTextField;
@end

@implementation WiFiPasswordVC
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.ssidLabel.text = [NSString stringWithFormat:@"SSID: %@",[[PionOneManager sharedInstance] cachedSSID]];
    self.passwordTextField.delegate = self;
    [self.passwordTextField becomeFirstResponder];
}

#pragma -mark Actions
- (IBAction)done:(UIBarButtonItem *)sender {
    [self.passwordTextField resignFirstResponder];
    [[PionOneManager sharedInstance] setCachedPassword:self.passwordTextField.text];
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark -  TextFielDelegate methods
// when user tap Enter or Return
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.passwordTextField) {
        [self done:nil];
    }
    return YES;
}

@end
