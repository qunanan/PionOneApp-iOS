//
//  SignInVC.m
//  WiFi IoT Node
//
//  Created by Qxn on 15/7/29.
//  Copyright (c) 2015年 SeeedStudio. All rights reserved.
//

#import "SignInVC.h"
#import "NSString+Email.h"
#import "PionOneManager.h"
#import "TextFieldEffects-Swift.h"
#import "WelcomeViewController.h"

@interface SignInVC () <UITextFieldDelegate, UIActionSheetDelegate>
@property (weak, nonatomic) IBOutlet HoshiTextField *emailTextField;
@property (weak, nonatomic) IBOutlet HoshiTextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicator;
@property (weak, nonatomic) IBOutlet UILabel *regionLabel;

@end

@implementation SignInVC


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.tintColor = self.navigationItem.rightBarButtonItem.tintColor;
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];

}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.emailTextField.delegate = self;
    self.passwordTextField.delegate = self;
    
    self.regionLabel.text = [[NSUserDefaults standardUserDefaults] valueForKey:kPionOneServerRegion];
}



- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.emailTextField becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
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
    
    [[PionOneManager sharedInstance] signInWithEmail:self.emailTextField.text andPwd:self.passwordTextField.text completionHandler:^(BOOL succse, NSString *msg) {
        [self.indicator stopAnimating];
        if (succse) {
                    WelcomeViewController *pVC = (WelcomeViewController *)self.presentingViewController;
                    [self cancel:nil];
                    [pVC login];
        } else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Sorry"
                                                                message:@"We had a problem doing this for you, maybe you can change the region for better internet connection."
                                                               delegate:nil
                                                      cancelButtonTitle:@"Ok"
                                                      otherButtonTitles:nil];
            [alertView show];
        }
    }];
}
- (IBAction)switchRegion {
    [self.emailTextField resignFirstResponder];
    [self.passwordTextField resignFirstResponder];
    UIActionSheet *action = [[UIActionSheet alloc] initWithTitle:@"Select region"
                                                        delegate:self
                                               cancelButtonTitle:@"Cancel"
                                          destructiveButtonTitle:nil
                                               otherButtonTitles:@"International", @"China", @"Custom", nil];
    [action showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
            //International
            self.regionLabel.text = PionOneRegionNameInternational;
            [[PionOneManager sharedInstance] setRegion:PionOneRegionNameInternational
                                           OTAServerIP:PionOneDefaultOTAServerIPAddressInternational
                                        andDataSeverIP:PionOneDefaultDataServerIPAddressInternational];
            break;
        case 1:
            //China
            self.regionLabel.text = PionOneRegionNameChina;
            [[PionOneManager sharedInstance] setRegion:PionOneRegionNameChina
                                           OTAServerIP:PionOneDefaultOTAServerIPAddressChina
                                        andDataSeverIP:PionOneDefaultDataServerIPAddressChina];
            break;
        case 2:
            //Custom
            self.regionLabel.text = PionOneRegionNameCustom;
            [self performSegueWithIdentifier:@"ShowSetupCustomServerIPSegue" sender:nil];
            break;

        default:
            break;
    }
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
