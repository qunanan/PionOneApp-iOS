//
//  StartAPConfigVC.m
//  PionOne
//
//  Created by Qxn on 15/9/5.
//  Copyright (c) 2015年 SeeedStudio. All rights reserved.
//

#import "PrepareAPConfigVC.h"
#import "PionOneManager.h"
#import "KHFlatButton.h"
#import "MBProgressHUD.h"
#import "TextFieldEffects-Swift.h"
#import "WiFiListTVC.h"

@interface PrepareAPConfigVC () <UITextFieldDelegate, UIAlertViewDelegate>
@property (strong, nonatomic) MBProgressHUD *progressHUD;
@property (strong, nonatomic) UIAlertController *userInputDialog;
@property (assign, nonatomic) BOOL isPreparedPionOne;

//@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicator;
@property (weak, nonatomic) IBOutlet KHFlatButton *button;
@end

@implementation PrepareAPConfigVC
- (MBProgressHUD *)progressHUD {
    if (_progressHUD == nil) {
        _progressHUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
        [self.navigationController.view addSubview:_progressHUD];
        _progressHUD.dimBackground = YES;
    }
    return _progressHUD;
}

- (UIAlertController *)userInputDialog {
    __typeof (&*self) __weak weakSelf = self;
    if (_userInputDialog == nil) {
        NSString *ssid = [[PionOneManager sharedInstance] cachedSSID];
        _userInputDialog = [UIAlertController alertControllerWithTitle:@"Join Network" message:[NSString stringWithFormat:@"SSID:%@",ssid] preferredStyle:UIAlertControllerStyleAlert];
        [_userInputDialog addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:nil]];
        UIAlertAction *joinAction = [UIAlertAction actionWithTitle:@"Join" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self startConfiguration];
        }];
        joinAction.enabled = NO;
        [_userInputDialog addAction:joinAction];
        [_userInputDialog addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = @"Enter SSID Password";
            textField.secureTextEntry = NO;
            [textField addTarget:weakSelf action:@selector(textFieldDidChange) forControlEvents:UIControlEventEditingChanged];
        }];
        [_userInputDialog addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = @"Enter A Name For Your Wio Link";
            textField.secureTextEntry = NO;
            [textField setReturnKeyType:UIReturnKeyJoin];
            textField.delegate = weakSelf;
            [textField addTarget:weakSelf action:@selector(textFieldDidChange) forControlEvents:UIControlEventEditingChanged];
        }];
    }
    return _userInputDialog;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    [self registerAPconfigLocalNotification];
    NSArray *viewControllers = self.navigationController.viewControllers;
    if (viewControllers.count > 1 && [viewControllers objectAtIndex:viewControllers.count-2] == self) {
        // View is disappearing because a new view controller was pushed onto the stack
        NSLog(@"New view controller was pushed");
    } else if ([viewControllers indexOfObject:self] == NSNotFound) {
        // View is disappearing because it was popped from the stack
        NSLog(@"View controller was popped");
        [[PionOneManager sharedInstance] deleteZombieNodeWithCompletionHandler:nil];
    }

    if (![[PionOneManager sharedInstance] isConnectedToPionOne]) {
        [self startCheckingNodeAPConnection];
    }
    
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[PionOneManager sharedInstance] cancel]; //cancel all processing, include Checking Node AP connection
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
}

- (IBAction)gotReady {
    BOOL isConnected = [[PionOneManager sharedInstance] isConnectedToPionOne];
    if (isConnected) {
        [[PionOneManager sharedInstance] setAPConfigurationDone:NO];
        [self prepareSetup];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Connect Wio Link"
                                   message:@"Please go to Settings and connect the WioLink_XXXX Network."
                                  delegate:self
                         cancelButtonTitle:@"Cancel"
                          otherButtonTitles:@"OK", nil] show];
    }
}

