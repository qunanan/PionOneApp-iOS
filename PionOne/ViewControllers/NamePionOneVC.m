//
//  NamePionOneVC.m
//  PionOne
//
//  Created by Qxn on 15/9/5.
//  Copyright (c) 2015年 SeeedStudio. All rights reserved.
//

#import "NamePionOneVC.h"
#import "PionOneManager.h"
#import "TextFieldEffects-Swift.h"
#import "MBProgressHUD.h"

@interface NamePionOneVC () <UITextFieldDelegate>
@property (nonatomic, strong) MBProgressHUD *HUD;
@property (weak, nonatomic) IBOutlet HoshiTextField *nameTextField;
@end

@implementation NamePionOneVC

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.nameTextField.delegate = self;
    [self.nameTextField becomeFirstResponder];
}

#pragma -mark Properyies
- (MBProgressHUD *)HUD {
    if (_HUD == nil) {
        _HUD = [[MBProgressHUD alloc] initWithView:self.view];
        [self.view addSubview:_HUD];
    }
    return _HUD;
}

- (IBAction)done:(UIBarButtonItem *)sender {
    [self.nameTextField resignFirstResponder];
    [self.HUD show:YES];
    PionOneManager *manager = [PionOneManager sharedInstance];
    [manager setNodeName:self.nameTextField.text withNodeSN:manager.tmpNodeSN completionHandler:^(BOOL success, NSString *msg) {
        if (success) {
            [[PionOneManager sharedInstance] getNodeListWithCompletionHandler:^(BOOL succes, NSString *msg) {
                [self.HUD hide:YES];
                if (success) {
                    [[PionOneManager sharedInstance] setAPConfigurationDone:YES];
                    [self dismissViewControllerAnimated:YES completion:NULL];
                } else {
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                                        message:msg
                                                                       delegate:nil
                                                              cancelButtonTitle:@"Ok"
                                                              otherButtonTitles:nil];
                    [alertView show];
                    [self.nameTextField becomeFirstResponder];
                }
            }];
        } else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                                message:msg
                                                               delegate:nil
                                                      cancelButtonTitle:@"Ok"
                                                      otherButtonTitles:nil];
            [alertView show];
            [self.nameTextField becomeFirstResponder];
        }
    }];
}

#pragma mark -  TextFielDelegate methods
// when user tap Enter or Return
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.nameTextField) {
        [self done:nil];
    }
    return YES;
}

@end
