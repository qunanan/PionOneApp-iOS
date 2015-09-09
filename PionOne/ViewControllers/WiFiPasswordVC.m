//
//  WiFiPasswordVC.m
//  PionOne
//
//  Created by Qxn on 15/9/5.
//  Copyright (c) 2015年 SeeedStudio. All rights reserved.
//

#import "WiFiPasswordVC.h"
#import "PionOneManager.h"
#import "APConfigGuideVC.h"
#import "TextFieldEffects-Swift.h"

@interface WiFiPasswordVC () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet HoshiTextField *nodeNameTextField;
@property (weak, nonatomic) IBOutlet UILabel *ssidLabel;
@property (weak, nonatomic) IBOutlet HoshiTextField *passwordTextField;
@end

@implementation WiFiPasswordVC
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    //[self setModalPresentationStyle:UIModalPresentationCurrentContext];
    self.ssidLabel.text = [NSString stringWithFormat:@"SSID: %@",[[PionOneManager sharedInstance] cachedSSID]];
    self.passwordTextField.delegate = self;
    self.nodeNameTextField.delegate = self;
    [self.passwordTextField becomeFirstResponder];
}

#pragma -mark Actions
- (IBAction)done:(UIBarButtonItem *)sender {
    if ([self.nodeNameTextField.text length] == 0) {
        [[[UIAlertView alloc] initWithTitle:nil
                                    message:@"Name should not be nil"
                                   delegate:self
                          cancelButtonTitle:@"OK"
                         otherButtonTitles:nil] show];
        return;
    }
    [self.passwordTextField resignFirstResponder];
    [[PionOneManager sharedInstance] setCachedPassword:self.passwordTextField.text];
    [[PionOneManager sharedInstance] setCachedNodeName:self.nodeNameTextField.text];
    [self dismissViewControllerAnimated:YES completion:NULL];
    if ([self.presentingVC isKindOfClass:[APConfigGuideVC class]]) {
        [self.presentingVC startConfiguration];
    }
}

- (IBAction)cancel:(UIBarButtonItem *)sender {
    [self.nodeNameTextField resignFirstResponder];
    [self.passwordTextField resignFirstResponder];
    [self dismissViewControllerAnimated:YES completion:NULL];
    if ([self.presentingVC isKindOfClass:[APConfigGuideVC class]]) {
        [self.presentingVC cancelConfiguration];
    }
}

#pragma mark -  TextFielDelegate methods
// when user tap Enter or Return
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.passwordTextField) {
        [self.nodeNameTextField becomeFirstResponder];
    }
    if (textField == self.nodeNameTextField) {
        [self done:nil];
    }
    return YES;
}

@end
