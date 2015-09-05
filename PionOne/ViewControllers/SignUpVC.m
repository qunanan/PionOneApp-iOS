//
//  SignUpVC.m
//  WiFi IoT Node
//
//  Created by Qxn on 15/7/28.
//  Copyright (c) 2015年 SeeedStudio. All rights reserved.
//

#import "SignUpVC.h"
#import "NSString+Email.h"
#import "PionOneManager.h"
#import "TextFieldEffects-Swift.h"

#import "WelcomeViewController.h"

@interface SignUpVC () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet HoshiTextField *emailTextField;
@property (weak, nonatomic) IBOutlet HoshiTextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicator;

@end

@implementation SignUpVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.emailTextField.delegate = self;
    self.passwordTextField.delegate = self;
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.emailTextField becomeFirstResponder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)cancel:(UIBarButtonItem *)sender {
    [self.emailTextField resignFirstResponder];
    [self.passwordTextField resignFirstResponder];
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)done {
    [self.emailTextField resignFirstResponder];
    [self.passwordTextField resignFirstResponder];
    [self.indicator startAnimating];
    
    [[PionOneManager sharedInstance] signUpWithEmail:self.emailTextField.text andPwd:self.passwordTextField.text completionHandler:^(BOOL succse, NSString *msg) {
        [self.indicator stopAnimating];
        if (succse) {
            WelcomeViewController *pVC = (WelcomeViewController *)self.presentingViewController;
            [self cancel:nil];
            [pVC login];
        } else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                                message:msg
                                                               delegate:nil
                                                      cancelButtonTitle:@"Ok"
                                                      otherButtonTitles:nil];
            [alertView show];
        }
    }];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark -  TextFielDelegate methods
// when user tap Enter or Return
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.emailTextField) {
        [self.passwordTextField becomeFirstResponder];
    } else if (textField == self.passwordTextField) {
        [self done];
    }
    return YES;
}


@end