- (void)startCheckingNodeAPConnection {
    [[PionOneManager sharedInstance] checkIfConnectedToPionOneWithCompletionHandler:^(BOOL success, NSString *msg) {
        if (success) {
            UILocalNotification *notification = [[UILocalNotification alloc] init];
            if (notification) {
                notification.soundName = UILocalNotificationDefaultSoundName;
                notification.alertBody = @"Connected a Wio Link!";
                [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                [NSThread sleepForTimeInterval:1.0];
                [self gotReady];
            }
        }
        else {
            NSLog(@"Stopped checking SSID.");
        }
    }];
}

- (void)showDialog {
    [[_userInputDialog.actions objectAtIndex:1] setEnabled:NO];
    NSString *ssid = [[PionOneManager sharedInstance] cachedSSID];
    self.userInputDialog.message = [NSString stringWithFormat:@"SSID:%@",ssid];
    [self presentViewController:self.userInputDialog animated:YES completion:nil];
}

- (void)prepareSetup {
    [self.progressHUD show:YES];
    [[PionOneManager sharedInstance] getNodeVersionWithCompletionHandler:^(BOOL success, NSString *msg) {
        [self.progressHUD hide:YES];
        if (msg.floatValue > 1.0) {
            NSLog(@"go to select wifi list vc.");
            [self performSegueWithIdentifier:@"showWiFiList" sender:nil];
        } else {
            [self showDialog];
        }
    }];
}

- (void)startConfiguration {

    if (_userInputDialog.textFields.count >= 2) {
        UITextField *passwordTextField = [_userInputDialog.textFields objectAtIndex:0];
        UITextField *nameTextField = [_userInputDialog.textFields objectAtIndex:1];
        [[PionOneManager sharedInstance] setCachedPassword:passwordTextField.text];
        [[PionOneManager sharedInstance] setCachedNodeName:nameTextField.text];
    }

    PionOneManager *manager = [PionOneManager sharedInstance];
    if (manager.cachedNodeName && manager.cachedPassword) {
        [manager startAPConfigWithProgressHandler:^(BOOL success, NSInteger step, NSString *msg) {
            if (success) {
                switch (step) {
                    case 1:
                        //connecting wifi
                        self.progressHUD.labelText = @"Connecting WiFi...";
                        [self.progressHUD show:YES];
                        self.progressHUD.animationType = MBProgressHUDModeDeterminate;
                        
                        break;
                    case 2:
                        //connecting server
                        self.progressHUD.labelText = @"Connecting Server...";
                        break;
                    case 3:
                        //rename device
                        self.progressHUD.labelText = @"Setup Device...";
                        break;
                    case 4:
                        //done
                        self.progressHUD.labelText = @"Done";
                        [self configurationgDone];
                        break;
                    default:
                        break;
                }
            } else {
                [self showAlertMsg:msg];
                [self cancelConfiguration];
            }
        }];
    }
}

- (void)cancelConfiguration {
    PionOneManager *manager = [PionOneManager sharedInstance];
    manager.APConfigurationDone = NO;
    [manager cancel];
    [self.progressHUD hide:YES];
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)configurationgDone {
    [self.progressHUD hide:YES];
    PionOneManager *manager = [PionOneManager sharedInstance];
    manager.APConfigurationDone = NO;
    manager.cachedPassword = nil;
    [[[UIAlertView alloc] initWithTitle:@"Success!" message:nil delegate:self cancelButtonTitle:@"Done" otherButtonTitles: nil] show];
}

#pragma mark - AlertView Delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0 && [[alertView buttonTitleAtIndex:0] isEqualToString:@"Done"]) {
        [self.navigationController popViewControllerAnimated:YES];
    }
    if (buttonIndex == 1 && [[alertView buttonTitleAtIndex:1] isEqualToString:@"OK"]) {
        NSURL*url=[NSURL URLWithString:@"prefs:root=WIFI"];
        [[UIApplication sharedApplication] openURL:url];
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
- (void)registerAPconfigLocalNotification{
    
    UIUserNotificationType types = UIUserNotificationTypeAlert | UIUserNotificationTypeSound;
    UIUserNotificationSettings *connectToNodeSettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
    
    [[UIApplication sharedApplication] registerUserNotificationSettings:connectToNodeSettings];
    
}


#pragma mark -  TextFielDelegate methods
// when user tap Enter or Return
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    UITextField *passwordTextField = [_userInputDialog.textFields objectAtIndex:0];
    UITextField *nameTextField = [_userInputDialog.textFields objectAtIndex:1];
    if (passwordTextField.text.length == 0 || nameTextField.text.length == 0) {
        return NO;
    }
    [self.userInputDialog dismissViewControllerAnimated:YES completion:nil];
    [self startConfiguration];
    return YES;
}
- (void)textFieldDidChange {
    UITextField *passwordTextField = [_userInputDialog.textFields objectAtIndex:0];
    UITextField *nameTextField = [_userInputDialog.textFields objectAtIndex:1];
    if (passwordTextField.text.length == 0 || nameTextField.text.length == 0) {
        [_userInputDialog.actions objectAtIndex:1].enabled = NO;
    } else {
        [_userInputDialog.actions objectAtIndex:1].enabled = YES;
    }
}

#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    id dVC = segue.destinationViewController;
    if ([dVC isKindOfClass:[WiFiListTVC class]]) {
        [(WiFiListTVC *)dVC setPresentingVC:self];
    }
}
@end
